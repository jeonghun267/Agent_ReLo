// A software passkey device for tests: it makes a P-256 key pair and answers the two
// WebAuthn ceremonies the way a phone or laptop would. `patch` bends one answer so a
// test can check that the server refuses it.
import {createHash, generateKeyPairSync, randomBytes, sign} from 'node:crypto';

const sha256 = value => createHash('sha256').update(value).digest();
const b64 = bytes => Buffer.from(bytes).toString('base64url');

// CBOR for what an authenticator sends: integers, byte strings, text, maps.
function head(major, n) {
  if (n < 24) return Buffer.from([(major << 5) | n]);
  if (n < 256) return Buffer.from([(major << 5) | 24, n]);
  const two = Buffer.alloc(3);
  two[0] = (major << 5) | 25;
  two.writeUInt16BE(n, 1);
  return two;
}
export function cbor(value) {
  if (Number.isInteger(value)) return value >= 0 ? head(0, value) : head(1, -1 - value);
  if (Buffer.isBuffer(value)) return Buffer.concat([head(2, value.length), value]);
  if (typeof value === 'string') return Buffer.concat([head(3, Buffer.byteLength(value)), Buffer.from(value)]);
  if (value instanceof Map) return Buffer.concat([head(5, value.size), ...[...value].flatMap(([k, v]) => [cbor(k), cbor(v)])]);
  throw new Error('cbor: unsupported value');
}

export function createAuthenticator({rpId, origin}) {
  const {publicKey, privateKey} = generateKeyPairSync('ec', {namedCurve: 'P-256'});
  const jwk = publicKey.export({format: 'jwk'});
  const credentialId = randomBytes(32);
  const coseKey = new Map([[1, 2], [3, -7], [-1, 1], [-2, Buffer.from(jwk.x, 'base64url')], [-3, Buffer.from(jwk.y, 'base64url')]]);
  let counter = 0;

  function authenticatorData({withKey, userVerified = true, count, forRpId = rpId}) {
    const flags = 0x01 | (userVerified ? 0x04 : 0) | (withKey ? 0x40 : 0);
    const counterBytes = Buffer.alloc(4);
    counterBytes.writeUInt32BE(count);
    const base = Buffer.concat([sha256(forRpId), Buffer.from([flags]), counterBytes]);
    if (!withKey) return base;
    const idLength = Buffer.alloc(2);
    idLength.writeUInt16BE(credentialId.length);
    return Buffer.concat([base, Buffer.alloc(16), idLength, credentialId, cbor(coseKey)]);
  }
  const clientData = (type, challenge, patch) => Buffer.from(JSON.stringify({
    type: patch.type ?? type, challenge: patch.challenge ?? challenge, origin: patch.origin ?? origin, crossOrigin: false,
  }));

  return {
    id: b64(credentialId),

    // navigator.credentials.create()
    create(options, patch = {}) {
      const authData = authenticatorData({withKey: true, userVerified: patch.userVerified, count: 0, forRpId: patch.rpId});
      const attestationObject = cbor(new Map([['fmt', 'none'], ['attStmt', new Map()], ['authData', authData]]));
      return {
        id: b64(credentialId),
        type: 'public-key',
        response: {clientDataJSON: b64(clientData('webauthn.create', options.challenge, patch)), attestationObject: b64(attestationObject)},
      };
    },

    // navigator.credentials.get()
    get(options, patch = {}) {
      counter = patch.counter ?? counter + 1;
      const authData = authenticatorData({withKey: false, userVerified: patch.userVerified, count: counter, forRpId: patch.rpId});
      const clientDataJSON = clientData('webauthn.get', options.challenge, patch);
      const signature = sign('sha256', Buffer.concat([authData, sha256(clientDataJSON)]), privateKey);
      if (patch.tamper) signature[signature.length - 1] ^= 0xff;
      return {
        id: b64(credentialId),
        type: 'public-key',
        response: {clientDataJSON: b64(clientDataJSON), authenticatorData: b64(authData), signature: b64(signature)},
      };
    },
  };
}
