// Claim CRUD, state changes and trash. Version comes from If-Match,
// retry keys from Idempotency-Key (see http/request.mjs).
export function registerClaimRoutes(router, {services}) {
  const {claims} = services;

  router.get('/api/claims', ctx => ({
    body: {claims: claims.list(ctx.user.id, {
      q: ctx.query.get('q') || '',
      state: ctx.query.get('state') || '',
      deleted: ctx.query.get('deleted') === '1',
    })},
  }));

  router.post('/api/claims', async ctx => {
    const claim = claims.create(ctx.user.id, await ctx.json(), ctx.idempotencyKey);
    // If the person has left their claims to the agent, it starts on the new request by itself.
    services.agent.wake(ctx.user.id, claim.id, 'filed', ctx.header('x-relo-locale'));
    return {status: 201, body: {claim}};
  });

  router.get('/api/claims/:id', ctx => ({
    body: {claim: claims.detail(ctx.user.id, ctx.params.id, {includeDeleted: ctx.query.get('deleted') === '1'})},
  }));

  router.patch('/api/claims/:id', async ctx => ({
    body: {claim: claims.update(ctx.user.id, ctx.params.id, ctx.version, await ctx.json())},
  }));

  router.delete('/api/claims/:id', async ctx => ({
    body: {claim: claims.moveToTrash(ctx.user.id, ctx.params.id, ctx.version, await ctx.json())},
  }));

  router.post('/api/claims/:id/restore', ctx => ({
    body: {claim: claims.restore(ctx.user.id, ctx.params.id, ctx.version)},
  }));

  router.post('/api/claims/:id/transition', async ctx => ({
    body: {claim: claims.transition(ctx.user.id, ctx.params.id, ctx.version, await ctx.json())},
  }));
}
