import 'package:flutter/material.dart';

import '../../core/i18n/relo_i18n.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/relo_theme.dart';
import '../../core/utils/money_format.dart';
import '../../shared/models/agent_models.dart';
import '../../shared/models/claim_words.dart';
import '../../shared/models/domain_models.dart';
import '../../shared/state/relo_store.dart';
import '../../shared/widgets/ai_consent_sheet.dart';
import '../../shared/widgets/claim_row.dart';
import '../../shared/widgets/relo_icons.dart';
import '../../shared/widgets/relo_mascot.dart';
import '../../shared/widgets/relo_primitives.dart';

/// @module features/claims/agent_sheet
/// @layer Feature Module — Agent Run (the AI works toward the goal of this case)
/// @purpose 상세 화면의 "AI에게 맡기기". 목표(이 건의 환불 · 교환 · 수리)를 적고, 맡기면
///          AI가 단계마다 무엇을 골랐고 왜 골랐는지, 그 결과가 무엇인지를 보여 준다.
///          AI가 건을 바꾸려 할 때(주문 정보 고치기 · 쓴 글 저장하기)는 여기서 멈추고 묻는다:
///          허락하기 전에는 아무것도 저장되지 않는다. 쇼핑몰에 보내는 일은 하지 않는다.
///          "스스로 시작하기"를 켜 두면 신청 · 자료 추가 · 답장 저장 때 버튼 없이 시작하고,
///          그때도 허락이 필요한 일은 여기서 기다린다. 웹의 AgentRunPanel과 같은 일을 한다.

/// 목표 한 줄: "$150.00 환불 받기" · "교환품 받기" · "수리 받기"
String agentGoalText(ClaimView claim, ReloStrings s) => s.agGoal(
      claim.kind,
      MoneyFormat.formatMinor(claim.agreed ?? claim.claimed, claim.currency),
    );

/// 상세 화면에 놓는 한 줄 (이 화면의 상자는 이것 하나). 누르면 아래 시트가 열린다.
/// 둘째 줄은 지금 모습을 말한다: 목표, AI가 살펴보는 중, AI가 물어볼 것이 있음.
class AgentEntryRow extends StatelessWidget {
  final ClaimView claim;
  final VoidCallback onTap;
  const AgentEntryRow({super.key, required this.claim, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final store = ReloScope.of(context);
    final p = ReloPalette.of(context);
    final s = store.strings;
    final overview = store.agentOverviews[claim.id];
    final asks = overview?.waiting != null;
    final working = overview?.working == true;
    final line = asks
        ? s.agAsks
        : working
            ? s.agRowWorking
            : '${s.agGoalLabel} · ${agentGoalText(claim, s)}';

    return Semantics(
      button: true,
      label: '${s.agTitle} · $line',
      excludeSemantics: true,
      child: Material(
        color: p.raised,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            child: Row(
              children: [
                ReloIconTile(icon: ReloIcons.agent, color: p.inset),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.agTitle,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: p.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        line,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: asks ? FontWeight.w600 : FontWeight.w500,
                          color: asks ? p.focusRing : p.subtle,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(ReloIcons.chevronRight, size: 22, color: p.subtle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "AI에게 맡기기" 아래 시트를 연다. AI가 쓴 글을 메시지 칸에 넣겠다고 하면 [onUseDraft]로 넘긴다
/// (그것만으로는 아무것도 저장되지 않는다).
Future<void> showAgentSheet(
  BuildContext context,
  ClaimView claim, {
  required ValueChanged<String> onUseDraft,
}) {
  final p = ReloPalette.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: p.canvas,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _AgentSheet(claimId: claim.id, onUseDraft: onUseDraft),
  );
}

class _AgentSheet extends StatefulWidget {
  final String claimId;
  final ValueChanged<String> onUseDraft;
  const _AgentSheet({required this.claimId, required this.onUseDraft});

  @override
  State<_AgentSheet> createState() => _AgentSheetState();
}

class _AgentSheetState extends State<_AgentSheet> {
  /// 이 시트에서 누른 일(맡기기 · 답하기)이 돌아오기를 기다리는 중
  bool _pressed = false;
  bool _savingAuto = false;

  /// 이 시트에서 누른 일의 결과. 서버가 그 뒤로 넘어갔으면(스스로 시작함) 버린다.
  AgentRun? _latest;
  String? _error;
  bool _asked = false;

  ReloStrings get _s => ReloScope.of(context).strings;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = ReloScope.of(context);
    if (!_asked) {
      _asked = true;
      // 열 때 한 번, 서버에 지금 모습을 묻는다 (AI를 부르지 않는다)
      store.refreshAgentOverview(widget.claimId);
    }
    final overview = store.agentOverviews[widget.claimId];
    final latest = _latest;
    if (latest == null || _pressed || overview == null) return;
    // 여기서 누른 결과를 들고 있는 사이에 AI가 스스로 시작했거나, 보여 주던 제안이 닫혔으면 버린다
    final outdated = overview.working ||
        (latest.isWaiting
            ? overview.waiting?.runId != latest.runId
            : overview.waiting != null);
    if (outdated) _latest = null;
  }

  Future<void> _run(ReloStore store) async {
    // 다른 AI 버튼과 같이, 보내기 전에 무엇이 어디로 가는지 알리고 동의를 받는다
    if (!await ensureAiConsent(context)) return;
    if (!mounted) return;
    setState(() {
      _pressed = true;
      _error = null;
    });
    try {
      final run = await store.runAgent(widget.claimId);
      if (!mounted) return;
      setState(() {
        _pressed = false;
        _latest = run;
      });
    } on AiUnavailable catch (e) {
      if (!mounted) return;
      setState(() {
        _pressed = false;
        _error = e.message;
      });
    }
  }

  Future<void> _decide(ReloStore store, AgentRun run, bool approve) async {
    setState(() {
      _pressed = true;
      _error = null;
    });
    try {
      final next =
          await store.decideAgent(widget.claimId, run.runId, approve: approve);
      if (!mounted) return;
      setState(() {
        _pressed = false;
        _latest = next;
      });
    } on AiUnavailable catch (e) {
      if (!mounted) return;
      setState(() {
        _pressed = false;
        _error = e.message;
      });
    }
  }

  Future<void> _setAuto(ReloStore store, bool on) async {
    // 스스로 시작하면 누를 때마다 묻지 않고 이 건이 AI로 가므로, 켤 때 같은 안내와 동의를 거친다
    if (on && !await ensureAiConsent(context)) return;
    if (!mounted) return;
    setState(() {
      _savingAuto = true;
      _error = null;
    });
    // 바뀌면 이 줄의 글이 바뀐다. 바꾸지 못했을 때만 까닭을 버튼 위에 적는다
    // (아래 알림 띠는 이 시트에 가려서 보이지 않는다).
    String? problem;
    try {
      await store.setAgentAuto(on);
    } on ApiError catch (e) {
      problem = store.locale == ReloLocale.ko && e.explained && e.message.isNotEmpty
          ? e.message
          : _s.agAutoToastFail;
    } catch (_) {
      problem = _s.agAutoToastFail;
    }
    if (!mounted) return;
    setState(() {
      _savingAuto = false;
      _error = problem;
    });
  }

  void _useDraft(ReloStore store, String body) {
    widget.onUseDraft(store.signAsMe(body));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final store = ReloScope.of(context);
    final p = ReloPalette.of(context);
    final claim = store.findClaim(widget.claimId);
    if (claim == null) return const SizedBox.shrink();

    final overview = store.agentOverviews[widget.claimId];
    // 여기서 아무도 누르지 않았는데 AI가 일하고 있다: 스스로 시작한 것이다
    final onItsOwn = overview?.working == true && !_pressed;
    final working = _pressed || onItsOwn;
    // 화면을 열었을 때 기다리던 제안은 멈춘 자리에서 이어서 보여 준다
    final run = onItsOwn ? null : (_latest ?? overview?.waiting);
    final pending = run != null && run.isWaiting ? run.pending : null;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _s.agTitle,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: p.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text.rich(
                        TextSpan(
                          text: '${_s.agGoalLabel}  ',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: p.muted,
                          ),
                          children: [
                            TextSpan(
                              text: agentGoalText(claim, _s),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: p.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 무엇을 하는 기능인지는 맡기기 전에만 적는다 (결과가 있으면 결과가 먼저다)
                      if (run == null) ...[
                        const SizedBox(height: 6),
                        _muted(_s.agIdle, p),
                      ],
                      if (working) ...[
                        const SizedBox(height: 18),
                        _Working(
                          text: onItsOwn
                              ? _s.agAutoRunning
                              : _s.agRunning(store.config.agentMaxSteps),
                        ),
                      ],
                      if (!working && run == null) ...[
                        if (overview?.heldBack == true) ...[
                          const SizedBox(height: 14),
                          _muted(_s.agAutoHeldBack, p),
                        ],
                        if (overview?.last != null)
                          _LastRun(last: overview!.last!),
                      ],
                      if (!working && run != null) ...[
                        const SizedBox(height: 18),
                        _RunResult(
                          run: run,
                          claim: claim,
                          onUseDraft: (body) => _useDraft(store, body),
                        ),
                      ],
                      const SizedBox(height: 16),
                      _AutoRow(
                        on: store.agentAutoOn,
                        busy: _savingAuto,
                        onChanged: (on) => _setAuto(store, on),
                      ),
                    ],
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _error!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: p.danger,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              if (pending != null && !working)
                Row(
                  children: [
                    Expanded(
                      child: ReloButton(
                        text: _s.agDecline,
                        isPrimary: false,
                        onPressed: () => _decide(store, run!, false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ReloButton(
                        text: _s.agApprove,
                        onPressed: () => _decide(store, run!, true),
                      ),
                    ),
                  ],
                )
              else
                ReloButton(
                  text: run == null ? _s.agTitle : _s.agAgain,
                  busy: working,
                  onPressed: working ? null : () => _run(store),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _muted(String text, ReloPalette p) => Text(
      text,
      style: TextStyle(fontSize: 13, color: p.muted, height: 1.5),
    );

/// AI가 일하는 동안: 말랑이가 생각하고, 옆에 무엇을 하는 중인지 한 줄.
class _Working extends StatelessWidget {
  final String text;
  const _Working({required this.text});

  @override
  Widget build(BuildContext context) {
    final p = ReloPalette.of(context);
    return Semantics(
      liveRegion: true,
      child: Row(
        children: [
          const ReloMascot(size: 30, mood: ReloMascotMood.thinking),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: p.body, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

/// 스스로 시작하기: 무엇이 달라지고 무엇이 AI로 가는지 한 문단, 그리고 켜고 끄는 파란 글자.
/// 처음에는 꺼져 있다.
class _AutoRow extends StatelessWidget {
  final bool on;
  final bool busy;
  final ValueChanged<bool> onChanged;
  const _AutoRow({
    required this.on,
    required this.busy,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = ReloPalette.of(context);
    final s = ReloScope.of(context).strings;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: p.line.withValues(alpha: 0.5))),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              on ? s.agAutoOnNote : s.agAutoOffNote,
              style: TextStyle(fontSize: 12, color: p.subtle, height: 1.5),
            ),
            Transform.translate(
              offset: const Offset(-6, 0),
              child: ReloTextAction(
                label: on ? s.agAutoTurnOff : s.agAutoTurnOn,
                onTap: busy ? null : () => onChanged(!on),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 지난번에 한 일과, 그때 AI가 사람에게 한 말.
class _LastRun extends StatelessWidget {
  final AgentLastRun last;
  const _LastRun({required this.last});

  @override
  Widget build(BuildContext context) {
    final p = ReloPalette.of(context);
    final s = ReloScope.of(context).strings;
    if (last.steps.isEmpty && last.userAction == null) {
      return const SizedBox.shrink();
    }
    final steps = last.steps.map((step) {
      final label = s.agTool(step.tool);
      if (step.decision == 'approved') return '$label (${s.agLastApproved})';
      if (step.decision == 'declined') return '$label (${s.agLastDeclined})';
      return label;
    }).join(' → ');
    final startedBy = s.agStartedBy(last.startedBy);
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.raised,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (startedBy.isNotEmpty) _muted(startedBy, p),
            if (steps.isNotEmpty) _muted(s.agLast(s.date(last.endedAt), steps), p),
            if (last.userAction != null)
              Text.rich(
                TextSpan(
                  text: '${s.agLastSaid} ',
                  children: [
                    TextSpan(
                      text: last.userAction,
                      style: TextStyle(color: p.ink),
                    ),
                  ],
                ),
                style: TextStyle(fontSize: 13, color: p.muted, height: 1.5),
              ),
          ],
        ),
      ),
    );
  }
}

/// 실행 하나의 결과: 단계들, 허락을 기다리는 일, 어떻게 끝났는지.
class _RunResult extends StatelessWidget {
  final AgentRun run;
  final ClaimView claim;
  final ValueChanged<String> onUseDraft;
  const _RunResult({
    required this.run,
    required this.claim,
    required this.onUseDraft,
  });

  @override
  Widget build(BuildContext context) {
    final p = ReloPalette.of(context);
    final s = ReloScope.of(context).strings;
    final startedBy = s.agStartedBy(run.startedBy);
    final pending = run.isWaiting ? run.pending : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (startedBy.isNotEmpty) ...[
          _muted(startedBy, p),
          const SizedBox(height: 10),
        ],
        // 좁은 화면에서는 답해야 할 것과 결론을 먼저 보여 주고, 단계는 그 아래에 둔다.
        // (허락 버튼이 시트 아래에 붙어 있으므로, 무엇을 허락하는지가 버튼과 함께 보여야 한다.)
        if (pending != null) ...[
          _Approval(pending: pending),
          const SizedBox(height: 18),
        ],
        if (run.endedBy != null) ...[
          _muted(
            '${s.agEnded(run.endedBy!, run.maxSteps)}${run.reason.isEmpty ? '' : ' ${run.reason}'}',
            p,
          ),
          if (run.userAction != null) ...[
            const SizedBox(height: 6),
            Text.rich(
              TextSpan(
                text: '${s.agNextTitle}  ',
                style: const TextStyle(fontWeight: FontWeight.w700),
                children: [
                  TextSpan(
                    text: run.userAction,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              style: TextStyle(fontSize: 14, color: p.ink, height: 1.5),
            ),
          ],
          const SizedBox(height: 18),
        ],
        if (run.steps.isNotEmpty) ...[
          Text(
            s.agResultTitle,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: p.ink,
            ),
          ),
          for (final step in run.steps)
            _StepBlock(step: step, claim: claim, onUseDraft: onUseDraft),
        ],
        const SizedBox(height: 12),
        Text(
          s.agNote(run.aiCalls),
          style: TextStyle(fontSize: 12, color: p.subtle, height: 1.5),
        ),
      ],
    );
  }
}

/// 고치려는 값들: "주문번호: A → B"
class _ChangeLines extends StatelessWidget {
  final List<AgentChange> changes;
  const _ChangeLines({required this.changes});

  @override
  Widget build(BuildContext context) {
    final p = ReloPalette.of(context);
    final s = ReloScope.of(context).strings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final change in changes)
          Text(
            s.agChangeLine(change.field, change.from, change.to),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: p.ink,
              height: 1.5,
            ),
          ),
      ],
    );
  }
}

/// AI가 하려는 일. 무엇이 바뀌는지를 다 보여 주고, 답은 시트 아래의 두 버튼으로 한다.
class _Approval extends StatelessWidget {
  final AgentPending pending;
  const _Approval({required this.pending});

  @override
  Widget build(BuildContext context) {
    final p = ReloPalette.of(context);
    final s = ReloScope.of(context).strings;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.raised,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.agApprovalTitle,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: p.ink,
            ),
          ),
          const SizedBox(height: 2),
          _muted(s.agApprovalIntro, p),
          const SizedBox(height: 10),
          Text(
            s.agTool(pending.tool),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: p.ink,
            ),
          ),
          const SizedBox(height: 2),
          _muted('${s.agWhy} ${pending.reason}', p),
          if (pending.changes.isNotEmpty) ...[
            const SizedBox(height: 8),
            _ChangeLines(changes: pending.changes),
            _muted(s.agFixNote(pending.fileName ?? ''), p),
          ],
          if (pending.draftBody != null) ...[
            const SizedBox(height: 8),
            _muted(s.agDraftNote, p),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 220),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: p.inset,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                child: Text(
                  pending.draftBody!,
                  style: TextStyle(fontSize: 13, color: p.ink, height: 1.5),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 한 단계: 고른 도구 · 고른 까닭 · 그 결과. 상자 없이 가는 선으로 나눈다.
class _StepBlock extends StatelessWidget {
  final AgentStep step;
  final ClaimView claim;
  final ValueChanged<String> onUseDraft;
  const _StepBlock({
    required this.step,
    required this.claim,
    required this.onUseDraft,
  });

  @override
  Widget build(BuildContext context) {
    final p = ReloPalette.of(context);
    final s = ReloScope.of(context).strings;
    return ReloHairline(
      vertical: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: '${step.seq}. ${s.agTool(step.tool)}',
              children: [
                if (step.fileName != null)
                  TextSpan(
                    text: ' · ${step.fileName}',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: p.muted,
                    ),
                  ),
              ],
            ),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: p.ink,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 2),
          _muted('${s.agWhy} ${step.reason}', p),
          const SizedBox(height: 4),
          ..._outcome(p, s),
        ],
      ),
    );
  }

  Text _line(String text, Color color, {FontWeight weight = FontWeight.w500}) =>
      Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: weight,
          color: color,
          height: 1.5,
        ),
      );

  List<Widget> _outcome(ReloPalette p, ReloStrings s) {
    // 건을 바꾸는 단계: 무엇을 바꿨는지와 사람이 한 답
    if (step.decision.isNotEmpty) {
      if (step.decision == 'declined') return [_muted(s.agDecidedDeclined, p)];
      if (!step.ok) {
        return [
          _line(
            '${s.agDecidedFailed} ${step.message}',
            p.danger,
            weight: FontWeight.w600,
          ),
        ];
      }
      return [
        _ChangeLines(changes: step.changes),
        _muted(s.agDecidedApproved, p),
      ];
    }

    final result = step.result;
    if (!step.ok || result == null) {
      return [
        _line(
          '${s.agStepFailed} ${step.message}',
          p.danger,
          weight: FontWeight.w600,
        ),
      ];
    }

    String? text(dynamic raw) {
      final value = raw?.toString() ?? '';
      return value.isEmpty ? null : value;
    }

    if (step.tool == 'read_evidence') {
      final suggestion = result['suggestion'] is Map
          ? result['suggestion'] as Map
          : const <String, dynamic>{};
      final rows = [
        for (final (field, value) in [
          ('vendor', text(suggestion['vendor'])),
          ('orderRef', text(suggestion['orderRef'])),
          ('orderedOn', text(suggestion['orderedOn'])),
          ('currency', text(suggestion['currency'])),
          ('total', text(result['orderTotal'])),
        ])
          if (value != null) '${s.agField(field)} $value',
      ];
      return [
        if (rows.isNotEmpty) _line(rows.join(' · '), p.ink),
        if (step.mismatches.isEmpty)
          _muted(s.agNoMismatch, p)
        else ...[
          _line(s.agMismatchTitle, p.danger, weight: FontWeight.w600),
          for (final item in step.mismatches)
            _line(
              s.agMismatchLine(item.field, item.saved, item.read),
              p.danger,
              weight: FontWeight.w600,
            ),
        ],
      ];
    }

    if (step.tool == 'analyze_reply') {
      final amount = text(result['mentionedAmount']);
      final deadline = text(result['deadline']);
      final kind = text(result['suggestedKind']);
      final facts = [
        if (kind != null) '${s.agReplyKind} ${s.cwReplyKind(claim.kind, kind)}',
        if (amount != null)
          s.agMentioned(
            '${text(result['mentionedCurrency']) ?? claim.currency} $amount',
          ),
        if (deadline != null) s.agDeadline(deadline),
      ];
      return [
        if (text(result['summaryKo']) != null)
          _line(result['summaryKo'].toString(), p.ink, weight: FontWeight.w600),
        if (facts.isNotEmpty) _muted(facts.join(' · '), p),
      ];
    }

    // write_draft
    final body = text(result['body']);
    return [
      if (text(result['summaryKo']) != null)
        _line(result['summaryKo'].toString(), p.ink, weight: FontWeight.w600),
      if (body != null) ...[
        Text(
          body,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 13, color: p.muted, height: 1.5),
        ),
        Transform.translate(
          offset: const Offset(-6, 0),
          child: ReloTextAction(
            label: s.agUseDraft,
            onTap: () => onUseDraft(body),
          ),
        ),
      ],
    ];
  }
}
