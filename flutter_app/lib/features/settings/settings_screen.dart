import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/i18n/relo_i18n.dart';
import '../../core/theme/relo_theme.dart';
import '../../core/network/api_client.dart';
import '../../shared/state/relo_store.dart';
import '../../shared/widgets/ai_consent_sheet.dart';
import '../../shared/widgets/relo_primitives.dart';
import '../auth/auth_screen.dart';
import '../compliance/business_footer.dart';
import '../../shared/widgets/relo_icons.dart';

/// @module features/settings/settings_screen
/// @layer Feature Module — Account, Accessibility, Email Unsubscribe & Immediate Purge
/// @purpose 계정, 화면(테마·고대비·언어), 알림, 백업, 약관·정책 열기, 탈퇴.
///          화면 구성은 DESIGN.md 7절 "설정": 맨 위 내 이름 → 구역 이름표 아래로 상자 없는 줄
///          (켜고 끄는 줄 · 눌러서 들어가는 줄) → 맨 아래 사업자 정보.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showJsonExportDialog(BuildContext context, ReloStore store) {
    final jsonText = store.exportUserDataAsJson();
    final palette = ReloPalette.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.surface,
        title: Text(
          store.strings.stBackupTitle,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: palette.ink,
          ),
        ),
        content: SizedBox(
          width: 340,
          child: SingleChildScrollView(
            child: SelectableText(
              jsonText,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: palette.body,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonText));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(store.strings.stBackupCopied)),
              );
            },
            child: Text(store.strings.cmCopy),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(store.strings.cmClose),
          ),
        ],
      ),
    );
  }

  /// "스스로 시작하기"를 켜거나 끈다. 서버가 받아야만 바뀌고, 받지 않으면 까닭을 말한다.
  Future<void> _setAgentAuto(
    BuildContext context,
    ReloStore store,
    bool on,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final s = store.strings;
    if (on && !await ensureAiConsent(context)) return;
    String text;
    try {
      await store.setAgentAuto(on);
      text = on ? s.agAutoToastOn : s.agAutoToastOff;
    } on ApiError catch (e) {
      text = store.locale == ReloLocale.ko && e.explained && e.message.isNotEmpty
          ? e.message
          : s.agAutoToastFail;
    } catch (_) {
      text = s.agAutoToastFail;
    }
    messenger.showSnackBar(SnackBar(content: Text(text)));
  }

  /// 알림 메일을 켜고 끈다. 서버가 받지 않았으면 스위치는 그대로이고, 그렇다고 알린다.
  Future<void> _setNoticeMail(
    BuildContext context,
    ReloStore store,
    bool on,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await store.setNoticeMail(on);
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(store.strings.stEmailFail)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = ReloScope.of(context);
    final palette = ReloPalette.of(context);
    final user = store.user;

    if (user == null) {
      return const AuthScreen();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 내 이름 (상자 없이)
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: palette.raised,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  user.name.isNotEmpty ? user.name.substring(0, 1) : 'R',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: palette.ink,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: palette.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      // 서버에 붙지 못했을 때만 알려 준다
                      store.isOfflineFallback
                          ? store.strings.stOffline(user.email)
                          : user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: palette.subtle),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // 화면 테마 · 고대비 접근성(#14) · 다국어 설정
          _SectionLabel(store.strings.stSectionScreen),
          ReloSwitchRow(
            title: store.strings.stDark,
            value: store.isDarkMode,
            onChanged: (_) => store.toggleDarkMode(),
          ),
          ReloSwitchRow(
            title: store.strings.stContrast,
            subtitle: store.strings.stContrastSub,
            value: store.isHighContrast,
            onChanged: (_) => store.toggleHighContrast(),
          ),
          ReloSwitchRow(
            title: store.strings.stHelper,
            subtitle: store.strings.stHelperSub,
            value: store.showAssistantButton,
            onChanged: store.setAssistantButtonVisible,
          ),
          // 마감 알림: 켤 때만 기기에 알림 허용을 묻는다. 기기가 막으면 꺼진 채로 두고 까닭을 말한다.
          ReloSwitchRow(
            title: store.strings.stReminders,
            subtitle: store.reminders.isSupported
                ? store.strings.stRemindersSub
                : store.strings.stRemindersUnavailable,
            value: store.deadlineRemindersOn,
            onChanged: (on) async {
              final messenger = ScaffoldMessenger.of(context);
              final s = store.strings;
              if (!store.reminders.isSupported) {
                messenger.showSnackBar(
                  SnackBar(content: Text(s.stRemindersUnavailable)),
                );
                return;
              }
              final ok = await store.setDeadlineReminders(on);
              if (on) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(ok ? s.rmTurnedOn : s.stRemindersDenied),
                  ),
                );
              }
            },
          ),
          ReloHairline(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.strings.stLanguage,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: palette.ink,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final loc in ReloLocale.values)
                      ReloChoiceChip(
                        label: loc.nativeName,
                        selected: store.locale == loc,
                        onTap: () => store.setLocale(loc),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // 개인정보 보호 · AI 도우미 동의 · 알림 메일 끄기(#18) · 즉시 삭제(#20)
          _SectionLabel(store.strings.stSectionMe),
          ReloSwitchRow(
            title: store.strings.stAi,
            subtitle: store.strings.stAiSub,
            value: user.aiConsentAt != null,
            onChanged: (_) => store.toggleAiConsent(),
          ),
          // 스스로 시작하기: 처음에는 꺼져 있다. 서버의 AI가 있을 때만 보이고,
          // 켤 때는 무엇이 Google로 가는지 알리고 AI 동의부터 받는다. AI 동의를 끄면 함께 꺼진다.
          if (!store.isOfflineFallback && store.config.aiEnabled)
            ReloSwitchRow(
              title: store.strings.stAgentAuto,
              subtitle: store.strings.stAgentAutoSub,
              value: store.agentAutoOn,
              onChanged: (on) => _setAgentAuto(context, store, on),
            ),
          // 알림 메일: 스스로 시작한 AI가 허락을 기다리는데 한동안 답이 없을 때 서버가 보내는 한 통.
          // 스스로 시작하기를 켠 사람에게만 가는 메일이라 켰을 때만 보인다. 서버가 받아야 바뀐다.
          if (!store.isOfflineFallback &&
              store.config.aiEnabled &&
              store.agentAutoOn)
            ReloSwitchRow(
              title: store.strings.stEmail,
              // 인증하지 않은 주소로는 보내지 않는다: 보낸다고 약속하지 않고 그렇다고 말한다
              subtitle: !store.noticeMailOn
                  ? store.strings.stEmailOff
                  : user.emailVerifiedAt == null
                      ? store.strings.stEmailUnverified
                      : store.strings.stEmailOn,
              value: store.noticeMailOn,
              onChanged: (on) => _setNoticeMail(context, store, on),
            ),
          _LinkRow(
            title: store.strings.stBackupTitle,
            onTap: () => _showJsonExportDialog(context, store),
          ),
          _LinkRow(
            title: store.strings.stLegal,
            onTap: () => store.openLegalDocument('checklist'),
          ),
          _LinkRow(title: store.strings.stLogout, onTap: store.logout),
          _LinkRow(
            title: store.strings.stDelete,
            danger: true,
            onTap: () => store.openLegalDocument('delete'),
          ),

          const BusinessFooter(),
        ],
      ),
    );
  }
}

/// 구역 이름표 ("화면" · "내 정보"). 홈의 "지금 할 일"과 같은 글자다.
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final palette = ReloPalette.of(context);
    return Semantics(
      header: true,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: palette.subtle,
        ),
      ),
    );
  }
}

/// 눌러서 들어가는 줄: 이름 + 오른쪽 화살표. 지우는 일([danger])은 빨간 글자로만 알린다.
class _LinkRow extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final bool danger;

  const _LinkRow({
    required this.title,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ReloPalette.of(context);
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: ReloHairline(
          vertical: 17,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: danger ? palette.danger : palette.ink,
                  ),
                ),
              ),
              if (!danger)
                Icon(ReloIcons.chevronRight,
                    size: 22, color: palette.subtle),
            ],
          ),
        ),
      ),
    );
  }
}
