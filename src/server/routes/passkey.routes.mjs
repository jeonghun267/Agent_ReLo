import {AppError} from '../domain/errors.mjs';

function tooMany() {
  return new AppError(429, 'too_many_attempts', '시도가 너무 많아요. 잠시 후 다시 시도하세요.');
}

// Passkeys. Signing in is public (two steps: get a challenge, send the device's answer);
// registering, listing and removing belong to the signed-in user.
export function registerPasskeyRoutes(router, {services, limits}) {
  router.post('/api/auth/passkey/options', ctx => {
    if (!limits.signIn.hit(ctx.ip)) throw tooMany();
    return {body: services.passkeys.loginOptions(ctx.origin)};
  }, {auth: false});

  router.post('/api/auth/passkey/login', async ctx => {
    if (!limits.signIn.hit(ctx.ip)) throw tooMany();
    const session = services.passkeys.login(ctx.origin, await ctx.json());
    ctx.setSession(session);
    return {body: {user: session.user, csrf: session.csrf}};
  }, {auth: false});

  router.get('/api/account/passkeys', ctx => ({body: {passkeys: services.passkeys.list(ctx.user.id)}}));

  router.post('/api/account/passkeys/options', ctx => ({body: services.passkeys.registrationOptions(ctx.user, ctx.origin)}));

  router.post('/api/account/passkeys', async ctx => ({
    status: 201,
    body: {passkeys: services.passkeys.register(ctx.user, ctx.origin, await ctx.json())},
  }));

  router.delete('/api/account/passkeys/:id', ctx => ({body: {passkeys: services.passkeys.remove(ctx.user.id, ctx.params.id)}}));
}
