import {AppError} from '../domain/errors.mjs';

const AUTH_URL = 'https://accounts.google.com/o/oauth2/v2/auth';
const TOKEN_URL = 'https://oauth2.googleapis.com/token';
const ISSUERS = ['https://accounts.google.com', 'accounts.google.com'];

const ERRORS = {
  unreachable: () => new AppError(502, 'google_unreachable', 'Google에 연결하지 못했어요. 잠시 후 다시 시도하세요.'),
  denied: () => new AppError(400, 'google_denied', 'Google 로그인을 확인하지 못했어요. 다시 시도해 주세요.'),
  unverified: () => new AppError(400, 'google_email_unverified', 'Google에서 인증된 이메일이 있어야 해요.'),
};

// Provider contract:
//   name: string, enabled: boolean
//   authorizationUrl({redirectUri, state, nonce, codeChallenge}) -> string (where to send the browser)
//   exchange({code, redirectUri, codeVerifier, nonce}) -> Promise<{subject, email, name}>
// "Sign in with Google" by the OAuth 2.0 authorization-code flow with PKCE, calling
// Google's REST endpoints directly (no SDK, nothing loaded into the page).
// The ID token comes straight from Google's token endpoint over TLS, so its claims
// are checked (issuer, audience, expiry, nonce, verified email) without fetching
// Google's signing keys. The client secret is never logged or returned.
export function createGoogleProvider({enabled, clientId, clientSecret, timeoutMs}, {fetchImpl = fetch, now = Date.now} = {}) {
  if (!enabled) {
    return {
      name: 'disabled',
      enabled: false,
      authorizationUrl() { throw new AppError(404, 'not_found', '요청을 찾을 수 없습니다.'); },
      async exchange() { throw new AppError(404, 'not_found', '요청을 찾을 수 없습니다.'); },
    };
  }

  return {
    name: 'google',
    enabled: true,

    authorizationUrl({redirectUri, state, nonce, codeChallenge}) {
      const url = new URL(AUTH_URL);
      url.search = new URLSearchParams({
        client_id: clientId,
        redirect_uri: redirectUri,
        response_type: 'code',
        scope: 'openid email profile',
        state,
        nonce,
        code_challenge: codeChallenge,
        code_challenge_method: 'S256',
        prompt: 'select_account',
      }).toString();
      return url.href;
    },

    async exchange({code, redirectUri, codeVerifier, nonce}) {
      let response;
      try {
        response = await fetchImpl(TOKEN_URL, {
          method: 'POST',
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: new URLSearchParams({
            code, client_id: clientId, client_secret: clientSecret, redirect_uri: redirectUri,
            grant_type: 'authorization_code', code_verifier: codeVerifier,
          }).toString(),
          signal: AbortSignal.timeout(timeoutMs),
        });
      } catch {
        throw ERRORS.unreachable();
      }
      if (response.status >= 500) throw ERRORS.unreachable();
      if (!response.ok) throw ERRORS.denied();

      let claims;
      try {
        const {id_token: idToken} = await response.json();
        claims = JSON.parse(Buffer.from(String(idToken).split('.')[1], 'base64url').toString('utf8'));
      } catch {
        throw ERRORS.denied();
      }
      const valid = ISSUERS.includes(claims.iss)
        && claims.aud === clientId
        && Number(claims.exp) * 1000 > now()
        && claims.nonce === nonce
        && typeof claims.sub === 'string' && claims.sub.length > 0 && claims.sub.length <= 255
        && typeof claims.email === 'string';
      if (!valid) throw ERRORS.denied();
      if (claims.email_verified !== true && claims.email_verified !== 'true') throw ERRORS.unverified();
      return {subject: claims.sub, email: claims.email.trim().toLowerCase(), name: typeof claims.name === 'string' ? claims.name : ''};
    },
  };
}
