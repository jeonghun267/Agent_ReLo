import {createAuthService} from './auth.service.mjs';
import {createClaimService} from './claim.service.mjs';
import {createFileService} from './file.service.mjs';
import {createDraftService} from './draft.service.mjs';
import {createReplyService} from './reply.service.mjs';
import {createReceiptService} from './receipt.service.mjs';
import {createAccountService} from './account.service.mjs';
import {createAiService} from './ai.service.mjs';
import {createPasskeyService} from './passkey.service.mjs';

// Builds the services in dependency order. Each receives only what it uses.
export function createServices({db, repos, config, aiProvider, mailProvider, googleProvider, logger}) {
  const base = {db, repos, config};
  const auth = createAuthService({...base, mail: mailProvider, google: googleProvider, logger});
  const claims = createClaimService(base);
  const withClaims = {...base, claims};
  const files = createFileService(withClaims);
  return {
    auth,
    claims,
    files,
    drafts: createDraftService(withClaims),
    replies: createReplyService(withClaims),
    receipts: createReceiptService(withClaims),
    account: createAccountService({...withClaims, auth}),
    ai: createAiService({...withClaims, files, provider: aiProvider}),
    passkeys: createPasskeyService({...base, auth}),
  };
}
