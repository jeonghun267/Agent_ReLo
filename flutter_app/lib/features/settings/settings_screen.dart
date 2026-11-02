import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/i18n/relo_i18n.dart';
import '../../core/theme/relo_theme.dart';
import '../../shared/state/relo_store.dart';
import '../../shared/widgets/relo_primitives.dart';
import '../auth/auth_screen.dart';
import '../compliance/business_footer.dart';

/// @module features/settings/settings_screen
/// @layer Feature Module — Account, Accessibility, Email Unsubscribe & Immediate Purge
/// @purpose [법적 안전장치 #8 외부 SDK 제어, #14 고대비 접근성, #18 이메일 수신거부, #20 개인정보 삭제요청]
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
          '내 환불 데이터 JSON 백업',
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
                fontSize: 11,
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
                const SnackBar(
                  content: Text('전체 환불 데이터(JSON)가 클립보드에 복사되었어요!'),
                ),
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
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ReloCard(
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: palette.brandSoft,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: palette.brandLine),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    user.name.isNotEmpty ? user.name.substring(0, 1) : 'R',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: palette.brandHover,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${user.name}님의 환불 보관함',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: palette.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 12,
                          color: palette.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                ReloBadge(
                  label: store.isOfflineFallback ? '로컬 보안 모드' : '서버 동기화됨',
                  tone: store.isOfflineFallback
                      ? ReloBadgeTone.sunny
                      : ReloBadgeTone.mint,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 화면 테마 · 고대비 접근성(#14) · 다국어 설정
          ReloCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '화면 스타일 · 고대비 접근성 · 다국어',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: palette.ink,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '미드나잇 다크 블루 테마',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: palette.ink,
                            ),
                          ),
                          Text(
                            '승인된 실배포 다크 에디토리얼 모드 / 라이트 모드 전환',
                            style: TextStyle(fontSize: 11, color: palette.muted),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: store.isDarkMode,
                      activeThumbColor: palette.brand,
                      onChanged: (_) => store.toggleDarkMode(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '시각 약자용 WCAG AAA 초고대비 모드 (항목 #14)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: palette.ink,
                            ),
                          ),
                          Text(
                            '글자와 배경 명도 대비를 15:1 이상으로 강화하고 노란 포커스 링을 표시합니다.',
                            style: TextStyle(fontSize: 11, color: palette.muted),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: store.isHighContrast,
                      activeThumbColor: palette.sunny,
                      onChanged: (_) => store.toggleHighContrast(),
                    ),
                  ],
                ),
                Divider(color: palette.line, height: 24),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ReloLocale.values.map((loc) {
                    final active = store.locale == loc;
                    return GestureDetector(
                      onTap: () => store.setLocale(loc),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: active ? palette.brand : palette.sunken,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${loc.shortLabel} · ${loc.nativeName}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: active ? Colors.white : palette.body,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 개인정보 보호 · AI 도우미 동의 · 이메일 수신거부(#18) · 즉시 삭제(#20)
          ReloCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '개인정보 권리 행사 및 수신거부 · 즉시 파기',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: palette.ink,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI 영수증 인식 · 외국어 번역 도우미 동의 (항목 #8)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: palette.ink,
                            ),
                          ),
                          Text(
                            '언제든 끄실 수 있으며, 끄면 외부 AI 서버로 텍스트가 전송되지 않습니다.',
                            style: TextStyle(fontSize: 11, color: palette.muted),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: user.aiConsentAt != null,
                      activeThumbColor: palette.brand,
                      onChanged: (_) => store.toggleAiConsent(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '이메일 알림 원클릭 수신 허용 (항목 #18)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: palette.ink,
                            ),
                          ),
                          Text(
                            store.emailUnsubscribed
                                ? '현재 수신거부됨 (광고·안내 메일이 발송되지 않습니다)'
                                : '현재 수신 허용 중 (스위치를 끄면 즉시 수신거부 처리됩니다)',
                            style: TextStyle(fontSize: 11, color: palette.muted),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: !store.emailUnsubscribed,
                      activeThumbColor: palette.brand,
                      onChanged: (v) => store.setEmailUnsubscribed(!v),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ReloButton(
                  text: '내 환불 기록 전체 백업 (JSON 내보내기)',
                  isPrimary: false,
                  height: 46,
                  icon: Icons.download_rounded,
                  onPressed: () => _showJsonExportDialog(context, store),
                ),
                const SizedBox(height: 10),
                ReloButton(
                  text: '법적보호 20선 · 외부 SDK 점검 · 약관 열람',
                  isPrimary: false,
                  height: 46,
                  icon: Icons.gavel_rounded,
                  onPressed: () => store.openLegalDocument('checklist'),
                ),
                const SizedBox(height: 10),
                ReloButton(
                  text: '회원 탈퇴 및 개인정보 즉시 영구 삭제 (항목 #20)',
                  isDanger: true,
                  height: 46,
                  icon: Icons.delete_forever_rounded,
                  onPressed: () => store.openLegalDocument('delete'),
                ),
                const SizedBox(height: 10),
                ReloButton(
                  text: '로그아웃',
                  isPrimary: false,
                  height: 44,
                  icon: Icons.logout_rounded,
                  onPressed: store.logout,
                ),
              ],
            ),
          ),

          const BusinessFooter(),
        ],
      ),
    );
  }
}
