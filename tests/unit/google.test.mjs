import test from 'node:test';
import assert from 'node:assert/strict';
import {createGoogleProvider} from '../../src/server/auth/google.provider.mjs';
import {loadConfig} from '../../src/server/config.mjs';

const settings = {enabled: true, clientId: 'client-1', clientSecret: 'secret-1', timeoutMs: 1000};
const NOW = Date.parse('2026-11-15T00:00:00Z');
const claimsOf = patch => ({
  iss: 'https://accounts.google.com', aud: 'client-1', exp: NOW / 1000 + 600, nonce: 'n-1',
  sub: '1234567890', email: 'Person@Example.test', email_verified: true, name: 'Person', ...patch,
});
// An ID token as Google's token endpoint returns it (the signature part is not read).
const idToken = claims => ['e30', Buffer.from(JSON.stringify(claims)).toString('base64url'), 'sig'].join('.');
const answer = (claims, status = 200) => async () => ({ok: status < 400, status, json: async () => ({id_token: idToken(claims)})});
const exchange = (fetchImpl, nonce = 'n-1') =>
  createGoogleProvider(settings, {fetchImpl, now: () => NOW}).exchange({code: 'code-1', redirectUri: 'https://relo.example/api/auth/google/callback', codeVerifier: 'v'.repeat(43), nonce});

test('google: sends the browser out with PKCE, state and nonce, and never the secret', () => {
  const url = new URL(createGoogleProvider(settings).authorizationUrl({
    redirectUri: 'https://relo.example/api/auth/google/callback', state: 's-1', nonce: 'n-1', codeChallenge: 'challenge-1',
  }));
  assert.equal(url.origin + url.pathname, 'https://accounts.google.com/o/oauth2/v2/auth');
  const sent = Object.fromEntries(url.searchParams);
  assert.deepEqual([sent.client_id, sent.response_type, sent.scope, sent.state, sent.nonce, sent.code_challenge, sent.code_challenge_method],
    ['client-1', 'code', 'openid email profile', 's-1', 'n-1', 'challenge-1', 'S256']);
  assert.equal(url.href.includes('secret-1'), false);
});

test('google: exchanges the code and returns who signed in', async () => {
  const calls = [];
  const person = await exchange(async (url, options) => { calls.push({url, options}); return answer(claimsOf({}))(); });
  assert.deepEqual(person, {subject: '1234567890', email: 'person@example.test', name: 'Person'});
  assert.equal(calls[0].url, 'https://oauth2.googleapis.com/token');
  const body = Object.fromEntries(new URLSearchParams(calls[0].options.body));
  assert.deepEqual([body.code, body.client_id, body.client_secret, body.grant_type, body.code_verifier.length],
    ['code-1', 'client-1', 'secret-1', 'authorization_code', 43]);
});

test('google: refuses a token for another app, an old one, a wrong nonce or an unverified email', async () => {
  const code = promise => promise.then(() => 'accepted', error => error.code);
  assert.equal(await code(exchange(answer(claimsOf({aud: 'another-app'})))), 'google_denied');
  assert.equal(await code(exchange(answer(claimsOf({iss: 'https://evil.example'})))), 'google_denied');
  assert.equal(await code(exchange(answer(claimsOf({exp: NOW / 1000 - 1})))), 'google_denied');
  assert.equal(await code(exchange(answer(claimsOf({})), 'another-nonce')), 'google_denied');
  assert.equal(await code(exchange(answer(claimsOf({sub: ''})))), 'google_denied');
  assert.equal(await code(exchange(answer(claimsOf({email_verified: false})))), 'google_email_unverified');
  assert.equal(await code(exchange(answer(claimsOf({}), 400))), 'google_denied');
  assert.equal(await code(exchange(answer(claimsOf({}), 503))), 'google_unreachable');
  assert.equal(await code(exchange(async () => { throw new Error('network down'); })), 'google_unreachable');
  assert.equal(await code(exchange(async () => ({ok: true, status: 200, json: async () => ({id_token: 'not-a-token'})}))), 'google_denied');
});

test('settings: both Google values or neither; the passkey domain must fit the site', () => {
  const base = {APP_ENV: 'test', DATA_DIR: 'x'};
  assert.deepEqual([loadConfig(base).google.enabled, loadConfig(base).passkey.enabled], [false, false]);
  assert.equal(loadConfig({...base, GOOGLE_CLIENT_ID: 'id', GOOGLE_CLIENT_SECRET: 'secret'}).google.enabled, true);
  assert.throws(() => loadConfig({...base, GOOGLE_CLIENT_ID: 'id'}), /GOOGLE_CLIENT_SECRET/);
  assert.throws(() => loadConfig({...base, GOOGLE_CLIENT_SECRET: 'secret'}), /GOOGLE_CLIENT_ID/);

  const production = {APP_ENV: 'production', DATA_DIR: 'x', APP_ORIGIN: 'https://app.relo.example'};
  assert.equal(loadConfig({...production, PASSKEY_RP_ID: 'Relo.Example'}).passkey.rpId, 'relo.example');
  assert.equal(loadConfig({...production, PASSKEY_RP_ID: 'app.relo.example'}).passkey.enabled, true);
  assert.throws(() => loadConfig({...production, PASSKEY_RP_ID: 'other.example'}), /PASSKEY_RP_ID/);
});
