export function registerAccountRoutes(router, {services}) {
  router.post('/api/account/ai-consent', async ctx => {
    const {consent} = await ctx.json();
    return {body: {user: services.account.setAiConsent(ctx.user.id, consent === true)}};
  });

  // Leaves the person's claims to the agent, or takes them back ({on: true | false}).
  router.post('/api/account/agent-auto', async ctx => {
    const {on} = await ctx.json();
    return {body: {user: services.account.setAgentAuto(ctx.user.id, on === true)}};
  });

  // Notice emails on or off ({on: true | false}). The account emails are not affected.
  router.post('/api/account/notice-mail', async ctx => {
    const {on} = await ctx.json();
    return {body: {user: services.account.setNoticeMail(ctx.user.id, on === true)}};
  });

  router.get('/api/account/export', ctx => ({
    body: services.account.exportData(ctx.user.id),
    headers: {'Content-Disposition': `attachment; filename="relo-export-${new Date().toISOString().slice(0, 10)}.json"`},
  }));

  router.post('/api/account/delete', async ctx => {
    const {password} = await ctx.json();
    await services.account.deleteAccount(ctx.user.id, password);
    ctx.clearSession();
    return {body: {ok: true}};
  });
}
