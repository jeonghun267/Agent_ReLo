import {transaction} from '../repositories/db.mjs';
import {reject, forField} from '../domain/errors.mjs';
import {nowIso} from '../domain/primitives.mjs';

export function createAccountService(ctx) {
  const {db, repos, auth, claims} = ctx;

  function setAiConsent(ownerId, consent) {
    const at = nowIso();
    transaction(db, () => {
      repos.users.setAiConsent(ownerId, consent ? at : null, at);
      // Without consent nothing may go to the AI, so the agent may not start by itself either.
      if (!consent) repos.users.setAgentAuto(ownerId, null, at);
    });
    return repos.users.findById(ownerId);
  }

  // "맡겨 두기": the agent may start by itself when something happens on a claim. It is a
  // separate choice from the AI consent, because it sends data to the AI without a press each time.
  function setAgentAuto(ownerId, on) {
    const user = repos.users.findById(ownerId);
    reject(on && !user.aiConsentAt, 'AI에게 맡겨 두려면 먼저 AI 처리에 동의해 주세요.', 'ai_consent_required', 403);
    const at = nowIso();
    repos.users.setAgentAuto(ownerId, on ? (user.agentAutoAt ?? at) : null, at);
    return repos.users.findById(ownerId);
  }

  // Notice emails (today: "the agent is waiting for your answer"). On unless the person
  // switches them off. The account emails they asked for themself (confirming the address,
  // resetting the password) are not notices and are not affected.
  function setNoticeMail(ownerId, on) {
    const user = repos.users.findById(ownerId);
    const at = nowIso();
    repos.users.setNoticeMail(ownerId, on ? null : (user.noticeMailOffAt ?? at), at);
    return repos.users.findById(ownerId);
  }

  // Everything we hold about the user, including deleted claims and files.
  function exportData(ownerId) {
    const user = repos.users.findById(ownerId);
    return {
      format: 'relo-export-v1',
      exportedAt: nowIso(),
      user: {email: user.email, name: user.name, createdAt: user.createdAt, emailVerifiedAt: user.emailVerifiedAt, aiConsentAt: user.aiConsentAt, agentAutoAt: user.agentAutoAt, noticeMailOffAt: user.noticeMailOffAt},
      claims: repos.claims.listAllRows(ownerId).map(row => claims.toView(ownerId, row)),
      files: repos.files.listAllWithBytes(ownerId).map(({bytes, ...meta}) => ({...meta, base64: bytes.toString('base64')})),
      // Each time the AI chose its own steps for a claim: which tools, in what order, and why.
      agentRuns: repos.agentRuns.listAll(ownerId),
    };
  }

  // Permanent: removes the account and every row it owns.
  async function deleteAccount(ownerId, password) {
    const valid = await auth.verifyPassword(ownerId, password);
    forField('password', () => reject(!valid, '비밀번호가 맞지 않아요. 다시 입력하세요.', 'invalid_password', 403));
    transaction(db, () => repos.account.purgeOwner(ownerId));
  }

  return {setAiConsent, setAgentAuto, setNoticeMail, exportData, deleteAccount};
}
