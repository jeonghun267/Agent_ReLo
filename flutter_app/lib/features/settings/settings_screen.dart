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
/// @purpose 계정, 화면(테마·고대비·언어), 알림, 백업, 약관·정책 열기, 탈퇴
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
                  label: store.isOfflineFallback ? '오프라인 데모' : '서버 연결됨',
                  tone: ReloBadgeTone.neutral,
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
                  '화면',
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
                            '어두운 화면',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: palette.ink,
                            ),
                          ),
                          Text(
                            '끄면 밝은 화면으로 바뀌어요',
                            style:
                                TextStyle(fontSize: 11, color: palette.muted),
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
                            '고대비 모드',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: palette.ink,
                            ),
                          ),
                          Text(
                            '글자와 배경 차이를 더 크게 하고, 키보드 포커스를 노란색으로 표시해요.',
                            style:
                                TextStyle(fontSize: 11, color: palette.muted),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: store.isHighContrast,
                      activeThumbColor: palette.brand,
                      onChanged: (_) => store.toggleHighContrast(),
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
                            '도우미 캐릭터 띄우기',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: palette.ink,
                            ),
                          ),
                          Text(
                            '화면 위에 떠 있는 ReLo 도우미예요. 꺼도 환불 상세에서 "이 건 물어보기"로 열 수 있어요.',
                            style:
                                TextStyle(fontSize: 11, color: palette.muted),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: store.showAssistantButton,
                      activeThumbColor: palette.brand,
                      onChanged: store.setAssistantButtonVisible,
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
                  '내 정보',
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
                            'AI 영수증 인식 · 외국어 번역 도우미',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: palette.ink,
                            ),
                          ),
                          Text(
                            '끄면 영수증과 사유를 AI 서버로 보내지 않아요.',
                            style:
                                TextStyle(fontSize: 11, color: palette.muted),
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
                            '이메일 알림 받기',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: palette.ink,
                            ),
                          ),
                          Text(
                            store.emailUnsubscribed
                                ? '지금은 메일을 보내지 않아요'
                                : '끄면 바로 수신 거부돼요',
                            style:
                                TextStyle(fontSize: 11, color: palette.muted),
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
                  text: '내 환불 기록 백업 (JSON)',
                  isPrimary: false,
                  height: 46,
                  icon: Icons.download_rounded,
                  onPressed: () => _showJsonExportDialog(context, store),
                ),
                const SizedBox(height: 10),
                ReloButton(
                  text: '약관 · 개인정보 처리방침 · 정책',
                  isPrimary: false,
                  height: 46,
                  icon: Icons.gavel_rounded,
                  onPressed: () => store.openLegalDocument('checklist'),
                ),
                const SizedBox(height: 10),
                ReloButton(
                  text: '회원 탈퇴 · 내 정보 모두 삭제',
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
