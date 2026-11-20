import {reject} from '../domain/errors.mjs';
import {newId, nowIso} from '../domain/primitives.mjs';
import {cleanText, requireText} from '../domain/validation.mjs';
import {buildDraftRequest, parseDraftResult} from '../ai/prompts/draft.mjs';
import {buildIssueTranslationRequest, parseIssueTranslation, buildReplyAnalysisRequest, parseReplyAnalysis} from '../ai/prompts/translate.mjs';
import {buildExtractRequest, parseExtraction} from '../ai/prompts/extract.mjs';
import {buildAssistantRequest, parseAssistantReply, ASSISTANT_HISTORY_LIMIT} from '../ai/prompts/assistant.mjs';
import {buildPlanRequest, parsePlan} from '../ai/prompts/plan.mjs';
import {buildIntakeRequest, parseIntake} from '../ai/prompts/intake.mjs';
import {checkFile} from './file.service.mjs';

// AI suggestions only. Nothing here saves to a claim: the user reviews the
// result in the web app and saves it through the normal claim/draft/reply APIs.
export function createAiService({repos, config, claims, files, provider}) {
  function status() {
    return {enabled: provider.enabled, provider: provider.name, model: provider.enabled ? provider.model : null, hourlyLimit: config.ai.hourlyLimit};
  }

  function guard(user) {
    reject(!provider.enabled, 'AI 기능이 아직 설정되지 않았어요. 운영자가 GEMINI_API_KEY를 설정해야 합니다.', 'ai_disabled', 503);
    reject(!user.aiConsentAt, 'AI 기능을 쓰려면 먼저 AI 처리에 동의해 주세요.', 'ai_consent_required', 403);
    const since = new Date(Date.now() - 60 * 60 * 1000).toISOString();
    reject(repos.aiUsage.countSince(user.id, since) >= config.ai.hourlyLimit,
      `AI 기능은 한 시간에 ${config.ai.hourlyLimit}번까지 쓸 수 있어요. 잠시 후 다시 시도하세요.`, 'ai_rate_limited', 429);
  }

  // Every attempt, failed or not, is recorded for cost tracking and the hourly limit.
  async function run(user, claimId, request, parse) {
    guard(user);
    const usage = {inputTokens: 0, outputTokens: 0};
    try {
      const result = await provider.generateJson(request);
      Object.assign(usage, result.usage);
      const parsed = parse(result.data);
      record(user, claimId, request.capability, usage, true, '');
      return {...parsed, model: result.model};
    } catch (error) {
      record(user, claimId, request.capability, usage, false, error.code || 'error');
      throw error;
    }
  }

  function record(user, claimId, capability, usage, ok, errorCode) {
    repos.aiUsage.insert({
      id: newId(), ownerId: user.id, claimId, capability, model: provider.model,
      inputTokens: usage.inputTokens, outputTokens: usage.outputTokens, ok, errorCode, createdAt: nowIso(),
    });
  }

  async function draft(user, claimId) {
    const claim = claims.detail(user.id, claimId);
    const result = await run(user, claimId, buildDraftRequest(claim), parseDraftResult);
    return {...result, origin: 'ai', notice: 'AI가 쓴 초안이에요. 사실과 다른 내용이나 [확인 필요] 표시가 없는지 확인하고 고쳐 주세요.'};
  }

  async function translateIssue(user, input) {
    const text = requireText(input.text, 3000, '번역할 문제 설명을 입력하세요.');
    return run(user, null, buildIssueTranslationRequest(text), parseIssueTranslation);
  }

  async function analyzeReply(user, claimId, input) {
    const body = requireText(input.body, 8000, '분석할 판매처 답변을 붙여 넣어 주세요.');
    const claim = claims.detail(user.id, claimId);
    return run(user, claimId, buildReplyAnalysisRequest(claim, body), parseReplyAnalysis);
  }

  async function extract(user, claimId, input) {
    const file = files.fileOfClaim(user.id, claimId, input.fileId);
    const result = await run(user, claimId, buildExtractRequest(file), parseExtraction);
    return {...result, source: {fileId: file.id, name: file.name}};
  }

  // New-claim flow: the same reading for a document that is not stored yet.
  // The bytes go to the provider and are then dropped; the user attaches the
  // file as evidence after the claim is created.
  async function extractDocument(user, {name, mime, bytes}) {
    const safeName = checkFile({name, mime, bytes});
    const result = await run(user, null, buildExtractRequest({mime, bytes}), parseExtraction);
    return {...result, source: {fileId: null, name: safeName}};
  }

  // In-app help desk. The model sees a summary of the user's open claims (and
  // the one they asked from, if any) and may suggest one button; it never acts.
  async function assistant(user, input) {
    const message = requireText(input.message, 1000, '궁금한 내용을 입력하세요.');
    const current = input.claimId ? claims.detail(user.id, String(input.claimId)) : null;
    const history = (Array.isArray(input.history) ? input.history : [])
      .slice(-ASSISTANT_HISTORY_LIMIT)
      .map(turn => ({role: turn?.role === 'assistant' ? 'assistant' : 'user', text: cleanText(turn?.text, 1000)}))
      .filter(turn => turn.text);
    const mine = claims.list(user.id).slice(0, 20);
    const request = buildAssistantRequest({claims: mine, current, history, message, locale: input.locale});
    const claimIds = new Set(mine.map(claim => claim.id));
    if (current) claimIds.add(current.id);
    return run(user, current?.id ?? null, request, data => parseAssistantReply(data, claimIds));
  }

  // --- For the agent loop (agent.service.mjs). The functions above are not changed. ---

  // How many AI calls the user has left this hour. Refuses for the same reasons as any AI
  // call: AI is off, the user has not consented, or the hourly limit is already reached.
  function remaining(user) {
    guard(user);
    const since = new Date(Date.now() - 60 * 60 * 1000).toISOString();
    return config.ai.hourlyLimit - repos.aiUsage.countSince(user.id, since);
  }

  // One choice of the loop: which tool to run next for this claim, or stop. It goes through
  // run() like every other AI call, so it is counted, recorded and limited the same way.
  async function plan(user, claimId, claim, steps, {fileIds, replyIds, locale, earlierRuns, startedBy}) {
    return run(user, claimId, buildPlanRequest(claim, steps, locale, earlierRuns, startedBy), data => parsePlan(data, {fileIds, replyIds}));
  }

  // --- Filing a new request. Added next to the functions above, which are not changed. ---

  // What the person wrote in one line, read against the items of their order document (as the
  // document reading returned them; the list may be empty). The model chooses the kind of
  // request, the item and the quantity, and translates. Nothing is saved: the screen fills the
  // form with it and the person checks and files it.
  async function intake(user, input) {
    const text = requireText(input.text, 3000, '무슨 일인지 한 줄로 적어 주세요.');
    // Positions are kept as they are, so the item the model picks is the one the screen has.
    const items = (Array.isArray(input.items) ? input.items : []).slice(0, 20).map(item => ({
      name: cleanText(item?.name, 200),
      orderedQty: Number.isInteger(item?.orderedQty) && item.orderedQty > 0 ? item.orderedQty : 1,
    }));
    return run(user, null, buildIntakeRequest({text, items, locale: input.locale}), data => parseIntake(data, items));
  }

  return {status, draft, translateIssue, analyzeReply, extract, extractDocument, assistant, remaining, plan, intake};
}
