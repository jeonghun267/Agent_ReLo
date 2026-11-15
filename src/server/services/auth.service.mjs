import {scrypt, randomBytes, timingSafeEqual, createHash} from 'node:crypto';
import {promisify} from 'node:util';
import {transaction} from '../repositories/db.mjs';
import {reject, AppError, forField} from '../domain/errors.mjs';
import {newId, nowIso, randomToken, sha256} from '../domain/primitives.mjs';
import {cleanText, parseEmail, parsePassword} from '../domain/validation.mjs';
import {verifyEmailMessage, resetPasswordMessage} from '../mail/messages.mjs';

const derive = promisify(scrypt);
const DUMMY_SALT = '0'.repeat(32);
const hashPassword = async (password, salt) => (await derive(password, salt, 64)).toString('hex');

async function newCredentials(password) {
  const salt = randomBytes(16).toString('hex');
  return {salt, passwordHash: await hashPassword(password, salt)};
}

// Unknown, expired, used and wrong-purpose links all get the same answer.
const INVALID_LINK = {
  verify: '인증 링크가 만료됐거나 이미 사용됐어요. 로그인한 뒤 인증 메일을 다시 받으세요.',
  reset: '재설정 링크가 만료됐거나 이미 사용됐어요. 비밀번호 재설정을 다시 요청하세요.',
};

export function createAuthService({db, repos, config, mail, google, logger}) {
  const ttlMs = config.sessionTtlSeconds * 1000;
  const linkTtlSeconds = {verify: config.verifyTokenTtlSeconds, reset: config.resetTokenTtlSeconds};
  const verifyLinkHours = Math.max(1, Math.round(linkTtlSeconds.verify / 3600));
  const resetLinkMinutes = Math.max(1, Math.round(linkTtlSeconds.reset / 60));

  function createSession(userId) {
    const token = randomToken(32);
    const csrf = randomToken(24);
    repos.sessions.insert({tokenHash: sha256(token), userId, csrf, expiresAt: Date.now() + ttlMs, createdAt: nowIso()});
    return {token, csrf, user: repos.users.findById(userId), maxAgeSeconds: config.sessionTtlSeconds};
  }

  // Creates the account only. signup() also signs the new user in.
  // Signing in right away means an existing email has to be answered with 409,
  // so sign-up does reveal registered addresses; the per-IP sign-up limit slows
  // bulk probing. Hiding it would need "confirm by email before the account
  // exists" (docs/ARCHITECTURE.md, 계정과 메일).
  async function register(input) {
    const email = forField('email', () => parseEmail(input.email));
    const password = forField('password', () => parsePassword(input.password));
    const name = cleanText(input.name, 50) || email.split('@')[0];
    forField('email', () => reject(repos.users.existsByEmail(email), '이미 가입한 이메일입니다. 로그인해 주세요.', 'email_taken', 409));
    const {salt, passwordHash} = await newCredentials(password);
    const id = newId();
    try {
      repos.users.insert({id, email, name, salt, passwordHash, createdAt: nowIso()});
    } catch (error) {
      if (String(error.message).includes('UNIQUE')) throw new AppError(409, 'email_taken', '이미 가입한 이메일입니다. 로그인해 주세요.', 'email');
      throw error;
    }
    return repos.users.findById(id);
  }

  async function signup(input) {
    const user = await register(input);
    sendVerification(user);
    return createSession(user.id);
  }

  // Always runs scrypt, even for unknown emails, so timing does not reveal accounts.
  async function login(input) {
    const email = cleanText(input.email, 200).toLowerCase();
    const credentials = repos.users.findCredentialsByEmail(email);
    const derived = await derive(String(input.password ?? '').slice(0, 200), credentials?.salt ?? DUMMY_SALT, 64);
    const valid = !!credentials && timingSafeEqual(derived, Buffer.from(credentials.passwordHash, 'hex'));
    reject(!valid, '이메일 또는 비밀번호를 확인하세요.', 'unauthorized', 401);
    return createSession(credentials.id);
  }

  // Returns the signed-in user for a cookie token, extending the session once
  // half of its lifetime has passed (renewed: true tells the route to reissue the cookie).
  function resolveSession(token) {
    if (!token) return null;
    const session = repos.sessions.find(sha256(token));
    if (!session) return null;
    const now = Date.now();
    const user = session.expiresAt > now ? repos.users.findById(session.userId) : null;
    if (!user) {
      repos.sessions.delete(session.tokenHash);
      return null;
    }
    const renewed = session.expiresAt - now < ttlMs / 2;
    if (renewed) repos.sessions.extend(session.tokenHash, now + ttlMs);
    return {user, csrf: session.csrf, renewed, maxAgeSeconds: config.sessionTtlSeconds};
  }

  function logout(token) {
    if (token) repos.sessions.delete(sha256(token));
  }

  async function verifyPassword(userId, password) {
    const credentials = repos.users.findCredentialsById(userId);
    if (!credentials) return false;
    const derived = await derive(String(password ?? '').slice(0, 200), credentials.salt, 64);
    return timingSafeEqual(derived, Buffer.from(credentials.passwordHash, 'hex'));
  }

  // One-time email links. Only the newest link of each purpose works.
  function issueLink(user, purpose) {
    const token = randomToken(32);
    transaction(db, () => {
      repos.emailTokens.deleteForUser(user.id, purpose);
      repos.emailTokens.insert({
        tokenHash: sha256(token), userId: user.id, purpose, email: user.email,
        expiresAt: Date.now() + linkTtlSeconds[purpose] * 1000, createdAt: nowIso(),
      });
    });
    return `${config.appOrigin}/#/${purpose}/${token}`;
  }

  // Uses the link up. Call inside a transaction: if a later step fails, the link stays valid.
  function takeLink(token, purpose) {
    const text = typeof token === 'string' && token.length <= 100 ? token : '';
    const found = text ? repos.emailTokens.take(sha256(text), purpose) : null;
    const user = found && found.expiresAt > Date.now() ? repos.users.findById(found.userId) : null;
    reject(!user || user.email !== found.email, INVALID_LINK[purpose], 'invalid_link', 400);
    return user;
  }

  // Delivery is never awaited, so a slow or failing provider changes neither the
  // answer nor its timing. The log names the failure, not the address.
  function deliver(message) {
    (async () => mail.send(message))().catch(error => logger.error(`[mail] delivery failed: ${error.code ?? error.name}${error.detail ? ` (${error.detail})` : ''}`));
  }

  // Runs once the response has been sent, so doing the work for a real account
  // (a committed write) does not make its answer measurably slower.
  function afterResponse(task) {
    setImmediate(() => {
      try { task(); } catch (error) { logger.error('[mail]', error); }
    });
  }

  function requireMail() {
    reject(!mail.enabled, '메일 발송이 아직 설정되지 않았어요. 운영자에게 문의하세요.', 'mail_disabled', 503);
  }

  function sendVerification(user) {
    if (!mail.enabled) return;
    const link = issueLink(user, 'verify');
    deliver(verifyEmailMessage({to: user.email, name: user.name, link, hours: verifyLinkHours}));
  }

  function resendVerification(userId) {
    requireMail();
    const user = repos.users.findById(userId);
    if (user.emailVerifiedAt) return {sent: false};
    sendVerification(user);
    return {sent: true};
  }

  function verifyEmail(token) {
    transaction(db, () => {
      const user = takeLink(token, 'verify');
      repos.users.markEmailVerified(user.id, nowIso());
      repos.emailTokens.deleteForUser(user.id, 'verify');
    });
  }

  // The same answer whether or not the address has an account.
  function requestPasswordReset(email) {
    requireMail();
    const address = forField('email', () => parseEmail(email));
    const user = repos.users.findByEmail(address);
    if (!user) return;
    afterResponse(() => {
      const link = issueLink(user, 'reset');
      deliver(resetPasswordMessage({to: user.email, name: user.name, link, minutes: resetLinkMinutes}));
    });
  }

  // Sets a new password from an emailed link and ends every session of that
  // user. Opening the link proves the mailbox, so the address counts as verified.
  async function resetPassword(token, password) {
    const {salt, passwordHash} = await newCredentials(forField('password', () => parsePassword(password)));
    transaction(db, () => {
      const user = takeLink(token, 'reset');
      const at = nowIso();
      repos.users.setPassword(user.id, salt, passwordHash, at);
      repos.users.markEmailVerified(user.id, at);
      repos.sessions.deleteForUser(user.id);
      repos.emailTokens.deleteForUser(user.id, 'reset');
    });
  }

  // Sign in with Google, step 1: where to send the browser, plus the one-time values
  // the callback must get back (the route keeps them in a short-lived cookie).
  function googleStart(redirectUri) {
    const state = randomToken(24);
    const nonce = randomToken(24);
    const codeVerifier = randomToken(48);
    const codeChallenge = createHash('sha256').update(codeVerifier).digest('base64url');
    return {state, nonce, codeVerifier, url: google.authorizationUrl({redirectUri, state, nonce, codeChallenge})};
  }

  // Step 2: Google sent the browser back with a code. Returns a session for
  //   - the user this Google account is already linked to, or
  //   - the user with the same email, if that email is verified (linked from now on), or
  //   - a new account (its email counts as verified: Google confirmed it).
  // An account whose email was never verified is not handed over: someone else could
  // have made it with this address, and would still know its password.
  async function signInWithGoogle({code, redirectUri, codeVerifier, nonce}) {
    const profile = await google.exchange({code, redirectUri, codeVerifier, nonce});
    const email = parseEmail(profile.email);
    const linkedId = repos.identities.findUserId('google', profile.subject);
    if (linkedId && repos.users.findById(linkedId)) return createSession(linkedId);

    const existing = repos.users.findByEmail(email);
    reject(existing && !existing.emailVerifiedAt,
      '이 이메일로 만든 계정이 있어요. 비밀번호로 로그인해 이메일 인증을 마치면 Google로도 들어올 수 있어요.', 'google_unverified_account', 409);
    const at = nowIso();
    if (existing) {
      repos.identities.insert({provider: 'google', subject: profile.subject, userId: existing.id, email, createdAt: at});
      return createSession(existing.id);
    }
    // No password was chosen, so the stored one is random: the person signs in with
    // Google, or sets a password later through the reset link.
    const {salt, passwordHash} = await newCredentials(randomToken(32));
    const id = newId();
    transaction(db, () => {
      repos.users.insert({id, email, name: cleanText(profile.name, 50) || email.split('@')[0], salt, passwordHash, createdAt: at});
      repos.users.markEmailVerified(id, at);
      repos.identities.insert({provider: 'google', subject: profile.subject, userId: id, email, createdAt: at});
    });
    return createSession(id);
  }

  // Which extra ways to sign in the operator has switched on.
  function signInMethods() {
    return {google: google.enabled, passkey: config.passkey.enabled};
  }

  function mailStatus() {
    return {enabled: mail.enabled, verifyLinkHours, resetLinkMinutes};
  }

  function cleanupExpired() {
    const now = Date.now();
    repos.sessions.deleteExpired(now);
    repos.emailTokens.deleteExpired(now);
  }

  return {
    register, signup, login, resolveSession, logout, verifyPassword, startSession: createSession,
    googleStart, signInWithGoogle, signInMethods,
    resendVerification, verifyEmail, requestPasswordReset, resetPassword, mailStatus, cleanupExpired,
  };
}
