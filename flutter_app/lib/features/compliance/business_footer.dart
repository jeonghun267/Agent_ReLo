import 'package:flutter/material.dart';
import '../../core/theme/relo_theme.dart';
import '../../shared/state/relo_store.dart';
import 'compliance_data.dart';

/// @module features/compliance/business_footer
/// @layer Feature Module — Legal Business Registration & Policy Links Footer
/// @purpose [법적 안전장치 #1~#4, #16 사업자 정보 추가, #18 이메일 수신거부, #19 라이선스, #20 삭제요청]
///          홈 화면 및 주요 페이지 하단에 전자상거래법 제10조 필수 사업자 정보와
///          6대 법적 정책 바로가기 버튼을 상시 노출합니다.
///          내용은 그대로 두고, 상자와 칩 없이 회색 글자로만 둔다 (DESIGN.md 7절 "설정").
class BusinessFooter extends StatelessWidget {
  const BusinessFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ReloScope.of(context);
    final palette = ReloPalette.of(context);
    final info = ReloComplianceData.businessInfo;

    return Semantics(
      container: true,
      label: store.strings.ftSemantics,
      child: Padding(
        padding: const EdgeInsets.only(top: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 법적 정책 바로가기 (개인정보 처리방침만 굵게)
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                _PolicyLink(
                  label: store.strings.lgTabPrivacy,
                  isBold: true,
                  onTap: () => store.openLegalDocument('privacy'),
                ),
                _PolicyLink(
                  label: store.strings.ftTerms,
                  onTap: () => store.openLegalDocument('terms'),
                ),
                _PolicyLink(
                  label: store.strings.ftRefund,
                  onTap: () => store.openLegalDocument('refund'),
                ),
                _PolicyLink(
                  label: store.strings.ftCookie,
                  onTap: () => store.openLegalDocument('cookie'),
                ),
                _PolicyLink(
                  label: store.strings.ftSdk,
                  onTap: () => store.openLegalDocument('sdk'),
                ),
                _PolicyLink(
                  label: store.strings.ftLicense,
                  onTap: () => store.openLegalDocument('licenses'),
                ),
                _PolicyLink(
                  label: store.strings.ftDelete,
                  onTap: () => store.openLegalDocument('delete'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              info['companyName']!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: palette.muted,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '대표자: ${info['ceoName']} | 사업자등록번호: ${info['bizRegNo']}\n'
              '통신판매업신고번호: ${info['ecommerceRegNo']}\n'
              '사업장 주소: ${info['address']}\n'
              '개인정보보호책임자(CPO): ${info['cpoName']}\n'
              '고객센터: ${info['supportPhone']} | 이메일: ${info['supportEmail']}\n'
              '호스팅 제공자: ${info['hostingProvider']}',
              style: TextStyle(
                fontSize: 12,
                color: palette.subtle,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              store.strings.ftNotice,
              style: TextStyle(
                fontSize: 12,
                color: palette.subtle,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 정책 바로가기 한 개. 칩으로 만들지 않고 글자로만 둔다.
class _PolicyLink extends StatelessWidget {
  final String label;
  final bool isBold;
  final VoidCallback onTap;

  const _PolicyLink({
    required this.label,
    this.isBold = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ReloPalette.of(context);
    return Semantics(
      link: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: isBold ? palette.ink : palette.muted,
            ),
          ),
        ),
      ),
    );
  }
}
