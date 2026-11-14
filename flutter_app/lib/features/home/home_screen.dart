import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/i18n/relo_i18n.dart';
import '../../core/theme/motion_tokens.dart';
import '../../core/theme/relo_theme.dart';
import '../../core/utils/dday.dart';
import '../../shared/models/domain_models.dart';
import '../../shared/state/relo_store.dart';
import '../../shared/widgets/claim_row.dart';
import '../../shared/widgets/relo_mascot.dart';
import '../../shared/widgets/relo_primitives.dart';
import '../assistant/assistant_sheet.dart';
import '../../shared/widgets/relo_icons.dart';

/// @module features/home/home_screen
/// @layer Feature Module — Home
/// @purpose 홈은 파란 카드 하나와 그 아래 조용한 목록, 그리고 도우미에게 말 거는 입력칸이다
///          (DESIGN.md 7절). 상자는 맨 위 카드(받을 돈 + 말랑이) 하나뿐이고, 지금 할 일은
///          상자 없이 줄로만 보여 준다. 말로 부탁하면 그 아래로 대화가 쌓인다.
///          AI는 직접 저장하거나 보내지 않고, 답 아래 카드로 해당 화면을 연다.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// 등장 효과는 앱을 켠 첫 화면에서만 재생한다 (탭을 오갈 때는 즉시)
  static bool _playedEntrance = false;
  late final bool _animateEntrance = !_playedEntrance;

  final _input = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();

  /// 마지막으로 그린 대화의 끝. 달라지면(새 말·답을 기다리는 중) 맨 아래로 내린다.
  Object? _seenTail;
  bool _firstBuild = true;

  @override
  void initState() {
    super.initState();
    _playedEntrance = true;
  }

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send(ReloStore store, String text, {String? claimId}) {
    if (text.trim().isEmpty || store.assistantBusy) return;
    _input.clear();
    // 건을 짚어서 물은 뒤의 이어지는 질문도 같은 건에 대한 것으로 본다
    store.askAssistant(text,
        claimId: claimId ?? store.activeAssistantClaimId);
  }

  /// 새 말이 오면 대화의 끝이 보이게 내린다. 대화가 있는 채로 홈에 돌아왔을 때는 바로 옮긴다.
  void _followConversation(ReloStore store) {
    final turns = store.assistantTurns;
    final Object? tail =
        store.assistantBusy ? 'busy' : (turns.isEmpty ? null : turns.last);
    final jump = _firstBuild;
    _firstBuild = false;
    if (identical(tail, _seenTail)) return;
    _seenTail = tail;
    if (tail == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final end = _scroll.position.maxScrollExtent;
      if (jump) {
        _scroll.jumpTo(end);
      } else {
        _scroll.animateTo(end,
            duration: ReloMotion.sheet, curve: ReloMotion.enter);
      }
    });
  }

  static int _byDeadline(ClaimView a, ClaimView b) {
    final da = DDay.daysLeft(a.deadline) ?? 9999;
    final db = DDay.daysLeft(b.deadline) ?? 9999;
    return da.compareTo(db);
  }

  @override
  Widget build(BuildContext context) {
    final store = ReloScope.of(context);
    final palette = ReloPalette.of(context);
    final s = store.strings;

    final active = store.claims.where((c) => !c.deleted).toList();
    final inFlight = active.where((c) => !isClaimDone(c)).toList()
      ..sort(_byDeadline);
    final needsConsent = store.user != null &&
        store.user!.aiConsentAt == null &&
        !store.isOfflineFallback;
    final empty = active.isEmpty && store.assistantTurns.isEmpty;
    _followConversation(store);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: empty
              ? _buildFirst(store, palette, s)
              : _buildFeed(store, palette, s, active, inFlight),
        ),
        if (needsConsent)
          _buildConsent(store, palette)
        else ...[
          _buildChips(store, palette, s, inFlight, first: empty),
          _buildInput(store, palette, s),
        ],
      ],
    );
  }

  // ── 위에서 아래로: 파란 카드 → 지금 할 일 → 주고받은 말 ─────────────────

  Widget _buildFeed(
    ReloStore store,
    ReloPalette palette,
    ReloStrings s,
    List<ClaimView> active,
    List<ClaimView> inFlight,
  ) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    Widget entrance(Widget child, int order) {
      if (!_animateEntrance || reduceMotion) return child;
      return child
          .animate(delay: Duration(milliseconds: 450 + order * 60))
          .fadeIn(duration: ReloMotion.listItem, curve: ReloMotion.enter)
          .slideY(
              begin: 0.08,
              end: 0,
              duration: ReloMotion.listItem,
              curve: ReloMotion.enter);
    }

    Widget arrive(Widget child) {
      if (reduceMotion) return child;
      return child
          .animate()
          .fadeIn(duration: ReloMotion.listItem, curve: ReloMotion.enter)
          .slideY(
              begin: 0.08,
              end: 0,
              duration: ReloMotion.listItem,
              curve: ReloMotion.enter);
    }

    Widget chat(Widget child) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: child,
        );

    var order = 0;
    final items = <Widget>[];

    // 1. 파란 카드: 받을 돈을 크게, 말랑이가 카드에 걸터앉는다
    if (active.isNotEmpty) {
      items.add(KeyedSubtree(
        key: const ValueKey('hero'),
        child: entrance(_buildMoney(store, s, active), order++),
      ));
    }

    // 2. 지금 할 일: 마감이 가까운 건부터 세 건, 상자 없이 줄로만
    if (inFlight.isNotEmpty) {
      items.add(KeyedSubtree(
        key: const ValueKey('todo'),
        child: entrance(
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 34, 20, 2),
            child: Text(
              s.homeTodo,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: palette.subtle,
              ),
            ),
          ),
          order++,
        ),
      ));
      for (final c in inFlight.take(3)) {
        items.add(KeyedSubtree(
          key: ValueKey('row_${c.id}'),
          child: entrance(ClaimRow(claim: c), order++),
        ));
      }
    } else if (active.isNotEmpty) {
      items.add(KeyedSubtree(
        key: const ValueKey('idle'),
        child: entrance(
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 34, 20, 0),
            child: Text(
              s.homeIdle,
              style:
                  TextStyle(fontSize: 14, color: palette.subtle, height: 1.5),
            ),
          ),
          order++,
        ),
      ));
    }

    // 3. 주고받은 말
    final turns = store.assistantTurns;
    if (turns.isNotEmpty || store.assistantBusy) {
      items.add(const SizedBox(key: ValueKey('gap'), height: 24));
    }
    for (var i = 0; i < turns.length; i++) {
      final turn = turns[i];
      items.add(KeyedSubtree(
        key: ValueKey('turn_${i}_${turn.fromUser}'),
        child: arrive(chat(
          turn.fromUser
              ? _UserBubble(text: turn.text)
              : _buildAnswer(store, palette, s, turn),
        )),
      ));
    }
    if (store.assistantBusy) {
      items.add(chat(_Thinking(
        key: const ValueKey('thinking'),
        label: s.assistantThinking,
      )));
    }
    if (turns.any((turn) => !turn.fromUser)) {
      items.add(Padding(
        key: const ValueKey('disclaimer'),
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 0),
        child: Text(
          s.assistantDisclaimer,
          style: TextStyle(fontSize: 12, color: palette.subtle, height: 1.4),
        ),
      ));
    }

    return SingleChildScrollView(
      controller: _scroll,
      padding: const EdgeInsets.only(top: 6, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: items,
      ),
    );
  }

  /// 받을 돈 / 받은 돈 (통화별 합계는 내 환불과 같은 계산을 쓴다)
  Widget _buildMoney(ReloStore store, ReloStrings s, List<ClaimView> active) {
    final money = ClaimMoney.of(active);
    return _MoneyHero(
      label: s.homeMoneyDue(money.dueCount),
      amount: money.due,
      receivedLabel: s.homeMoneyReceived,
      received: money.received,
      semanticLabel: '${s.navClaims} ${s.homeMoneyDue(money.dueCount)}',
      onTap: () => store.navigateToTab(2),
      // 말랑이: 앱을 켠 첫 화면에서 인사로 한 번 뛰고, 답을 기다릴 땐 생각하는 얼굴,
      // 답이 도착하면 또 한 번 뛴다
      greet: _animateEntrance,
      thinking: store.assistantBusy,
      answers: store.assistantTurns.where((turn) => !turn.fromUser).length,
    );
  }

  /// 도우미의 답: 말풍선 + (있으면) 화면을 여는 카드 하나
  Widget _buildAnswer(
    ReloStore store,
    ReloPalette palette,
    ReloStrings s,
    AssistantTurn turn,
  ) {
    ClaimView? claim;
    for (final c in store.claims) {
      if (c.id == turn.claimId) claim = c;
    }
    final label = s.assistantAction(turn.action);

    Widget? card;
    if (turn.action == 'open_claim' && claim != null) {
      card = ClaimRow(claim: claim, boxed: true);
    } else if (label.isNotEmpty) {
      card = _ActionCard(
        icon: switch (turn.action) {
          'draft_email' => ReloIcons.mail,
          'analyze_reply' => ReloIcons.chats,
          'new_claim' => ReloIcons.add,
          _ => ReloIcons.forward,
        },
        title: label,
        subtitle: claim == null ? null : shortClaimTitle(claim.title),
        onTap: () => runAssistantAction(store, turn),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AssistantBubble(text: turn.text),
        if (turn.offline)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              s.assistantOfflineNote,
              style: TextStyle(fontSize: 12, color: palette.subtle),
            ),
          ),
        if (card != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: card,
          ),
      ],
    );
  }

  // ── 환불 건이 하나도 없을 때: "무슨 일이 있었어요?" ─────────────────────

  /// 처음 쓰는 사람에게는 무슨 일이 있었는지 하나만 고르게 한다.
  /// 고르면 그 내용이 채워진 신청 화면이 열린다.
  Widget _buildFirst(ReloStore store, ReloPalette palette, ReloStrings s) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: ReloMascot(size: 96, hopOnTap: true, hopOnAppear: true),
            ),
            const SizedBox(height: 14),
            Text(
              s.homeFirstTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: palette.ink,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              s.homeFirstSub,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: palette.subtle, height: 1.5),
            ),
            const SizedBox(height: 18),
            for (final option in s.homeFirstOptions)
              _FirstOption(
                label: option.label,
                onTap: () => store.launchWizardWithPreset(
                  kind: 'refund',
                  issue: option.issue,
                ),
              ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => store.navigateToTab(1),
                child: Text(
                  s.homeFirstReceipt,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: palette.focusRing,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 바로 고르는 말 ───────────────────────────────────────────────────

  Widget _buildChips(
    ReloStore store,
    ReloPalette palette,
    ReloStrings s,
    List<ClaimView> inFlight, {
    required bool first,
  }) {
    final ko = store.locale == ReloLocale.ko;
    final turns = store.assistantTurns;
    final last = turns.isEmpty ? null : turns.last;
    final chips = <({String label, VoidCallback onTap})>[
      // 신청은 여기서 시작한다 (탭에 따로 두지 않는다). 늘 같은 자리인 맨 앞에 둔다.
      // 처음 화면에서는 위의 세 가지가 신청을 맡으므로 또 두지 않는다.
      if (!first)
        (label: '+ ${s.homeNewClaim}', onTap: () => store.navigateToTab(1)),
    ];

    if (last != null && !last.fromUser && last.suggestions.isNotEmpty) {
      // 방금 답에 이어서 물을 만한 것
      for (final q in last.suggestions.take(3)) {
        chips.add((label: q, onTap: () => _send(store, q)));
      }
    } else if (first) {
      // 아직 건이 없으니 누구나 궁금한 것 두 가지
      for (final q in s.assistantStarters.skip(3).take(2)) {
        chips.add((label: q, onTap: () => _send(store, q)));
      }
    } else {
      // 가장 급한 건에 지금 필요한 부탁 하나
      if (inFlight.isNotEmpty && ko) {
        final c = inFlight.first;
        final ask = switch (c.state) {
          'preparing' || 'review' => '판매자 메시지 써 줘',
          'awaiting' => '독촉 메시지 써 줘',
          'negotiating' => '답장 해석해 줘',
          _ => null,
        };
        if (ask != null) {
          chips.add((label: ask, onTap: () => _send(store, ask, claimId: c.id)));
        }
      }
      // 짧게 보여 주고, 물을 때는 온전한 문장으로 묻는다
      final full = s.assistantStarters.first;
      chips.add((label: s.homeAskStatus, onTap: () => _send(store, full)));
    }

    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 8),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => Material(
          color: Colors.transparent,
          shape: StadiumBorder(
            side: BorderSide(color: palette.line, width: 1.4),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              chips[i].onTap();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Center(
                child: Text(
                  chips[i].label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: palette.muted,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── 입력칸 ──────────────────────────────────────────────────────────

  Widget _buildInput(ReloStore store, ReloPalette palette, ReloStrings s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      child: Container(
        padding: const EdgeInsets.only(left: 18, right: 6),
        decoration: BoxDecoration(
          color: palette.raised,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                focusNode: _focus,
                minLines: 1,
                maxLines: 4,
                maxLength: 1000,
                textInputAction: TextInputAction.send,
                onSubmitted: (v) => _send(store, v),
                style: TextStyle(fontSize: 15, color: palette.ink),
                decoration: InputDecoration(
                  hintText: s.homeInputHint,
                  hintStyle: TextStyle(color: palette.subtle),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
            ListenableBuilder(
              listenable: _input,
              builder: (context, _) {
                final ready =
                    _input.text.trim().isNotEmpty && !store.assistantBusy;
                return Semantics(
                  button: true,
                  label: s.homeInputHint,
                  child: AnimatedContainer(
                    duration: ReloMotion.press,
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: ready ? palette.brand : palette.inset,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: ready ? () => _send(store, _input.text) : null,
                      icon: Icon(
                        ReloIcons.send,
                        size: 20,
                        color: ready ? Colors.white : palette.subtle,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsent(ReloStore store, ReloPalette palette) {
    final s = store.strings;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: ReloCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              s.assistantConsentTitle,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: palette.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              s.assistantConsentBody,
              style: TextStyle(fontSize: 13, color: palette.muted, height: 1.4),
            ),
            const SizedBox(height: 12),
            ReloButton(
              text: s.assistantConsentButton,
              height: 44,
              onPressed: store.toggleAiConsent,
            ),
          ],
        ),
      ),
    );
  }
}

// ── 파란 카드 ─────────────────────────────────────────────────────────

/// 홈의 하나뿐인 상자. 받을 돈을 크게 쓰고, 말랑이가 오른쪽 아래에 걸터앉는다.
/// 누르면 내 환불이 열린다.
class _MoneyHero extends StatelessWidget {
  final String label;
  final String amount;
  final String receivedLabel;
  final String received;
  final String semanticLabel;
  final VoidCallback onTap;
  final bool greet;
  final bool thinking;
  final int answers;
  const _MoneyHero({
    required this.label,
    required this.amount,
    required this.receivedLabel,
    required this.received,
    required this.semanticLabel,
    required this.onTap,
    required this.greet,
    required this.thinking,
    required this.answers,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Semantics(
        button: true,
        label: semanticLabel,
        child: Stack(
          fit: StackFit.passthrough,
          clipBehavior: Clip.none,
          children: [
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              clipBehavior: Clip.antiAlias,
              child: Ink(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1E56C9),
                      Color(0xFF18439E),
                      Color(0xFF15367F),
                    ],
                    stops: [0, 0.55, 1],
                  ),
                ),
                child: InkWell(
                  onTap: onTap,
                  child: Padding(
                    // 오른쪽은 말랑이 자리
                    padding: const EdgeInsets.fromLTRB(20, 20, 132, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFC7DBFF),
                          ),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            amount,
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -1,
                              height: 1.2,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text.rich(
                          TextSpan(
                            text: '$receivedLabel ',
                            children: [
                              TextSpan(
                                text: received,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFB4CDFF),
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // 카드 끝에 걸터앉은 것이 분명히 보이도록 카드 아래로 32 내린다 (조금만 내리면 어긋난 것처럼 보인다).
            // 누르면 윙크하며 폴짝 뛴다.
            Positioned(
              right: 8,
              bottom: -32,
              child: ReloMascot(
                size: 118,
                onBrand: true,
                hopOnTap: true,
                hopOnAppear: greet,
                hopSignal: answers,
                mood: thinking ? ReloMascotMood.thinking : ReloMascotMood.idle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 처음 화면의 고르는 줄 ─────────────────────────────────────────────

class _FirstOption extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _FirstOption({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = ReloPalette.of(context);
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: palette.line.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 17),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: palette.ink,
                        ),
                      ),
                    ),
                    Icon(ReloIcons.chevronRight,
                        size: 22, color: palette.subtle),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── 말풍선 ────────────────────────────────────────────────────────────

class _AssistantBubble extends StatelessWidget {
  final String text;
  const _AssistantBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    final palette = ReloPalette.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10, right: 40),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: palette.raised,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: palette.body,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  final String text;
  const _UserBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    final palette = ReloPalette.of(context);
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10, left: 64),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: palette.brand,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.white,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

class _Thinking extends StatelessWidget {
  final String label;
  const _Thinking({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final palette = ReloPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const ReloMascot(size: 30, mood: ReloMascotMood.thinking),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: palette.raised,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 14, color: palette.muted),
                ),
                const SizedBox(width: 6),
                for (var i = 0; i < 3; i++)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: palette.muted,
                      shape: BoxShape.circle,
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(
                        begin: 0.25,
                        end: 1,
                        delay: (150 * i).ms,
                        duration: 450.ms,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 대화 속 카드 ──────────────────────────────────────────────────────

/// 다른 화면을 여는 카드: 아이콘 + 할 일 + (어느 건인지)
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ReloPalette.of(context);
    return Semantics(
      button: true,
      label: title,
      child: Material(
        color: palette.raised,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            child: Row(
              children: [
                ReloIconTile(icon: icon, color: palette.inset),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: palette.ink,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyle(fontSize: 13, color: palette.subtle),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(ReloIcons.chevronRight,
                    size: 22, color: palette.subtle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
