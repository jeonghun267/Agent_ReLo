import 'package:flutter/material.dart';
import '../../core/theme/relo_theme.dart';
import '../../shared/models/domain_models.dart';
import '../../shared/state/relo_store.dart';

/// @module features/compliance/cookie_consent_banner
/// @layer Feature Module — Fair-Choice Cookie Consent Banner
/// @purpose [법적 안전장치 #4 쿠키정책, #5 쿠키동의 배너, #9 원하지 않는 선택 유도 금지(다크패턴 방지)]
///          [필수 쿠키만 허용(선택 거절)] 버튼과 [전체 쿠키 동의] 버튼의 크기·높이·가독성을
///          1:1 동등하게 배치하여 공정거래위원회 다크패턴 방지 가이드라인을 완벽히 준수합니다.
class CookieConsentBanner extends StatelessWidget {
  const CookieConsentBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ReloScope.of(context);
    if (store.cookieConsent != CookieConsentChoice.pending) {
      return const SizedBox.shrink();
    }

    final palette = ReloPalette.of(context);

    return Semantics(
      container: true,
      label: '쿠키 및 개인정보 보호 설정 안내 배너',
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.surfaceElevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.brandLine, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cookie_outlined,
                  size: 16,
                  color: palette.brandHover,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '투명한 쿠키 운영 안내 (제3자 광고 추적 쿠키 0개)',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      color: palette.ink,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => store.openLegalDocument('cookie'),
                  child: Text(
                    '쿠키정책 전문',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: palette.brandHover,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'ReLo는 안전한 로그인 유지를 위한 필수 보안 쿠키(relo_session)와 화면 테마·언어 기억을 위한 선택 쿠키를 구분합니다. 선택 쿠키를 거절하셔도 모든 환불 신청 기능을 똑같이 이용하실 수 있어요.',
              style: TextStyle(
                fontSize: 11,
                color: palette.body,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            // [항목 #9 다크패턴 방지] 거절 버튼과 동의 버튼의 크기·높이를 1:1 동일하게 제공
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: palette.ink,
                        backgroundColor: palette.sunken,
                        side: BorderSide(color: palette.line, width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => store.setCookieConsent(
                        CookieConsentChoice.essentialOnly,
                      ),
                      child: const Text(
                        '필수만 허용 (거절)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.brand,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => store.setCookieConsent(
                        CookieConsentChoice.allAccepted,
                      ),
                      child: const Text(
                        '전체 쿠키 동의',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
