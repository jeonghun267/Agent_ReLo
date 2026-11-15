// Sign in with Google and passkeys. Both are off until the operator sets their values.
import test from 'node:test';
import assert from 'node:assert/strict';
import {startApp} from '../helpers/app.mjs';
import {createAuthenticator} from '../helpers/authenticator.mjs';
import {AppError} from '../../src/server/domain/errors.mjs';
import {transaction} from '../../src/server/repositories/db.mjs';

// Stands in for Google: `people` maps the code Google would send back to the person it names.
function fakeGoogle(people) {
  return {
    name: 'fake-google',
    enabled: true,
    exchanges: [],
    authorizationUrl: ({redirectUri, state}) => `https://accounts.example.test/auth?state=${state}&redirect_uri=${encodeURIComponent(redirectUri)}`,
    async exchange(input) {
      this.exchanges.push(input);
      const person = people[input.code];
      if (!person) throw new AppError(400, 'google_denied', 'denied');
      return person;
    },
  };
}

// One page navigation, without following the redirect, keeping this browser's cookies.
function browser(base) {
  const jar = new Map();
  return {
    jar,
    async go(path) {
      const response = await fetch(base + path, {redirect: 'manual', headers: {Cookie: [...jar].map(([k, v]) => `${k}=${v}`).join('; ')}});
      for (const line of response.headers.getSetCookie()) {
        const [pair] = line.split(';');
        const [name, value] = [pair.slice(0, pair.indexOf('=')), pair.slice(pair.indexOf('=') + 1)];
        if (value === '') jar.delete(name); else jar.set(name, value);
      }
      return {status: response.status, location: response.headers.get('location')};
    },
    async me() {
      const response = await fetch(base + '/api/me', {headers: {Cookie: [...jar].map(([k, v]) => `${k}=${v}`).join('; ')}});
      return {status: response.status, data: await response.json()};
    },
    // Leaves for Google and comes back with `code`, as the real redirect would.
    async signIn(code, {next = '', state} = {}) {
      const out = await this.go(`/api/auth/google/start${next ? `?next=${encodeURIComponent(next)}` : ''}`);
      const sent = new URL(out.location).searchParams.get('state');
      return {out, back: await this.go(`/api/auth/google/callback?code=${code}&state=${state ?? sent}`)};
    },
  };
}

test('sign-in methods are off by default', async t => {
  const {client, base} = await startApp(t);
  assert.deepEqual((await client().call('/api/config')).data.signIn, {google: false, passkey: false});
  assert.equal((await browser(base).go('/api/auth/google/start')).status, 404);
  assert.equal((await client().call('/api/auth/passkey/options', {method: 'POST', data: {}})).status, 404);
  const user = await client().signup();
  assert.equal((await user.call('/api/account/passkeys/options', {method: 'POST', data: {}})).status, 404);
  assert.deepEqual((await user.call('/api/account/passkeys')).data.passkeys, []);
});

test('google: a first sign-in creates a verified account; the same Google account returns to it', async t => {
  const google = fakeGoogle({
    alice: {subject: 'g-alice', email: 'Alice@Example.test', name: 'Alice'},
    moved: {subject: 'g-alice', email: 'alice-new@example.test', name: 'Alice'},
  });
  const {client, base} = await startApp(t, {googleProvider: google});
  assert.equal((await client().call('/api/config')).data.signIn.google, true);

  const first = browser(base);
  const {out, back} = await first.signIn('alice');
  assert.equal(out.status, 302);
  assert.equal(new URL(out.location).searchParams.get('redirect_uri'), `${base}/api/auth/google/callback`);
  assert.deepEqual([back.status, back.location], [302, '/wizard']);
  assert.equal(first.jar.has('relo_google'), false, 'the flow cookie is used up');
  const me = await first.me();
  assert.equal(me.status, 200);
  assert.deepEqual([me.data.user.email, me.data.user.name, !!me.data.user.emailVerifiedAt], ['alice@example.test', 'Alice', true]);
  // The code verifier and nonce that went out are the ones handed to the exchange.
  assert.ok(google.exchanges[0].codeVerifier.length >= 43 && google.exchanges[0].nonce.length >= 16);

  // Same Google account later, even after its address changed: the same ReLo account.
  const second = browser(base);
  assert.equal((await second.signIn('moved', {next: '/claims'})).back.location, '/claims');
  assert.equal((await second.me()).data.user.id, me.data.user.id);
});

test('google: a forged or cancelled return, and an unknown code, go back to the login screen', async t => {
  const {base} = await startApp(t, {googleProvider: fakeGoogle({alice: {subject: 'g-alice', email: 'alice@example.test', name: ''}})});
  const loginError = code => `/auth?mode=login&error=${code}`;

  const forged = browser(base);
  assert.equal((await forged.signIn('alice', {state: 'not-the-state-we-sent'})).back.location, loginError('google_denied'));
  assert.equal((await forged.me()).status, 401);

  // A return without the cookie of the browser that started the sign-in.
  assert.equal((await browser(base).go('/api/auth/google/callback?code=alice&state=x')).location, loginError('google_denied'));

  const cancelled = browser(base);
  await cancelled.go('/api/auth/google/start');
  assert.equal((await cancelled.go('/api/auth/google/callback?error=access_denied')).location, loginError('google_cancelled'));

  assert.equal((await browser(base).signIn('nobody')).back.location, loginError('google_denied'));
  // Only a path on this site can be the landing place.
  assert.equal((await browser(base).signIn('alice', {next: '//evil.example/x'})).back.location, '/wizard');
});

test('google: links to an account with the same verified email, not to an unverified one', async t => {
  const google = fakeGoogle({
    bob: {subject: 'g-bob', email: 'bob@example.test', name: 'Bob'},
    eve: {subject: 'g-eve', email: 'eve@example.test', name: 'Eve'},
  });
  const {app, client, base, mail} = await startApp(t, {googleProvider: google});

  const bob = await client().signup('bob@example.test');
  const bobId = (await bob.call('/api/me')).data.user.id;
  assert.equal((await client().call('/api/auth/verify', {method: 'POST', data: {token: mail.token('bob@example.test', 'verify')}})).status, 200);
  const viaGoogle = browser(base);
  assert.equal((await viaGoogle.signIn('bob')).back.location, '/wizard');
  assert.equal((await viaGoogle.me()).data.user.id, bobId, 'same account as the password one');
  assert.equal((await client().login('bob@example.test')).email, undefined, 'the password still works');

  // Someone made an account with Eve's address but never proved they own it.
  await client().signup('eve@example.test');
  const eve = browser(base);
  assert.equal((await eve.signIn('eve')).back.location, '/auth?mode=login&error=google_unverified_account');
  assert.equal((await eve.me()).status, 401);

  // Deleting the account removes the link too; the next sign-in starts a new account.
  transaction(app.db, () => app.repos.account.purgeOwner(bobId));
  assert.equal(app.db.prepare('SELECT COUNT(*) AS n FROM identities').get().n, 0);
  const again = browser(base);
  await again.signIn('bob');
  assert.notEqual((await again.me()).data.user.id, bobId);
});

test('passkey: register, sign in without a password, and remove', async t => {
  const {client, base} = await startApp(t, {env: {PASSKEY_RP_ID: '127.0.0.1'}});
  assert.equal((await client().call('/api/config')).data.signIn.passkey, true);
  const device = createAuthenticator({rpId: '127.0.0.1', origin: base});
  const user = await client().signup('carol@example.test');

  const options = (await user.call('/api/account/passkeys/options', {method: 'POST', data: {}})).data;
  assert.deepEqual([options.rp.id, options.user.name, options.attestation, options.authenticatorSelection.userVerification],
    ['127.0.0.1', 'carol@example.test', 'none', 'required']);
  const answer = device.create(options);
  const added = await user.call('/api/account/passkeys', {method: 'POST', data: {name: '  내 노트북  ', response: answer.response}});
  assert.equal(added.status, 201, JSON.stringify(added.data));
  assert.deepEqual(added.data.passkeys.map(p => [p.name, p.lastUsedAt]), [['내 노트북', null]]);
  const passkeyId = added.data.passkeys[0].id;
  // The same answer cannot be sent twice: its challenge is used up.
  assert.equal((await user.call('/api/account/passkeys', {method: 'POST', data: {response: answer.response}})).data.error, 'passkey_expired');

  const anon = client();
  const ask = async () => (await anon.call('/api/auth/passkey/options', {method: 'POST', data: {}})).data;
  const send = (answerToSend, id = answerToSend.id) => anon.call('/api/auth/passkey/login', {method: 'POST', data: {id, response: answerToSend.response}});

  assert.equal((await send(device.get(await ask(), {origin: 'http://evil.example'}))).data.error, 'passkey_invalid');
  assert.equal((await send(device.get(await ask(), {tamper: true}))).data.error, 'passkey_invalid');
  assert.equal((await send(device.get(await ask()), 'unknown-credential')).status, 401);
  assert.equal((await anon.call('/api/me')).status, 401);

  const good = device.get(await ask());
  const signedIn = await send(good);
  assert.equal(signedIn.status, 200, JSON.stringify(signedIn.data));
  assert.equal(signedIn.data.user.email, 'carol@example.test');
  assert.equal((await anon.call('/api/me')).status, 200);
  assert.equal((await send(good)).data.error, 'passkey_expired', 'a used answer does not sign in again');
  assert.ok((await user.call('/api/account/passkeys')).data.passkeys[0].lastUsedAt);

  // Another user cannot remove it; the owner can, and then it no longer signs in.
  const other = await client().signup();
  assert.equal((await other.call(`/api/account/passkeys/${passkeyId}`, {method: 'DELETE'})).status, 404);
  assert.deepEqual((await user.call(`/api/account/passkeys/${passkeyId}`, {method: 'DELETE'})).data.passkeys, []);
  assert.equal((await client().call('/api/auth/passkey/login', {method: 'POST', data: {id: device.id, response: device.get(await ask()).response}})).status, 401);
});

test('passkey: only on the site address it belongs to, and only with the device check', async t => {
  const {client, base} = await startApp(t, {env: {PASSKEY_RP_ID: 'relo.example'}});
  // This test server answers on 127.0.0.1, which is not relo.example.
  assert.equal((await client().call('/api/auth/passkey/options', {method: 'POST', data: {}})).data.error, 'passkey_origin');

  const {client: local, base: localBase} = await startApp(t, {env: {PASSKEY_RP_ID: '127.0.0.1'}});
  const user = await local().signup();
  const device = createAuthenticator({rpId: '127.0.0.1', origin: localBase});
  const options = (await user.call('/api/account/passkeys/options', {method: 'POST', data: {}})).data;
  // The device did not check the person (no fingerprint, face or PIN).
  const unchecked = await user.call('/api/account/passkeys', {method: 'POST', data: {response: device.create(options, {userVerified: false}).response}});
  assert.equal(unchecked.data.error, 'passkey_invalid');
  assert.deepEqual((await user.call('/api/account/passkeys')).data.passkeys, []);
  assert.ok(base);
});
