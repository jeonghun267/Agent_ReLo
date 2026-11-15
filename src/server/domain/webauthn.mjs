// Checks what a passkey (WebAuthn) device sends back, using only node:crypto.
// Two ceremonies:
//   verifyRegistration: the device made a new key pair for this site; we keep the public key.
//   verifyAssertion:    the device signed our one-time challenge with that key; we check it.
// We ask for no attestation ("none"), so we never judge which make of device it is;
// what matters is that the same key signs in later. Supported keys: ES256 (-7) and RS256 (-257).
import {createHash, createPublicKey, verify as verifySignature} from 'node:crypto';
import {AppError, reject} from './errors.mjs';

export const PASSKEY_ALGORITHMS = Object.freeze([-7, -257]);
const DIGEST = {'-7': 'sha256', '-257': 'sha256'};
const MESSAGE = '패스키를 확인하지 못했어요. 다시 시도해 주세요.';
const fail = () => reject(true, MESSAGE, 'passkey_invalid', 400);

const fromBase64Url = text => Buffer.from(String(text ?? ''), 'base64url');
const toBase64Url = bytes => Buffer.from(bytes).toString('base64url');
const sha256 = bytes => createHash('sha256').update(bytes).digest();

// The small part of CBOR that authenticators use: integers, byte and text strings,
// arrays, maps, and true/false/null. Returns [value, nextOffset].
function decodeCbor(bytes, start = 0) {
  if (start >= bytes.length) fail();
  const head = bytes[start];
  const major = head >> 5;
  const info = head & 31;
  let offset = start + 1;
  let length = info;
  if (info === 24) { length = bytes.readUInt8(offset); offset += 1; }
  else if (info === 25) { length = bytes.readUInt16BE(offset); offset += 2; }
  else if (info === 26) { length = bytes.readUInt32BE(offset); offset += 4; }
  else if (info > 26) fail();

  if (major === 0) return [length, offset];
  if (major === 1) return [-1 - length, offset];
  if (major === 2 || major === 3) {
    if (offset + length > bytes.length) fail();
    const slice = bytes.subarray(offset, offset + length);
    return [major === 2 ? Buffer.from(slice) : slice.toString('utf8'), offset + length];
  }
  if (major === 4) {
    const items = [];
    for (let i = 0; i < length; i += 1) {
      const [item, next] = decodeCbor(bytes, offset);
      items.push(item);
      offset = next;
    }
    return [items, offset];
  }
  if (major === 5) {
    const map = new Map();
    for (let i = 0; i < length; i += 1) {
      const [key, afterKey] = decodeCbor(bytes, offset);
      const [value, afterValue] = decodeCbor(bytes, afterKey);
      map.set(key, value);
      offset = afterValue;
    }
    return [map, offset];
  }
  if (major === 7 && info >= 20 && info <= 22) return [[false, true, null][info - 20], offset];
  return fail();
}

// Authenticator data: 32-byte hash of the site's domain, 1 flag byte, 4-byte counter,
// then (when a key was just made) the credential id and its public key.
function parseAuthenticatorData(data) {
  if (!Buffer.isBuffer(data) || data.length < 37) fail();
  const flags = data[32];
  const parsed = {
    rpIdHash: data.subarray(0, 32),
    userPresent: !!(flags & 0x01),
    userVerified: !!(flags & 0x04),
    hasCredential: !!(flags & 0x40),
    signCount: data.readUInt32BE(33),
  };
  if (!parsed.hasCredential) return parsed;
  if (data.length < 55) fail();
  const idLength = data.readUInt16BE(53);
  if (idLength < 1 || idLength > 1023 || data.length < 55 + idLength) fail();
  parsed.credentialId = toBase64Url(data.subarray(55, 55 + idLength));
  [parsed.coseKey] = decodeCbor(data, 55 + idLength);
  return parsed;
}

// COSE key (the form the device sends) to JWK (the form node:crypto reads and we store).
function coseToJwk(cose) {
  if (!(cose instanceof Map)) fail();
  const algorithm = cose.get(3);
  const bytes = label => {
    const value = cose.get(label);
    if (!Buffer.isBuffer(value) || value.length === 0) fail();
    return toBase64Url(value);
  };
  if (cose.get(1) === 2 && algorithm === -7 && cose.get(-1) === 1) {
    return {kty: 'EC', crv: 'P-256', x: bytes(-2), y: bytes(-3), alg: -7};
  }
  if (cose.get(1) === 3 && algorithm === -257) {
    return {kty: 'RSA', n: bytes(-1), e: bytes(-2), alg: -257};
  }
  return fail();
}

// What the browser says it did: the kind of ceremony, our challenge, and the page's origin.
function checkClientData(clientDataJSON, {type, challenge, origin}) {
  let client = null;
  try { client = JSON.parse(clientDataJSON.toString('utf8')); } catch { fail(); }
  if (client?.type !== type || client.challenge !== challenge || client.origin !== origin || client.crossOrigin === true) fail();
}

function checkAuthenticatorData(parsed, rpId) {
  if (!parsed.rpIdHash.equals(sha256(rpId))) fail();
  // The person was there and proved who they are to the device (fingerprint, face or PIN).
  if (!parsed.userPresent || !parsed.userVerified) fail();
}

// Whatever goes wrong while reading a device's answer (a truncated buffer, a wrong
// type) is the same refusal to the caller, never a 500.
function guarded(check) {
  return input => {
    try {
      return check(input);
    } catch (error) {
      if (error instanceof AppError) throw error;
      return fail();
    }
  };
}

// response: {clientDataJSON, attestationObject} as base64url strings.
// Returns what to store: {credentialId, publicKey (JWK with alg), signCount}.
export const verifyRegistration = guarded(({response, challenge, origin, rpId}) => {
  checkClientData(fromBase64Url(response?.clientDataJSON), {type: 'webauthn.create', challenge, origin});
  const [attestation] = decodeCbor(fromBase64Url(response?.attestationObject));
  if (!(attestation instanceof Map)) fail();
  const parsed = parseAuthenticatorData(attestation.get('authData'));
  checkAuthenticatorData(parsed, rpId);
  if (!parsed.hasCredential) fail();
  const publicKey = coseToJwk(parsed.coseKey);
  const {alg: _alg, ...jwk} = publicKey;
  createPublicKey({key: jwk, format: 'jwk'});
  return {credentialId: parsed.credentialId, publicKey, signCount: parsed.signCount};
});

// response: {clientDataJSON, authenticatorData, signature} as base64url strings.
// Returns the device's new counter. A counter that does not move forward means the
// key may have been copied, so that sign-in is refused.
export const verifyAssertion = guarded(({response, challenge, origin, rpId, publicKey, signCount}) => {
  const clientDataJSON = fromBase64Url(response?.clientDataJSON);
  const authenticatorData = fromBase64Url(response?.authenticatorData);
  checkClientData(clientDataJSON, {type: 'webauthn.get', challenge, origin});
  const parsed = parseAuthenticatorData(authenticatorData);
  checkAuthenticatorData(parsed, rpId);

  const digest = DIGEST[String(publicKey?.alg)];
  if (!digest) fail();
  const {alg: _alg, ...jwk} = publicKey;
  const signed = Buffer.concat([authenticatorData, sha256(clientDataJSON)]);
  const valid = verifySignature(digest, signed, createPublicKey({key: jwk, format: 'jwk'}), fromBase64Url(response?.signature));
  if (!valid) fail();
  if ((parsed.signCount > 0 || signCount > 0) && parsed.signCount <= signCount) fail();
  return {signCount: parsed.signCount};
});
