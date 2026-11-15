import {reject, notFound} from '../domain/errors.mjs';
import {newId, nowIso, randomToken} from '../domain/primitives.mjs';
import {cleanText} from '../domain/validation.mjs';
import {PASSKEY_ALGORITHMS, verifyRegistration, verifyAssertion} from '../domain/webauthn.mjs';

const CHALLENGE_TTL_MS = 5 * 60 * 1000;
const MAX_PER_USER = 10;
const TIMEOUT_MS = 60 * 1000;

// Passkeys: sign in with the device's fingerprint, face or PIN instead of a password.
// Off until PASSKEY_RP_ID (the site's domain) is set. Every ceremony starts with a
// one-time challenge issued here; it is kept in memory, which suits one server process
// (like the rate limiter), and works once, for one purpose, within five minutes.
export function createPasskeyService({repos, config, auth, now = Date.now}) {
  const {enabled, rpId, rpName} = config.passkey;
  const challenges = new Map();

  // A passkey only works on the domain it was made for, so the page must be on it.
  function requireUsable(origin) {
    reject(!enabled, '요청을 찾을 수 없습니다.', 'not_found', 404);
    let host = '';
    try { host = new URL(origin).hostname; } catch { /* reported below */ }
    reject(host !== rpId && !host.endsWith(`.${rpId}`), `패스키는 ${rpId} 주소에서만 쓸 수 있어요.`, 'passkey_origin', 400);
  }

  function issue(purpose, userId = null) {
    const time = now();
    if (challenges.size > 5000) {
      for (const [challenge, entry] of challenges) if (entry.expiresAt <= time) challenges.delete(challenge);
    }
    const challenge = randomToken(32);
    challenges.set(challenge, {purpose, userId, expiresAt: time + CHALLENGE_TTL_MS});
    return challenge;
  }

  // Uses up the challenge the device signed. It must be one we issued for this purpose
  // (and, when registering, for this user), unused and not expired.
  function take(response, purpose, userId = null) {
    let challenge = null;
    try {
      challenge = JSON.parse(Buffer.from(String(response?.clientDataJSON ?? ''), 'base64url').toString('utf8')).challenge;
    } catch { /* reported below */ }
    const entry = typeof challenge === 'string' ? challenges.get(challenge) : null;
    if (entry) challenges.delete(challenge);
    reject(!entry || entry.purpose !== purpose || entry.userId !== userId || entry.expiresAt <= now(),
      '패스키 요청 시간이 지났어요. 다시 시도해 주세요.', 'passkey_expired', 400);
    return challenge;
  }

  const toView = passkey => ({id: passkey.id, name: passkey.name, createdAt: passkey.createdAt, lastUsedAt: passkey.lastUsedAt});

  function list(userId) {
    return repos.passkeys.listForUser(userId).map(toView);
  }

  // What the browser needs to make a new passkey for the signed-in user.
  function registrationOptions(user, origin) {
    requireUsable(origin);
    const existing = repos.passkeys.listForUser(user.id);
    reject(existing.length >= MAX_PER_USER, `패스키는 ${MAX_PER_USER}개까지 등록할 수 있어요.`, 'passkey_limit', 409);
    return {
      challenge: issue('register', user.id),
      rp: {id: rpId, name: rpName},
      user: {id: Buffer.from(user.id).toString('base64url'), name: user.email, displayName: user.name},
      pubKeyCredParams: PASSKEY_ALGORITHMS.map(alg => ({type: 'public-key', alg})),
      timeout: TIMEOUT_MS,
      attestation: 'none',
      authenticatorSelection: {residentKey: 'required', userVerification: 'required'},
      excludeCredentials: existing.map(passkey => ({type: 'public-key', id: passkey.credentialId})),
    };
  }

  // input: {name?, response: {clientDataJSON, attestationObject}}
  function register(user, origin, input) {
    requireUsable(origin);
    const challenge = take(input?.response, 'register', user.id);
    const verified = verifyRegistration({response: input.response, challenge, origin, rpId});
    reject(!!repos.passkeys.findByCredentialId(verified.credentialId), '이미 등록한 패스키예요.', 'passkey_exists', 409);
    reject(repos.passkeys.countForUser(user.id) >= MAX_PER_USER, `패스키는 ${MAX_PER_USER}개까지 등록할 수 있어요.`, 'passkey_limit', 409);
    repos.passkeys.insert({
      id: newId(), userId: user.id, credentialId: verified.credentialId, publicKey: verified.publicKey,
      signCount: verified.signCount, name: cleanText(input.name, 40) || 'Passkey', createdAt: nowIso(),
    });
    return list(user.id);
  }

  function remove(userId, id) {
    if (!repos.passkeys.delete(userId, id)) throw notFound();
    return list(userId);
  }

  // What the browser needs to ask the device for a passkey of this site. No account is
  // named: the device offers the passkeys it holds, so nothing is revealed about who has one.
  function loginOptions(origin) {
    requireUsable(origin);
    return {challenge: issue('login'), rpId, timeout: TIMEOUT_MS, userVerification: 'required'};
  }

  // input: {id, response: {clientDataJSON, authenticatorData, signature}}. Returns a session.
  function login(origin, input) {
    requireUsable(origin);
    const challenge = take(input?.response, 'login');
    const passkey = repos.passkeys.findByCredentialId(String(input?.id ?? ''));
    reject(!passkey, '이 패스키로 등록된 계정을 찾지 못했어요.', 'passkey_unknown', 401);
    const {signCount} = verifyAssertion({
      response: input.response, challenge, origin, rpId, publicKey: passkey.publicKey, signCount: passkey.signCount,
    });
    repos.passkeys.markUsed(passkey.id, signCount, nowIso());
    return auth.startSession(passkey.userId);
  }

  return {list, registrationOptions, register, remove, loginOptions, login};
}
