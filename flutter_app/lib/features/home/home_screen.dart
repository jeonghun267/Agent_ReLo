import 'package:flutter/material.dart';
import '../../core/theme/relo_theme.dart';
import '../../shared/state/relo_store.dart';
import '../../shared/widgets/relo_orb_emblem.dart';
import '../../shared/widgets/relo_primitives.dart';
import '../compliance/business_footer.dart';

/// @module features/home/home_screen
/// @layer Feature Module — Main Home Screen (Approved Design + Legal Transparency)
/// @purpose 사용자가 승인한 실배포 미드나잇 블루 + 3D 오브 디자인을 1:1 구현하며,
///          [항목 #10 숨겨진 요금 0원], [항목 #11 가짜후기 배제], [항목 #12 근거없는 주장 배제],
///          [항목 #16 사업자 정보 푸터]를 함께 제공합니다.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _activeStoryIndex = 0;

  static const List<({String name, String currency, String desc, String issue})>
  _frequentMalls = [
    (
      name: 'Amazon US',
      currency: 'USD',
      desc: 'USD · 영문 채팅 초안',
      issue: '택배 개봉 시 외관 파손 및 전원 작동 불량이 확인되었습니다.',
    ),
    (
      name: 'AliExpress',
      currency: 'USD',
      desc: 'USD · 분쟁 증빙 패키지',
      issue: '주문한 옵션과 전혀 다른 모델이 오배송되었습니다.',
    ),
    (
      name: 'Taobao · 1688',
      currency: 'CNY',
      desc: 'CNY · 중국어 환불 요청',
      issue: '구성품 일부가 누락되어 도착했습니다.',
    ),
    (
      name: 'Mercari · JP',
      currency: 'JPY',
      desc: 'JPY · 일본어 정중 문의',
      issue: '상품 설명에 없던 심각한 스크래치와 작동 오류가 있습니다.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final store = ReloScope.of(context);
    final palette = ReloPalette.of(context);
    final s = store.strings;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. 승인된 3D 블루 글로우 오브 엠블럼 (Semantics 대체 텍스트 포함)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 6, bottom: 18),
              child: ReloOrbEmblem(size: 88),
            ),
          ),

          // 2. 에디토리얼 히어로 타이틀
          Text(
            s.heroTitleLine1,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              color: palette.ink,
              height: 1.32,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            s.heroTitleLine2,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              color: palette.isDark ? const Color(0xFF3B82F6) : palette.brand,
              height: 1.32,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            s.heroSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: palette.muted,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 22),

          // 3. 승인된 2단 메인 CTA 버튼
          ReloButton(
            text: s.ctaPrimary,
            onPressed: () => store.navigateToTab(1),
          ),
          const SizedBox(height: 10),
          ReloButton(
            text: s.ctaSecondary,
            isPrimary: false,
            onPressed: () => store.navigateToTab(2),
          ),

          // 4. 승인된 3단 핵심 신뢰 지표 (과장 없는 검증된 스펙만 표기 — 항목 #11, #12 준수)
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              border: Border.symmetric(
                horizontal: BorderSide(color: palette.line),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTrustMetric(
                    title: s.metric1Title,
                    sub: s.metric1Sub,
                    palette: palette,
                  ),
                ),
                Container(width: 1, height: 32, color: palette.line),
                Expanded(
                  child: _buildTrustMetric(
                    title: s.metric2Title,
                    sub: s.metric2Sub,
                    palette: palette,
                  ),
                ),
                Container(width: 1, height: 32, color: palette.line),
                Expanded(
                  child: _buildTrustMetric(
                    title: s.metric3Title,
                    sub: s.metric3Sub,
                    palette: palette,
                  ),
                ),
              ],
            ),
          ),

          // [항목 #10 숨겨진 요금 없애기 & #11 가짜후기 없애기 & #12 근거없는 주장 없애기]
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: palette.brandSoft.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.brandLine),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.verified_outlined,
                  size: 18,
                  color: palette.brandHover,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '숨겨진 요금 0원 · 가짜 별점 후기 0건 · 사실 기반 안내',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: palette.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '신청 수수료·환불 성공보수·자동 유료전환이 일절 없으며, 허위 후기나 "무조건 100% 환불 보장" 같은 과장 광고를 하지 않습니다.',
                        style: TextStyle(
                          fontSize: 11,
                          color: palette.body,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 5. 자주 찾는 직구 쇼핑몰 즉시 환불 2x2 그리드
          const SizedBox(height: 22),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                s.frequentMallsHeader,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  color: palette.ink,
                ),
              ),
              Text(
                s.tapToStart,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: palette.isDark
                      ? const Color(0xFF3B82F6)
                      : palette.brand,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Column(
            children: [
              for (int row = 0; row < _frequentMalls.length; row += 2) ...[
                if (row > 0) const SizedBox(height: 10),
                Row(
                  children: [
                    for (int col = 0; col < 2; col++) ...[
                      if (col > 0) const SizedBox(width: 10),
                      if (row + col < _frequentMalls.length)
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              final mall = _frequentMalls[row + col];
                              return ReloCard(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                semanticLabel:
                                    '${mall.name} (${mall.desc}) 환불 신청 바로 시작',
                                onTap: () => store.launchWizardWithPreset(
                                  vendor: mall.name,
                                  currency: mall.currency,
                                  kind: 'refund',
                                  issue: mall.issue,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      mall.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w900,
                                        color: palette.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      mall.desc,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: palette.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ],
                ),
              ],
            ],
          ),

          // 6. 3단계 환불 과정 인터랙티브 프리뷰
          const SizedBox(height: 24),
          ReloCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '해외직구 환불 3단계 핵심 원리',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: palette.ink,
                      ),
                    ),
                    const ReloBadge(
                      label: '탭하여 미리보기',
                      tone: ReloBadgeTone.brand,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildStoryStepTab(0, '1. 영수증·마스킹', palette),
                    const SizedBox(width: 6),
                    _buildStoryStepTab(1, '2. 외국어 요청서', palette),
                    const SizedBox(width: 6),
                    _buildStoryStepTab(2, '3. 실제 입금대조', palette),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: palette.sunken,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: palette.line),
                  ),
                  child: Text(
                    switch (_activeStoryIndex) {
                      0 =>
                        '주문 영수증을 올리면 쇼핑몰·주문번호·결제금액을 자동 추출하고, 집 주소와 전화번호는 안전하게 가려(Masking) 불필요한 개인정보 유출을 막습니다.',
                      1 =>
                        '한국어로 적은 파손 사유를 Amazon·AliExpress·Mercari 상담원이 즉시 이해하는 정중하고 명확한 외국어 환불 요청서로 변환합니다.',
                      _ =>
                        '판매자의 "환불해 줄게요" 말만 믿고 놓치지 않도록, 내 카드사 해외승인 취소 또는 통장 입금이 실제로 완료될 때까지 차액을 추적합니다.',
                    },
                    style: TextStyle(
                      fontSize: 12,
                      color: palette.body,
                      height: 1.48,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // [항목 #16] 사업자 정보 및 6대 법적 정책 푸터
          const BusinessFooter(),
        ],
      ),
    );
  }

  Widget _buildTrustMetric({
    required String title,
    required String sub,
    required ReloPalette palette,
  }) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: palette.ink,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          sub,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: palette.muted,
          ),
        ),
      ],
    );
  }

  Widget _buildStoryStepTab(int index, String label, ReloPalette palette) {
    final active = _activeStoryIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeStoryIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? palette.brand : palette.sunken,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: active ? Colors.white : palette.body,
            ),
          ),
        ),
      ),
    );
  }
}
