import 'package:flutter/material.dart';
import '../../core/config/sdk_registry.dart';
import '../../core/theme/relo_theme.dart';
import '../../shared/models/domain_models.dart';
import '../../shared/state/relo_store.dart';
import '../../shared/widgets/relo_primitives.dart';
import 'business_footer.dart';
import 'compliance_data.dart';

/// @module features/compliance/legal_center_screen
/// @layer Feature Module — 20-Point Legal & Compliance Protection Center
/// @purpose 약관·정책 문서와 개인정보 보호 항목 20개를
///          한눈에 검증하고 조작할 수 있는 통합 법적 보호 센터입니다.
class LegalCenterScreen extends StatefulWidget {
  const LegalCenterScreen({super.key});

  @override
  State<LegalCenterScreen> createState() => _LegalCenterScreenState();
}

class _LegalCenterScreenState extends State<LegalCenterScreen> {
  final _deletePassCtrl = TextEditingController();
  bool _confirmImmediateDelete = false;
  bool _deleting = false;

  static const List<({String id, String label})> _tabs = [
    (id: 'checklist', label: '보호 항목'),
    (id: 'privacy', label: '1. 개인정보 처리방침'),
    (id: 'terms', label: '2. 이용약관·사업자정보'),
    (id: 'refund', label: '3. 환불·투명요금 정책'),
    (id: 'cookie', label: '4. 쿠키정책·동의관리'),
    (id: 'sdk', label: '5. 외부 SDK·수신거부'),
    (id: 'licenses', label: '6. 글꼴·이미지 이용권'),
    (id: 'delete', label: '7. 개인정보 즉시 파기'),
  ];

  @override
  void dispose() {
    _deletePassCtrl.dispose();
    super.dispose();
  }

  Future<void> _executeImmediatePurge(ReloStore store) async {
    setState(() => _deleting = true);
    final msg = await store.deleteAccountAndPurgeAllData(
      _deletePassCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _deleting = false;
      _confirmImmediateDelete = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = ReloScope.of(context);
    final palette = ReloPalette.of(context);
    final activeId = store.activeLegalDocId;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 상단 요약 배너
          ReloCard(
            backgroundColor: palette.brandSoft.withValues(alpha: 0.7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const ReloBadge(
                      label: '모두 적용됨',
                      tone: ReloBadgeTone.mint,
                      icon: Icons.verified_user_rounded,
                    ),
                    GestureDetector(
                      onTap: store.toggleHighContrast,
                      child: ReloBadge(
                        label: store.isHighContrast ? '고대비 켜짐' : '고대비 켜기',
                        tone: store.isHighContrast
                            ? ReloBadgeTone.sunny
                            : ReloBadgeTone.brand,
                        icon: Icons.contrast_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '약관과 개인정보 보호',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: palette.ink,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '개인정보 처리방침, 이용약관, 환불 정책, 쿠키 설정과 내 정보 삭제 요청을 한곳에서 봅니다. 개인정보보호법·전자상거래법·표시광고법·장애인차별금지법·저작권법 기준 20개 항목을 적용했습니다.',
                  style: TextStyle(
                    fontSize: 12,
                    color: palette.body,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 가로 스크롤 문서 탭
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _tabs.map((tab) {
                final selected = activeId == tab.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => store.openLegalDocument(tab.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? palette.brand : palette.surface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: selected ? palette.brand : palette.line,
                        ),
                      ),
                      child: Text(
                        tab.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: selected ? Colors.white : palette.body,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          if (activeId == 'checklist')
            _buildTwentyPointChecklist(store, palette),
          if (activeId == 'privacy')
            _buildPolicyDocumentCard(
              title: '1. 개인정보 처리방침 (최소 수집 · 아동 보호 · 즉시 파기)',
              badgeText: '개인정보보호법 제30조 준수',
              body: ReloComplianceData.privacyPolicyFullText,
              palette: palette,
            ),
          if (activeId == 'terms')
            _buildPolicyDocumentCard(
              title: '2. 서비스 이용약관 및 법적 한계 고지',
              badgeText: '약관규제법 · 변호사법 준수',
              body: ReloComplianceData.termsOfServiceFullText,
              palette: palette,
            ),
          if (activeId == 'refund')
            _buildPolicyDocumentCard(
              title: '3. 환불정책 및 숨겨진 요금 제로(0원) 선언',
              badgeText: '전자상거래법 제17조 준수',
              body: ReloComplianceData.refundPolicyFullText,
              palette: palette,
            ),
          if (activeId == 'cookie') _buildCookieControlPanel(store, palette),
          if (activeId == 'sdk')
            _buildExternalSdkAndUnsubscribePanel(store, palette),
          if (activeId == 'licenses') _buildFontAndAssetLicensesPanel(palette),
          if (activeId == 'delete')
            _buildImmediateDataPurgePanel(store, palette),

          const BusinessFooter(),
        ],
      ),
    );
  }

  Widget _buildTwentyPointChecklist(ReloStore store, ReloPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: ReloComplianceData.twentyPointChecklist.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: ReloCard(
            padding: const EdgeInsets.all(14),
            onTap: item.actionTabId == 'checklist'
                ? null
                : () => store.openLegalDocument(item.actionTabId),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: palette.mintSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${item.number}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: palette.mint,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                              color: palette.ink,
                            ),
                          ),
                          ReloBadge(
                            label: item.lawReference,
                            tone: ReloBadgeTone.brand,
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.implementationSummary,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: palette.body,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPolicyDocumentCard({
    required String title,
    required String badgeText,
    required String body,
    required ReloPalette palette,
  }) {
    return ReloCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReloBadge(label: badgeText, tone: ReloBadgeTone.brand),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: palette.ink,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: palette.sunken,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: palette.line),
            ),
            child: SelectableText(
              body.trim(),
              style: TextStyle(
                fontSize: 12,
                color: palette.body,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCookieControlPanel(ReloStore store, ReloPalette palette) {
    return ReloCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ReloBadge(
            label: '쿠키 설정',
            tone: ReloBadgeTone.brand,
          ),
          const SizedBox(height: 8),
          Text(
            '쿠키 운영 정책 및 동의 상태 변경',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: palette.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '현재 선택된 쿠키 설정: ${switch (store.cookieConsent) {
              CookieConsentChoice.pending => '아직 선택 전 (하단 배너 표시 중)',
              CookieConsentChoice.essentialOnly => '필수 보안 쿠키만 허용 (선택 쿠키 거절됨)',
              CookieConsentChoice.allAccepted => '전체 쿠키 동의 완료',
            }}',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: palette.mint,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ReloButton(
                  text: '필수만 허용 (거절)',
                  isPrimary: false,
                  height: 44,
                  onPressed: () => store.setCookieConsent(
                    CookieConsentChoice.essentialOnly,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ReloButton(
                  text: '전체 쿠키 동의',
                  height: 44,
                  onPressed: () => store.setCookieConsent(
                    CookieConsentChoice.allAccepted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ReloButton(
            text: '하단 쿠키 동의 배너 다시 띄우기 (테스트용)',
            isPrimary: false,
            height: 42,
            onPressed: () => store.setCookieConsent(
              CookieConsentChoice.pending,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: palette.sunken,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: palette.line),
            ),
            child: SelectableText(
              ReloComplianceData.cookiePolicyFullText.trim(),
              style: TextStyle(
                fontSize: 12,
                color: palette.body,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExternalSdkAndUnsubscribePanel(
    ReloStore store,
    ReloPalette palette,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // [항목 #18] 이메일 원클릭 수신거부 카드
        ReloCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ReloBadge(
                label: '이메일 수신 거부',
                tone: ReloBadgeTone.sunny,
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
                          '원클릭 이메일 알림 · 안내 메일 수신거부',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: palette.ink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          store.emailUnsubscribed
                              ? '현재 상태: 수신거부 완료 (마케팅·안내 이메일이 발송되지 않습니다)'
                              : '현재 상태: 이메일 수신 허용 중 (언제든 스위치 하나로 즉시 거부 가능)',
                          style: TextStyle(
                            fontSize: 12,
                            color: store.emailUnsubscribed
                                ? palette.sunny
                                : palette.mint,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: !store.emailUnsubscribed,
                    activeThumbColor: palette.brand,
                    onChanged: (receive) =>
                        store.setEmailUnsubscribed(!receive),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: palette.sunken,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: palette.line),
                ),
                child: Text(
                  '[발송 이메일 하단 필수 표기 문구 미리보기]\n'
                  '본 메일은 정보통신망법 제50조에 의거하여 발송되었습니다. 메일 수신을 원치 않으시면 [수신거부(Unsubscribe)]를 클릭해 주세요. (If you no longer wish to receive these emails, click Unsubscribe.)',
                  style: TextStyle(
                    fontSize: 11,
                    color: palette.muted,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // [항목 #8] 외부 SDK 점검 및 패키지 버전 충돌 방지 매트릭스
        ReloCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ReloBadge(
                label: '외부 서비스 연결',
                tone: ReloBadgeTone.brand,
              ),
              const SizedBox(height: 8),
              Text(
                '탑재 SDK · 패키지 버전 호환성 및 데이터 전송 제어',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: palette.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Flutter ${ReloSdkRegistry.flutterFrameworkVersion} / Dart ${ReloSdkRegistry.dartSdkVersion} 기준 모든 서브 패키지 버전을 dependency_overrides로 고정하여 구형/신형 충돌을 원천 차단했습니다.',
                style: TextStyle(fontSize: 11.5, color: palette.body),
              ),
              const SizedBox(height: 12),
              ...ReloSdkRegistry.auditedSdks.map((sdk) {
                final isEnabled = sdk.id == 'gemini_ai_bridge'
                    ? store.sdkAiEnabled
                    : (sdk.id == 'resend_mail_bridge'
                        ? store.sdkMailEnabled
                        : true);
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: palette.sunken,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: palette.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${sdk.name} (${sdk.pinnedVersion})',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w900,
                                color: palette.ink,
                              ),
                            ),
                          ),
                          if (sdk.canUserDisable)
                            Switch(
                              value: isEnabled,
                              activeThumbColor: palette.brand,
                              onChanged: (_) => store.toggleExternalSdk(sdk.id),
                            )
                          else
                            const ReloBadge(
                              label: '로컬 필수 SDK',
                              tone: ReloBadgeTone.mint,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '용도: ${sdk.purpose}\n데이터 전송 범위: ${sdk.dataShared}\n라이선스: ${sdk.license}',
                        style: TextStyle(
                          fontSize: 11,
                          color: palette.muted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
              Text(
                '차단된 제3자 광고·추적 SDK 목록 (0개 탑재 보증)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: palette.mint,
                ),
              ),
              const SizedBox(height: 6),
              ...ReloSdkRegistry.blockedTrackerSdks.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.block_rounded,
                        size: 14,
                        color: palette.mint,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: palette.body,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFontAndAssetLicensesPanel(ReloPalette palette) {
    return ReloCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ReloBadge(
            label: '글꼴·이미지 라이선스',
            tone: ReloBadgeTone.mint,
          ),
          const SizedBox(height: 8),
          Text(
            '글꼴(Font) · 아이콘 · 그래픽 상업적 라이선스 검증서',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: palette.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '폰트 저작권 합의금 내용증명이나 무단 이미지 도용 분쟁을 원천 차단하기 위해, 상업적 무료 이용 및 임베딩이 검증된 오픈소스 글꼴과 100% 자체 제작 코드 그래픽만 사용합니다.',
            style: TextStyle(
              fontSize: 12,
              color: palette.body,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          ...ReloComplianceData.verifiedAssetLicenses.map(
            (lic) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: palette.sunken,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: palette.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        lic.assetName,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          color: palette.ink,
                        ),
                      ),
                      ReloBadge(
                        label: lic.licenseType,
                        tone: ReloBadgeTone.mint,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '분류: ${lic.category} | 권리자: ${lic.copyrightHolder}\n검증 결과: ${lic.commercialRightNote}',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: palette.body,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImmediateDataPurgePanel(ReloStore store, ReloPalette palette) {
    return ReloCard(
      borderColor: palette.danger.withValues(alpha: 0.6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ReloBadge(
            label: '내 정보 삭제 요청',
            tone: ReloBadgeTone.danger,
          ),
          const SizedBox(height: 8),
          Text(
            '개인정보 및 증빙 파일 즉시 영구 파기 요청 (Right to be Forgotten)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: palette.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '고객센터에 별도로 전화하거나 이메일을 보낼 필요 없이, 지금 바로 아래 버튼 하나로 내 계정, 환불 클레임 내역, 영수증·파손 사진 원본을 데이터베이스에서 즉시 영구 삭제할 수 있습니다.',
            style: TextStyle(
              fontSize: 12,
              color: palette.body,
              height: 1.45,
            ),
          ),
          if (store.lastPurgeReceiptCode != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: palette.mintSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '✓ 최근 개인정보 영구 파기 완료 증명 번호: ${store.lastPurgeReceiptCode}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: palette.mint,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          ReloTextField(
            label: '본인 확인 비밀번호 (체험 계정일 경우 비워두셔도 즉시 실행됩니다)',
            controller: _deletePassCtrl,
            obscureText: true,
            hint: '현재 비밀번호 입력',
          ),
          const SizedBox(height: 10),
          ReloConsentCheckbox(
            value: _confirmImmediateDelete,
            onChanged: (v) => setState(() => _confirmImmediateDelete = v),
            isRequired: true,
            title: '내 계정과 모든 환불 내역·사진을 복구 불가능하게 즉시 파기하는 것에 동의합니다.',
          ),
          const SizedBox(height: 10),
          ReloButton(
            text: _deleting ? '영구 파기 실행 중...' : '내 모든 개인정보 · 영수증 사진 즉시 영구 삭제하기',
            isDanger: true,
            icon: Icons.delete_forever_rounded,
            onPressed: (!_confirmImmediateDelete || _deleting)
                ? null
                : () => _executeImmediatePurge(store),
          ),
        ],
      ),
    );
  }
}
