import 'package:flutter/material.dart';
import '../../core/config/sdk_registry.dart';
import '../../core/theme/relo_theme.dart';
import '../../shared/models/domain_models.dart';
import '../../shared/state/relo_store.dart';
import '../../shared/widgets/relo_primitives.dart';
import 'business_footer.dart';
import 'compliance_data.dart';
import '../../shared/widgets/relo_icons.dart';

/// @module features/compliance/legal_center_screen
/// @layer Feature Module — 20-Point Legal & Compliance Protection Center
/// @purpose 약관·정책 문서와 개인정보 보호 항목 20개를
///          한눈에 검증하고 조작할 수 있는 통합 법적 보호 센터입니다.
///          화면 구성은 DESIGN.md 7절 "약관·정책": 뒤로 + 제목 → 옆으로 미는 글자 탭 →
///          상자 없이 바탕 위에 놓은 문서와 줄 → 맨 아래 사업자 정보. 문서 내용은 그대로 둔다.
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
    (id: 'privacy', label: '개인정보 처리방침'),
    (id: 'terms', label: '이용약관'),
    (id: 'refund', label: '환불·요금'),
    (id: 'cookie', label: '쿠키'),
    (id: 'sdk', label: '외부 서비스·수신거부'),
    (id: 'licenses', label: '글꼴·이미지'),
    (id: 'delete', label: '내 정보 삭제'),
  ];

  final Map<String, GlobalKey> _tabKeys = {
    for (final tab in _tabs) tab.id: GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    // 문서를 바꾸면 화면이 새로 그려지므로, 고른 탭이 탭 줄 안에 보이도록 옆으로 옮겨 둔다
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final id = ReloScope.of(context).activeLegalDocId;
      final tabContext = _tabKeys[id]?.currentContext;
      final box = tabContext?.findRenderObject();
      if (tabContext == null || box == null) return;
      Scrollable.of(tabContext).position.ensureVisible(box, alignment: 0.5);
    });
  }

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
      padding: const EdgeInsets.only(bottom: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 뒤로 + 제목
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
            child: Row(
              children: [
                IconButton(
                  tooltip: '설정으로',
                  icon: Icon(ReloIcons.back, color: palette.ink),
                  onPressed: () => store.navigateToTab(4),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '약관과 개인정보 보호',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: palette.ink,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
            child: Text(
              '처리방침, 이용약관, 환불 정책, 쿠키 설정, 내 정보 삭제를 한곳에서 봐요.',
              style: TextStyle(fontSize: 14, color: palette.muted, height: 1.45),
            ),
          ),
          const SizedBox(height: 14),

          // 옆으로 미는 글자 탭 (고른 칸은 굵은 글자와 밑줄)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 20, right: 2),
            child: Row(
              children: [
                for (final tab in _tabs)
                  ReloTextTab(
                    key: _tabKeys[tab.id],
                    label: tab.label,
                    selected: activeId == tab.id,
                    onTap: () => store.openLegalDocument(tab.id),
                  ),
              ],
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            color: palette.line.withValues(alpha: 0.5),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: switch (activeId) {
              'privacy' => _buildPolicyDocument(
                  title: '개인정보 처리방침 (최소 수집 · 아동 보호 · 즉시 파기)',
                  lawNote: '개인정보보호법 제30조 준수',
                  body: ReloComplianceData.privacyPolicyFullText,
                  palette: palette,
                ),
              'terms' => _buildPolicyDocument(
                  title: '서비스 이용약관 및 법적 한계 고지',
                  lawNote: '약관규제법 · 변호사법 준수',
                  body: ReloComplianceData.termsOfServiceFullText,
                  palette: palette,
                ),
              'refund' => _buildPolicyDocument(
                  title: '환불정책 및 숨겨진 요금 제로(0원) 선언',
                  lawNote: '전자상거래법 제17조 준수',
                  body: ReloComplianceData.refundPolicyFullText,
                  palette: palette,
                ),
              'cookie' => _buildCookieControlPanel(store, palette),
              'sdk' => _buildExternalSdkAndUnsubscribePanel(store, palette),
              'licenses' => _buildFontAndAssetLicensesPanel(palette),
              'delete' => _buildImmediateDataPurgePanel(store, palette),
              _ => _buildTwentyPointChecklist(store, palette),
            },
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: BusinessFooter(),
          ),
        ],
      ),
    );
  }

  /// 문서·구역의 제목 (화면의 큰 글자는 맨 위 제목 하나이므로 한 단계 작게)
  Widget _heading(String text, ReloPalette palette) => Text(
        text,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: palette.ink,
          height: 1.35,
          letterSpacing: -0.2,
        ),
      );

  /// 근거 법령 · 분류 같은 한 줄 (배지로 만들지 않고 회색 글자로)
  Widget _note(String text, ReloPalette palette) => Text(
        text,
        style: TextStyle(fontSize: 12, color: palette.subtle, height: 1.4),
      );

  Widget _paragraph(String text, ReloPalette palette) => Text(
        text,
        style: TextStyle(fontSize: 13, color: palette.muted, height: 1.5),
      );

  // ── 보호 항목 20개 ───────────────────────────────────────────────────
  Widget _buildTwentyPointChecklist(ReloStore store, ReloPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _paragraph(
          '개인정보보호법·전자상거래법·표시광고법·장애인차별금지법·저작권법 기준 20개 항목을 적용했습니다.',
          palette,
        ),
        const SizedBox(height: 6),
        for (final item in ReloComplianceData.twentyPointChecklist)
          InkWell(
            onTap: item.actionTabId == 'checklist'
                ? null
                : () => store.openLegalDocument(item.actionTabId),
            child: ReloHairline(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 30,
                    child: Text(
                      '${item.number}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: palette.subtle,
                        height: 1.4,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: palette.ink,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 2),
                        _note(item.lawReference, palette),
                        const SizedBox(height: 6),
                        _paragraph(item.implementationSummary, palette),
                      ],
                    ),
                  ),
                  if (item.actionTabId != 'checklist')
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(ReloIcons.chevronRight,
                          size: 20, color: palette.subtle),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ── 문서 (처리방침 · 이용약관 · 환불 정책) ───────────────────────────
  Widget _buildPolicyDocument({
    required String title,
    required String lawNote,
    required String body,
    required ReloPalette palette,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(title, palette),
        const SizedBox(height: 4),
        _note(lawNote, palette),
        const SizedBox(height: 16),
        SelectableText(
          body.trim(),
          style: TextStyle(fontSize: 13, color: palette.body, height: 1.7),
        ),
      ],
    );
  }

  // ── 쿠키 ─────────────────────────────────────────────────────────────
  Widget _buildCookieControlPanel(ReloStore store, ReloPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading('쿠키 운영 정책 및 동의 상태 변경', palette),
        const SizedBox(height: 6),
        Text(
          '현재 선택된 쿠키 설정: ${switch (store.cookieConsent) {
            CookieConsentChoice.pending => '아직 선택 전',
            CookieConsentChoice.essentialOnly => '필수 보안 쿠키만 허용 (선택 쿠키 거절됨)',
            CookieConsentChoice.allAccepted => '전체 쿠키 동의 완료',
          }}',
          style: TextStyle(fontSize: 14, color: palette.muted, height: 1.45),
        ),
        const SizedBox(height: 16),
        // [항목 #9] 거절과 동의를 같은 크기로 나란히 둔다
        Row(
          children: [
            Expanded(
              child: ReloButton(
                text: '필수만 허용 (거절)',
                isPrimary: false,
                height: 48,
                onPressed: () => store.setCookieConsent(
                  CookieConsentChoice.essentialOnly,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ReloButton(
                text: '전체 쿠키 동의',
                height: 48,
                onPressed: () => store.setCookieConsent(
                  CookieConsentChoice.allAccepted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: ReloTextAction(
            label: '아직 고르지 않은 상태로 되돌리기',
            onTap: () => store.setCookieConsent(CookieConsentChoice.pending),
          ),
        ),
        const SizedBox(height: 12),
        SelectableText(
          ReloComplianceData.cookiePolicyFullText.trim(),
          style: TextStyle(fontSize: 13, color: palette.body, height: 1.7),
        ),
      ],
    );
  }

  // ── 외부 서비스 · 수신거부 ───────────────────────────────────────────
  Widget _buildExternalSdkAndUnsubscribePanel(
    ReloStore store,
    ReloPalette palette,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // [항목 #18] 이메일 원클릭 수신거부
        _heading('원클릭 이메일 알림 · 안내 메일 수신거부', palette),
        ReloSwitchRow(
          title: '이메일 받기',
          subtitle: store.emailUnsubscribed
              ? '현재 상태: 수신거부 완료 (마케팅·안내 이메일이 발송되지 않습니다)'
              : '현재 상태: 이메일 수신 허용 중 (언제든 스위치 하나로 즉시 거부 가능)',
          value: !store.emailUnsubscribed,
          onChanged: (receive) => store.setEmailUnsubscribed(!receive),
        ),
        const SizedBox(height: 12),
        _note(
          '[발송 이메일 하단 필수 표기 문구 미리보기]\n'
          '본 메일은 정보통신망법 제50조에 의거하여 발송되었습니다. 메일 수신을 원치 않으시면 [수신거부(Unsubscribe)]를 클릭해 주세요. (If you no longer wish to receive these emails, click Unsubscribe.)',
          palette,
        ),
        const SizedBox(height: 32),

        // [항목 #8] 외부 SDK 점검 및 패키지 버전 충돌 방지 매트릭스
        _heading('탑재 SDK · 패키지 버전 호환성 및 데이터 전송 제어', palette),
        const SizedBox(height: 6),
        _paragraph(
          'Flutter ${ReloSdkRegistry.flutterFrameworkVersion} / Dart ${ReloSdkRegistry.dartSdkVersion} 기준 모든 서브 패키지 버전을 dependency_overrides로 고정하여 구형/신형 충돌을 원천 차단했습니다.',
          palette,
        ),
        const SizedBox(height: 4),
        for (final sdk in ReloSdkRegistry.auditedSdks)
          if (sdk.canUserDisable)
            ReloSwitchRow(
              title: '${sdk.name} (${sdk.pinnedVersion})',
              subtitle:
                  '용도: ${sdk.purpose}\n데이터 전송 범위: ${sdk.dataShared}\n라이선스: ${sdk.license}',
              value: switch (sdk.id) {
                'gemini_ai_bridge' => store.sdkAiEnabled,
                'resend_mail_bridge' => store.sdkMailEnabled,
                _ => true,
              },
              onChanged: (_) => store.toggleExternalSdk(sdk.id),
            )
          else
            ReloHairline(
              vertical: 12,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${sdk.name} (${sdk.pinnedVersion})',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: palette.ink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '용도: ${sdk.purpose}\n데이터 전송 범위: ${sdk.dataShared}\n라이선스: ${sdk.license}',
                          style: TextStyle(
                            fontSize: 13,
                            color: palette.subtle,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '로컬 필수',
                    style: TextStyle(fontSize: 13, color: palette.subtle),
                  ),
                ],
              ),
            ),
        const SizedBox(height: 24),
        Text(
          '차단된 제3자 광고·추적 SDK 목록 (0개 탑재 보증)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: palette.subtle,
          ),
        ),
        const SizedBox(height: 10),
        for (final item in ReloSdkRegistry.blockedTrackerSdks)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child:
                      Icon(ReloIcons.block, size: 14, color: palette.subtle),
                ),
                const SizedBox(width: 8),
                Expanded(child: _paragraph(item, palette)),
              ],
            ),
          ),
      ],
    );
  }

  // ── 글꼴 · 이미지 라이선스 ───────────────────────────────────────────
  Widget _buildFontAndAssetLicensesPanel(ReloPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading('글꼴(Font) · 아이콘 · 그래픽 상업적 라이선스 검증서', palette),
        const SizedBox(height: 6),
        _paragraph(
          '폰트 저작권 합의금 내용증명이나 무단 이미지 도용 분쟁을 원천 차단하기 위해, 상업적 무료 이용 및 임베딩이 검증된 오픈소스 글꼴과 100% 자체 제작 코드 그래픽만 사용합니다.',
          palette,
        ),
        const SizedBox(height: 4),
        for (final lic in ReloComplianceData.verifiedAssetLicenses)
          ReloHairline(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lic.assetName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: palette.ink,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 2),
                _note(lic.licenseType, palette),
                const SizedBox(height: 6),
                _paragraph(
                  '분류: ${lic.category} | 권리자: ${lic.copyrightHolder}\n검증 결과: ${lic.commercialRightNote}',
                  palette,
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── 내 정보 삭제 ─────────────────────────────────────────────────────
  Widget _buildImmediateDataPurgePanel(ReloStore store, ReloPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading('개인정보 및 증빙 파일 즉시 영구 파기 요청 (Right to be Forgotten)', palette),
        const SizedBox(height: 6),
        Text(
          '고객센터에 별도로 전화하거나 이메일을 보낼 필요 없이, 지금 바로 아래 버튼 하나로 내 계정, 환불 클레임 내역, 영수증·파손 사진 원본을 데이터베이스에서 즉시 영구 삭제할 수 있습니다.',
          style: TextStyle(fontSize: 14, color: palette.muted, height: 1.5),
        ),
        if (store.lastPurgeReceiptCode != null) ...[
          const SizedBox(height: 12),
          Text(
            '✓ 최근 개인정보 영구 파기 완료 증명 번호: ${store.lastPurgeReceiptCode}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: palette.body,
            ),
          ),
        ],
        const SizedBox(height: 20),
        ReloTextField(
          label: '본인 확인 비밀번호 (체험 계정이면 비워 두어도 바로 실행돼요)',
          controller: _deletePassCtrl,
          obscureText: true,
          hint: '현재 비밀번호 입력',
          fillColor: palette.raised,
        ),
        const SizedBox(height: 6),
        ReloConsentRow(
          value: _confirmImmediateDelete,
          onChanged: (v) => setState(() => _confirmImmediateDelete = v),
          isRequired: true,
          title: '내 계정과 모든 환불 내역·사진을 복구 불가능하게 즉시 파기하는 것에 동의합니다.',
        ),
        const SizedBox(height: 10),
        // 되돌릴 수 없는 일이라 이 버튼만 빨갛게 둔다
        ReloButton(
          text: _deleting ? '영구 파기 실행 중…' : '내 정보와 사진 모두 영구 삭제하기',
          isDanger: true,
          icon: ReloIcons.trash,
          onPressed: (!_confirmImmediateDelete || _deleting)
              ? null
              : () => _executeImmediatePurge(store),
        ),
      ],
    );
  }
}
