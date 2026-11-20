import {MAX_FILE_BYTES} from '../services/file.service.mjs';

// AI suggestions. Responses are previews; the user saves through other routes.
export function registerAiRoutes(router, {services}) {
  const {ai, agent} = services;

  router.post('/api/ai/translate-issue', async ctx => ({
    body: await ai.translateIssue(ctx.user, await ctx.json()),
  }));

  // Raw body like a file upload; the file name travels URL-encoded in X-File-Name.
  router.post('/api/ai/extract', async ctx => ({
    body: await ai.extractDocument(ctx.user, {
      name: decodeURIComponent(ctx.header('x-file-name') || 'document'),
      mime: ctx.header('content-type') || '',
      bytes: await ctx.raw(MAX_FILE_BYTES + 1),
    }),
  }));

  router.post('/api/ai/assistant', async ctx => ({
    body: await ai.assistant(ctx.user, await ctx.json()),
  }));

  router.post('/api/claims/:id/ai/draft', async ctx => ({
    body: await ai.draft(ctx.user, ctx.params.id),
  }));

  router.post('/api/claims/:id/ai/analyze-reply', async ctx => ({
    body: await ai.analyzeReply(ctx.user, ctx.params.id, await ctx.json()),
  }));

  router.post('/api/claims/:id/ai/extract', async ctx => ({
    body: await ai.extract(ctx.user, ctx.params.id, await ctx.json()),
  }));

  // The agent loop: the model chooses which tool to run next, toward the goal of the claim.
  // Reading tools run at once. An action that would change the claim is only proposed: the run
  // comes back waiting, and nothing is saved until the person approves it in the next route.
  router.post('/api/claims/:id/ai/agent', async ctx => ({
    body: await agent.run(ctx.user, ctx.params.id, await ctx.json()),
  }));

  // The person's answer to a proposal ({approve: true | false}). The run then goes on.
  router.post('/api/claims/:id/ai/agent/:runId/decision', async ctx => ({
    body: await agent.decide(ctx.user, ctx.params.id, ctx.params.runId, await ctx.json()),
  }));

  // Whether the agent is at work on this claim right now, a proposal still waiting for an
  // answer, and what the last run did. No AI call.
  router.get('/api/claims/:id/ai/agent', ctx => ({
    body: agent.overview(ctx.user, ctx.params.id),
  }));

  // Every claim where the agent is waiting for the person's answer. No AI call.
  router.get('/api/ai/agent/waiting', ctx => ({
    body: {claims: agent.waitingList(ctx.user)},
  }));

  // New request: what the person wrote in one line, read against the items of their order
  // document. Returns which kind of request it is, which item, how many, and the English text.
  router.post('/api/ai/intake', async ctx => ({
    body: await ai.intake(ctx.user, await ctx.json()),
  }));
}
