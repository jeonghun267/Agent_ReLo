import test from 'node:test';
import assert from 'node:assert/strict';
import {verifyRegistration, verifyAssertion} from '../../src/server/domain/webauthn.mjs';
import {createAuthenticator} from '../helpers/authenticator.mjs';

const rpId = 'relo.example';
const origin = 'https://relo.example';
const refused = fn => assert.throws(fn, error => error.code === 'passkey_invalid' && error.status === 400);

test('passkey: a new key is accepted and later signs in; the counter must move forward', () => {
  const device = createAuthenticator({rpId, origin});
  const stored = verifyRegistration({response: device.create({challenge: 'c-1'}).response, challenge: 'c-1', origin, rpId});
  assert.equal(stored.credentialId, device.id);
  assert.deepEqual([stored.publicKey.kty, stored.publicKey.crv, stored.publicKey.alg, stored.signCount], ['EC', 'P-256', -7, 0]);

  const check = (answer, challenge, signCount = 0) =>
    verifyAssertion({response: answer.response, challenge, origin, rpId, publicKey: stored.publicKey, signCount});
  assert.equal(check(device.get({challenge: 'c-2'}), 'c-2').signCount, 1);
  assert.equal(check(device.get({challenge: 'c-3'}), 'c-3', 1).signCount, 2);
  // A counter that stays or goes back means the key may have been copied.
  refused(() => check(device.get({challenge: 'c-4'}, {counter: 2}), 'c-4', 2));
});

test('passkey: answers for another challenge, site, origin or ceremony are refused', () => {
  const device = createAuthenticator({rpId, origin});
  const register = (patch, challenge = 'c') => verifyRegistration({response: device.create({challenge: 'c'}, patch).response, challenge, origin, rpId});
  refused(() => register({}, 'other-challenge'));
  refused(() => register({origin: 'https://evil.example'}));
  refused(() => register({rpId: 'evil.example'}));
  refused(() => register({type: 'webauthn.get'}));
  refused(() => register({userVerified: false}));

  const {publicKey} = register({});
  const signIn = (patch, challenge = 'c') => verifyAssertion({response: device.get({challenge: 'c'}, patch).response, challenge, origin, rpId, publicKey, signCount: 0});
  refused(() => signIn({}, 'other-challenge'));
  refused(() => signIn({origin: 'https://evil.example'}));
  refused(() => signIn({rpId: 'evil.example'}));
  refused(() => signIn({type: 'webauthn.create'}));
  refused(() => signIn({userVerified: false}));
  refused(() => signIn({tamper: true}));

  // A key from a different device does not match the stored one.
  const stranger = createAuthenticator({rpId, origin});
  refused(() => verifyAssertion({response: stranger.get({challenge: 'c'}).response, challenge: 'c', origin, rpId, publicKey, signCount: 0}));
});

test('passkey: broken or truncated input is a refusal, not a crash', () => {
  for (const response of [undefined, {}, {clientDataJSON: 'e30', attestationObject: 'oA'}, {clientDataJSON: '!!', attestationObject: '!!'}]) {
    refused(() => verifyRegistration({response, challenge: 'c', origin, rpId}));
    refused(() => verifyAssertion({response, challenge: 'c', origin, rpId, publicKey: {kty: 'EC', crv: 'P-256', x: 'AA', y: 'AA', alg: -7}, signCount: 0}));
  }
  const device = createAuthenticator({rpId, origin});
  const good = device.create({challenge: 'c'}).response;
  refused(() => verifyRegistration({response: {...good, attestationObject: good.attestationObject.slice(0, 40)}, challenge: 'c', origin, rpId}));
});
