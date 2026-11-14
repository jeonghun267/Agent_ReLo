import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/i18n/relo_i18n.dart';
import '../../core/theme/relo_theme.dart';
import '../../shared/state/relo_store.dart';
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
          '내 환불 기록 백업',
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
                const SnackBar(content: Text('백업 내용을 복사했어요.')),
              );
            },
            child: const Text('복사하기'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
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
                          ? '${user.email} · 오프라인 데모'
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
          const _SectionLabel('화면'),
          ReloSwitchRow(
            title: '어두운 화면',
            value: store.isDarkMode,
            onChanged: (_) => store.toggleDarkMode(),
          ),
          ReloSwitchRow(
            title: '고대비 모드',
            subtitle: '글자와 배경의 차이를 더 크게 하고, 키보드 포커스를 노란색으로 표시해요',
            value: store.isHighContrast,
            onChanged: (_) => store.toggleHighContrast(),
          ),
          ReloSwitchRow(
            title: '도우미 캐릭터 띄우기',
            subtitle: '설정과 약관 화면에 떠 있는 말랑이예요. 꺼도 홈과 내 환불에서 물어볼 수 있어요',
            value: store.showAssistantButton,
            onChanged: store.setAssistantButtonVisible,
          ),
          ReloHairline(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '언어',
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

          // 개인정보 보호 · AI 도우미 동의 · 이메일 수신거부(#18) · 즉시 삭제(#20)
          const _SectionLabel('내 정보'),
          ReloSwitchRow(
            title: 'AI 기능 쓰기',
            subtitle: '영수증 읽기와 번역에 써요. 끄면 영수증과 사유를 AI 서버로 보내지 않아요',
            value: user.aiConsentAt != null,
            onChanged: (_) => store.toggleAiConsent(),
          ),
          ReloSwitchRow(
            title: '이메일 알림 받기',
            subtitle:
                store.emailUnsubscribed ? '지금은 메일을 보내지 않아요' : '끄면 바로 수신 거부돼요',
            value: !store.emailUnsubscribed,
            onChanged: (v) => store.setEmailUnsubscribed(!v),
          ),
          _LinkRow(
            title: '내 환불 기록 백업',
            onTap: () => _showJsonExportDialog(context, store),
          ),
          _LinkRow(
            title: '약관 · 개인정보 처리방침 · 정책',
            onTap: () => store.openLegalDocument('checklist'),
          ),
          _LinkRow(title: '로그아웃', onTap: store.logout),
          _LinkRow(
            title: '회원 탈퇴 · 내 정보 모두 삭제',
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
