import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

import '../../core/theme/motion_tokens.dart';
import '../../core/theme/relo_theme.dart';
import '../../shared/models/domain_models.dart';
import '../../shared/state/relo_store.dart';
import '../../shared/widgets/relo_mascot.dart';
import '../../shared/widgets/relo_primitives.dart';

/// 도우미 답변 아래 버튼을 눌렀을 때 할 일. 없으면 스토어로 화면을 옮긴다.
typedef AssistantActionHandler = void Function(AssistantTurn turn);

/// @module features/assistant/assistant_sheet
/// @purpose ReLo 도우미 대화 창. 아래에서 올라오는 시트(smooth_sheets)이고,
///          아래로 끌어내리면 닫힌다. 대화는 스토어에 남아서 다시 열어도 이어진다.
///          AI는 직접 아무것도 바꾸지 않고, 답 아래 버튼으로 해당 화면을 연다.
Future<void> showReloAssistant(
  BuildContext context, {
  String? claimId,
  AssistantActionHandler? onAction,
}) {
  HapticFeedback.selectionClick();
  return Navigator.of(context).push(
    ModalSheetRoute<void>(
      swipeDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: ReloMotion.sheet,
      builder: (_) => ReloAssistantSheet(claimId: claimId, onAction: onAction),
    ),
  );
}

/// 도우미 버튼의 기본 동작: 해당 화면으로 옮긴다.
void runAssistantAction(ReloStore store, AssistantTurn turn) {
  final id = turn.claimId;
  switch (turn.action) {
    case 'open_claim' when id != null:
      store.openClaimDetail(id);
    case 'draft_email' when id != null:
      store.openClaimDetail(id, subTab: 0);
    case 'analyze_reply' when id != null:
      store.openClaimDetail(id, subTab: 1);
    case 'new_claim':
      store.navigateToTab(1);
  }
}

class ReloAssistantSheet extends StatefulWidget {
  final String? claimId;
  final AssistantActionHandler? onAction;
  const ReloAssistantSheet({super.key, this.claimId, this.onAction});

  @override
  State<ReloAssistantSheet> createState() => _ReloAssistantSheetState();
}

class _ReloAssistantSheetState extends State<ReloAssistantSheet> {
  late String? _claimId = widget.claimId;
  final _input = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _send(ReloStore store, String text) {
    if (text.trim().isEmpty || store.assistantBusy) return;
    _input.clear();
    store.askAssistant(text, claimId: _claimId);
  }

  void _runAction(ReloStore store, AssistantTurn turn) {
    Navigator.of(context).pop();
    (widget.onAction ?? (t) => runAssistantAction(store, t))(turn);
  }

  @override
  Widget build(BuildContext context) {
    final store = ReloScope.of(context);
    final palette = ReloPalette.of(context);
    // 시트 안쪽 MediaQuery는 시트가 바꿔 놓으므로, 키보드 높이는 화면 기준으로 읽는다
    final screen = MediaQueryData.fromView(View.of(context));
    final height = math.min(
      screen.size.height * 0.88,
      screen.size.height - screen.viewInsets.bottom - screen.padding.top - 12,
    );

    return Sheet(
      decoration: MaterialSheetDecoration(
        size: SheetSize.fit,
        color: palette.canvas,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
      ),
      child: SizedBox(
        height: height,
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final s = store.strings;
            ClaimView? claim;
            for (final c in store.claims) {
              if (c.id == _claimId) claim = c;
            }
            final needsConsent = store.user != null &&
                store.user!.aiConsentAt == null &&
                !store.isOfflineFallback;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  children: [
                    _buildHandle(palette),
                    _buildHeader(store, palette),
                    if (claim != null) _buildContextPill(store, claim, palette),
                    Expanded(
                      child: store.assistantTurns.isEmpty
                          ? _buildWelcome(store, claim != null, palette)
                          : _buildConversation(store, palette),
                    ),
                    needsConsent
                        ? _buildConsent(store, palette)
                        : _buildInput(store, palette),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                          20, 0, 20, 10 + screen.padding.bottom),
                      child: Text(
                        s.assistantDisclaimer,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: palette.subtle),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHandle(ReloPalette palette) {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 4),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: palette.subtle.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }

  Widget _buildHeader(ReloStore store, ReloPalette palette) {
    final s = store.strings;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close_rounded, color: palette.body),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const ReloMascot(size: 28),
                const SizedBox(width: 8),
                Text(
                  s.assistantName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: palette.ink,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: s.assistantNewChat,
            onPressed: store.assistantTurns.isEmpty
                ? null
                : store.clearAssistantConversation,
            icon: Icon(Icons.add_comment_outlined,
                color: store.assistantTurns.isEmpty
                    ? palette.subtle.withValues(alpha: 0.4)
                    : palette.body),
          ),
        ],
      ),
    );
  }

  Widget _buildContextPill(
      ReloStore store, ClaimView claim, ReloPalette palette) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
        decoration: BoxDecoration(
          color: palette.brandSoft,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 16, color: palette.brandHover),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                store.strings.assistantContext(claim.vendor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: palette.ink,
                ),
              ),
            ),
            InkWell(
              customBorder: const CircleBorder(),
              onTap: () => setState(() => _claimId = null),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child:
                    Icon(Icons.close_rounded, size: 16, color: palette.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _starterIcons = [
    (Icons.local_shipping_outlined, Color(0xFF34D399)),
    (Icons.edit_note_rounded, Color(0xFF60A5FA)),
    (Icons.translate_rounded, Color(0xFFA78BFA)),
    (Icons.compare_arrows_rounded, Color(0xFFFBBF24)),
    (Icons.schedule_rounded, Color(0xFFF472B6)),
  ];

  Widget _buildWelcome(ReloStore store, bool aboutClaim, ReloPalette palette) {
    final s = store.strings;
    final starters =
        aboutClaim ? s.assistantClaimStarters : s.assistantStarters;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      children: [
        const Center(child: ReloMascot(size: 76, mood: ReloMascotMood.happy)),
        const SizedBox(height: 16),
        Text(
          s.assistantGreeting,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: palette.ink,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          s.assistantGreetingSub,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: palette.muted, height: 1.4),
        ),
        const SizedBox(height: 24),
        for (var i = 0; i < starters.length; i++)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _StarterRow(
                icon: _starterIcons[i % _starterIcons.length].$1,
                color: _starterIcons[i % _starterIcons.length].$2,
                text: starters[i],
                onTap: () => _send(store, starters[i]),
              ),
            )
                .animate()
                .fadeIn(
                    delay: ReloMotion.listStagger * (i + 2),
                    duration: ReloMotion.listItem)
                .slideY(begin: 0.15, end: 0, curve: ReloMotion.enter),
          ),
      ],
    );
  }

  Widget _buildConversation(ReloStore store, ReloPalette palette) {
    final turns = store.assistantTurns;
    final items = <Widget>[
      if (store.assistantBusy) _buildThinking(store, palette),
      for (var i = turns.length - 1; i >= 0; i--)
        turns[i].fromUser
            ? _buildUserBubble(turns[i], palette)
            : _buildAssistantBubble(
                store, turns[i], palette, i == turns.length - 1),
    ];
    // 아래부터 쌓이도록 뒤집어 둔다. 새 말이 오면 자동으로 맨 아래가 보인다.
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: items.length,
      itemBuilder: (_, i) => items[i],
    );
  }

  Widget _buildUserBubble(AssistantTurn turn, ReloPalette palette) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 56),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: palette.brand,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(6),
          ),
        ),
        child: Text(
          turn.text,
          style:
              const TextStyle(fontSize: 14, color: Colors.white, height: 1.4),
        ),
      ),
    ).animate().fadeIn(duration: ReloMotion.press * 2).slideX(begin: 0.05);
  }

  Widget _buildAssistantBubble(
    ReloStore store,
    AssistantTurn turn,
    ReloPalette palette,
    bool latest,
  ) {
    final s = store.strings;
    final actionLabel = s.assistantAction(turn.action);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ReloMascot(size: 30, animate: false),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(right: 32),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                  ),
                  child: Text(
                    turn.text,
                    style: TextStyle(
                        fontSize: 14, color: palette.ink, height: 1.5),
                  ),
                ),
                if (turn.offline)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text(
                      s.assistantOfflineNote,
                      style: TextStyle(fontSize: 11, color: palette.subtle),
                    ),
                  ),
                if (actionLabel.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _ActionPill(
                    label: actionLabel,
                    onTap: () => _runAction(store, turn),
                  ),
                ],
                if (latest && turn.suggestions.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final q in turn.suggestions)
                        ActionChip(
                          label: Text(q),
                          onPressed: () => _send(store, q),
                          backgroundColor: palette.canvas,
                          side: BorderSide(color: palette.line),
                          shape: const StadiumBorder(),
                          labelStyle:
                              TextStyle(fontSize: 12, color: palette.body),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: ReloMotion.listItem).slideY(begin: 0.08);
  }

  Widget _buildThinking(ReloStore store, ReloPalette palette) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          const ReloMascot(size: 30, mood: ReloMascotMood.thinking),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  store.strings.assistantThinking,
                  style: TextStyle(fontSize: 13, color: palette.muted),
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

  Widget _buildInput(ReloStore store, ReloPalette palette) {
    final s = store.strings;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.only(left: 18, right: 6),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(28),
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
                style: TextStyle(fontSize: 14, color: palette.ink),
                decoration: InputDecoration(
                  hintText: s.assistantInputHint,
                  hintStyle: TextStyle(color: palette.subtle),
                  border: InputBorder.none,
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
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
                  label: s.assistantInputHint,
                  child: AnimatedContainer(
                    duration: ReloMotion.press,
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: ready ? palette.brand : palette.sunken,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: ready ? () => _send(store, _input.text) : null,
                      icon: Icon(
                        Icons.arrow_upward_rounded,
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: ReloCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              s.assistantConsentTitle,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: palette.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              s.assistantConsentBody,
              style: TextStyle(fontSize: 12, color: palette.muted, height: 1.4),
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

class _StarterRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final VoidCallback onTap;
  const _StarterRow({
    required this.icon,
    required this.color,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ReloPalette.of(context);
    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: palette.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ActionPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = ReloPalette.of(context);
    return Material(
      color: palette.brandSoft,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: palette.brandHover,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_rounded,
                  size: 15, color: palette.brandHover),
            ],
          ),
        ),
      ),
    );
  }
}

/// 화면 위에 떠 있는 도우미 캐릭터. 화면을 스크롤해도 제자리에 있고,
/// 끌어서 옮기면 가까운 왼쪽·오른쪽 가장자리에 붙는다. 자리는 앱을 켜 둔 동안 기억한다.
/// 설정 > 화면에서 끌 수 있다.
class ReloAssistantLauncher extends StatefulWidget {
  const ReloAssistantLauncher({super.key});

  @override
  State<ReloAssistantLauncher> createState() => _ReloAssistantLauncherState();
}

class _ReloAssistantLauncherState extends State<ReloAssistantLauncher> {
  static const double _size = 52;
  static const double _margin = 12;
  static bool _onRight = true;
  static double? _top;

  bool _dragging = false;
  double _dragLeft = 0;

  @override
  Widget build(BuildContext context) {
    final store = ReloScope.of(context);
    // 글을 쓰는 동안(키보드가 올라와 있을 때)은 입력을 가리지 않게 숨긴다
    if (MediaQuery.viewInsetsOf(context).bottom > 0) {
      return const SizedBox.shrink();
    }
    return LayoutBuilder(
      builder: (context, box) {
        final maxTop = math.max(_margin, box.maxHeight - _size - _margin);
        final top = (_top ?? box.maxHeight - _size - 16).clamp(_margin, maxTop);
        final left = _dragging
            ? _dragLeft
            : (_onRight ? box.maxWidth - _size - _margin : _margin);
        return Stack(
          children: [
            AnimatedPositioned(
              duration: _dragging ? Duration.zero : ReloMotion.sheet,
              curve: Curves.easeOutBack,
              left: left,
              top: top,
              child: Semantics(
                button: true,
                label: '${store.strings.assistantName} 열기',
                child: GestureDetector(
                  onTap: () => showReloAssistant(
                    context,
                    claimId: store.activeTabIndex == 2
                        ? store.selectedClaimId
                        : null,
                  ),
                  onPanStart: (_) => setState(() {
                    _dragging = true;
                    _dragLeft = left;
                    _top = top;
                  }),
                  onPanUpdate: (d) => setState(() {
                    _dragLeft =
                        (_dragLeft + d.delta.dx).clamp(0, box.maxWidth - _size);
                    _top = (top + d.delta.dy).clamp(_margin, maxTop);
                  }),
                  onPanEnd: (_) => setState(() {
                    _dragging = false;
                    _onRight = _dragLeft + _size / 2 > box.maxWidth / 2;
                    HapticFeedback.selectionClick();
                  }),
                  child: AnimatedScale(
                    scale: _dragging ? 1.08 : 1,
                    duration: ReloMotion.press,
                    child: const _LauncherFace(size: _size),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LauncherFace extends StatelessWidget {
  final double size;
  const _LauncherFace({required this.size});

  @override
  Widget build(BuildContext context) {
    final body = size * 0.86;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        children: [
          // 캐릭터 몸통 아래 그림자
          Positioned(
            left: 0,
            top: size - body - size * 0.02,
            child: Container(
              width: body,
              height: body,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(body * 0.32),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1B64DA).withValues(alpha: 0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
            ),
          ),
          ReloMascot(size: size),
        ],
      ),
    );
  }
}
