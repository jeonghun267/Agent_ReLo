import {AppError} from '../domain/errors.mjs';

// Holds the one-time values of a sign-in that is on its way to Google and back.
const FLOW_COOKIE = 'relo_google';
const FLOW_PATH = '/api/auth/google';
const FLOW_SECONDS = 10 * 60;

// Only a path inside this site may be the place to land after signing in.
const safeNext = value => (typeof value === 'string' && /^\/(?!\/)[\w\-./?=&%]{0,200}$/.test(value) ? value : '/wizard');
const callbackUrl = ctx => `${ctx.origin}${FLOW_PATH}/callback`;

// Sign in with Google. Both steps are plain page navigations (the browser leaves for
// Google and comes back), so they answer with redirects rather than JSON, and a failure
// goes back to the login screen with a code the screen turns into a sentence.
export function registerGoogleRoutes(router, {services, limits}) {
  router.get(`${FLOW_PATH}/start`, ctx => {
    if (!limits.signIn.hit(ctx.ip)) throw new AppError(429, 'too_many_attempts', '시도가 너무 많아요. 잠시 후 다시 시도하세요.');
    const flow = services.auth.googleStart(callbackUrl(ctx));
    const next = Buffer.from(safeNext(ctx.query.get('next'))).toString('base64url');
    ctx.setFlowCookie(FLOW_COOKIE, [flow.state, flow.nonce, flow.codeVerifier, next].join('.'), {maxAgeSeconds: FLOW_SECONDS, path: FLOW_PATH});
    return {redirect: flow.url};
  }, {auth: false});

  router.get(`${FLOW_PATH}/callback`, async ctx => {
    const [state, nonce, codeVerifier, next] = (ctx.readCookie(FLOW_COOKIE) ?? '').split('.');
    ctx.setFlowCookie(FLOW_COOKIE, '', {maxAgeSeconds: 0, path: FLOW_PATH});
    const backToLogin = code => ({redirect: `/auth?mode=login&error=${encodeURIComponent(code)}`});

    if (!limits.signIn.hit(ctx.ip)) return backToLogin('too_many_attempts');
    // The person pressed "cancel" at Google, or Google reported a problem.
    if (ctx.query.get('error')) return backToLogin('google_cancelled');
    // The state must be the one this browser was sent out with; otherwise the answer
    // belongs to someone else's sign-in (or was forged).
    if (!state || !nonce || !codeVerifier || ctx.query.get('state') !== state) return backToLogin('google_denied');

    try {
      const session = await services.auth.signInWithGoogle({
        code: ctx.query.get('code') ?? '', redirectUri: callbackUrl(ctx), codeVerifier, nonce,
      });
      ctx.setSession(session);
      return {redirect: safeNext(Buffer.from(next ?? '', 'base64url').toString('utf8'))};
    } catch (error) {
      if (error instanceof AppError) return backToLogin(error.code);
      throw error;
    }
  }, {auth: false});
}
