import 'package:flutter/material.dart';
import '../../core/theme/relo_theme.dart';
import '../../shared/state/relo_store.dart';
import 'compliance_data.dart';

/// @module features/compliance/business_footer
/// @layer Feature Module — Legal Business Registration & Policy Links Footer
/// @purpose [법적 안전장치 #1~#4, #16 사업자 정보 추가, #18 이메일 수신거부, #19 라이선스, #20 삭제요청]
///          홈 화면 및 주요 페이지 하단에 전자상거래법 제10조 필수 사업자 정보와
///          6대 법적 정책 바로가기 버튼을 상시 노출합니다.
class BusinessFooter extends StatelessWidget {
  const BusinessFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ReloScope.of(context);
    final palette = ReloPalette.of(context);
    final info = ReloComplianceData.businessInfo;

    return Semantics(
      container: true,
      label: '사업자 등록 정보 및 법적 정책 안내 푸터',
      child: Container(
        margin: const EdgeInsets.only(top: 24),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: palette.sunken,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: palette.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 법적 정책 퀵 링크 바
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _PolicyLinkChip(
                  label: '개인정보 처리방침',
                  isBold: true,
                  onTap: () => store.openLegalDocument('privacy'),
                ),
                _PolicyLinkChip(
                  label: '서비스 이용약관',
                  onTap: () => store.openLegalDocument('terms'),
                ),
                _PolicyLinkChip(
                  label: '환불·요금 정책',
                  onTap: () => store.openLegalDocument('refund'),
                ),
                _PolicyLinkChip(
                  label: '쿠키 운영 정책',
                  onTap: () => store.openLegalDocument('cookie'),
                ),
                _PolicyLinkChip(
                  label: '외부 SDK 점검·수신거부',
                  onTap: () => store.openLegalDocument('sdk'),
                ),
                _PolicyLinkChip(
                  label: '글꼴·이미지 라이선스',
                  onTap: () => store.openLegalDocument('licenses'),
                ),
                _PolicyLinkChip(
                  label: '개인정보 즉시 삭제요청',
                  onTap: () => store.openLegalDocument('delete'),
                ),
              ],
            ),
            Divider(color: palette.line, height: 24),
            Text(
              info['companyName']!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: palette.ink,
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
                fontSize: 11,
                color: palette.muted,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: palette.line),
              ),
              child: Text(
                '※ 법적 고지 (근거없는 주장 배제): ReLo는 해외직구 반품·교환·환불 증빙 정리, 8개국 통화 계산, 외국어 문의 초안 작성 및 실제 카드 취소 입금 확인 기록을 돕는 B2C 소프트웨어 도구이며, 법률 소송 대리인이 아닙니다.',
                style: TextStyle(
                  fontSize: 10.5,
                  color: palette.body,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicyLinkChip extends StatelessWidget {
  final String label;
  final bool isBold;
  final VoidCallback onTap;

  const _PolicyLinkChip({
    required this.label,
    this.isBold = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ReloPalette.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isBold ? palette.brandSoft : palette.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isBold ? palette.brandLine : palette.line,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
            color: isBold
                ? (palette.isDark ? const Color(0xFF93C5FD) : palette.brand)
                : palette.body,
          ),
        ),
      ),
    );
  }
}
