import 'package:flutter/material.dart';
import '../../core/config/sdk_registry.dart';
import '../../core/i18n/relo_i18n.dart';
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
  /// 지금 언어의 문구
  ReloStrings get _s => ReloScope.of(context).strings;

  final _deletePassCtrl = TextEditingController();
  bool _confirmImmediateDelete = false;
  bool _deleting = false;

  List<({String id, String label})> get _tabs => [
    (id: 'checklist', label: _s.lgTabChecklist),
    (id: 'privacy', label: _s.lgTabPrivacy),
    (id: 'terms', label: _s.lgTabTerms),
    (id: 'refund', label: _s.lgTabRefund),
    (id: 'cookie', label: _s.lgTabCookie),
    (id: 'sdk', label: _s.lgTabSdk),
    (id: 'licenses', label: _s.lgTabLicenses),
    (id: 'delete', label: _s.lgTabDelete),
  ];

  static const List<String> _tabIds = [
    'checklist',
    'privacy',
    'terms',
    'refund',
    'cookie',
    'sdk',
    'licenses',
    'delete',
  ];

  final Map<String, GlobalKey> _tabKeys = {
    for (final id in _tabIds) id: GlobalKey(),
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
                  tooltip: _s.lgBack,
                  icon: Icon(ReloIcons.back, color: palette.ink),
                  onPressed: () => store.navigateToTab(4),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _s.lgTitle,
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
              _s.lgIntro,
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
                  title: _s.lgPrivacyTitle,
                  lawNote: _s.lgPrivacyLaw,
                  body: ReloComplianceData.privacyPolicyFullText,
                  palette: palette,
                ),
              'terms' => _buildPolicyDocument(
                  title: _s.lgTermsTitle,
                  lawNote: _s.lgTermsLaw,
                  body: ReloComplianceData.termsOfServiceFullText,
                  palette: palette,
                ),
              'refund' => _buildPolicyDocument(
                  title: _s.lgRefundTitle,
                  lawNote: _s.lgRefundLaw,
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

  /// 문서 본문과 보호 항목은 한국어 원문 그대로 보여 준다.
  /// 다른 언어로 볼 때는 그렇다는 것을 한 줄로 알린다 (한국어에서는 아무것도 나오지 않는다).
  List<Widget> _koreanOnly(ReloPalette palette) {
    final note = _s.lgKoreanOnly;
    if (note.isEmpty) return const [];
    return [const SizedBox(height: 8), _note(note, palette)];
  }

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
          _s.lgChecklistIntro,
          palette,
        ),
        ..._koreanOnly(palette),
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
        ..._koreanOnly(palette),
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
        _heading(_s.lgCookieTitle, palette),
        const SizedBox(height: 6),
        Text(
          _s.lgCookieCurrent(switch (store.cookieConsent) {
            CookieConsentChoice.pending => _s.lgCookiePending,
            CookieConsentChoice.essentialOnly => _s.lgCookieEssential,
            CookieConsentChoice.allAccepted => _s.lgCookieAll,
          }),
          style: TextStyle(fontSize: 14, color: palette.muted, height: 1.45),
        ),
        const SizedBox(height: 16),
        // [항목 #9] 거절과 동의를 같은 크기로 나란히 둔다
        Row(
          children: [
            Expanded(
              child: ReloButton(
                text: _s.lgCookieDecline,
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
                text: _s.lgCookieAccept,
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
            label: _s.lgCookieReset,
            onTap: () => store.setCookieConsent(CookieConsentChoice.pending),
          ),
        ),
        ..._koreanOnly(palette),
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
        // [항목 #18] 보내는 메일과 알림 메일 끄기. 스위치는 서버의 값이다: 서버에 붙어 있고
        // 알림 메일이 갈 수 있을 때(스스로 시작하기를 켰을 때)만 보인다.
        _heading(_s.lgUnsubTitle, palette),
        if (store.user != null &&
            !store.isOfflineFallback &&
            store.config.aiEnabled &&
            store.agentAutoOn)
          ReloSwitchRow(
            title: _s.stEmail,
            subtitle: !store.noticeMailOn
                ? _s.stEmailOff
                : store.user?.emailVerifiedAt == null
                    ? _s.stEmailUnverified
                    : _s.stEmailOn,
            value: store.noticeMailOn,
            onChanged: (on) async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                await store.setNoticeMail(on);
              } catch (_) {
                messenger.showSnackBar(SnackBar(content: Text(_s.stEmailFail)));
              }
            },
          ),
        const SizedBox(height: 12),
        _note(_s.lgMailFacts, palette),
        const SizedBox(height: 32),

        // [항목 #8] 외부 SDK 점검 및 패키지 버전 충돌 방지 매트릭스
        _heading(_s.lgSdkTitle, palette),
        const SizedBox(height: 6),
        _paragraph(
          _s.lgSdkPinned(
            ReloSdkRegistry.flutterFrameworkVersion,
            ReloSdkRegistry.dartSdkVersion,
          ),
          palette,
        ),
        const SizedBox(height: 4),
        for (final sdk in ReloSdkRegistry.auditedSdks)
          if (sdk.canUserDisable)
            ReloSwitchRow(
              title: '${sdk.name} (${sdk.pinnedVersion})',
              subtitle:
                  _s.lgSdkDetail(sdk.purpose, sdk.dataShared, sdk.license),
              value: switch (sdk.id) {
                'gemini_ai_bridge' => store.sdkAiEnabled,
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
                          _s.lgSdkDetail(sdk.purpose, sdk.dataShared, sdk.license),
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
                    _s.lgLocalRequired,
                    style: TextStyle(fontSize: 13, color: palette.subtle),
                  ),
                ],
              ),
            ),
        const SizedBox(height: 24),
        Text(
          _s.lgBlockedTitle,
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
        _heading(_s.lgLicenseTitle, palette),
        const SizedBox(height: 6),
        _paragraph(
          _s.lgLicenseIntro,
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
                  _s.lgLicenseDetail(
                    lic.category,
                    lic.copyrightHolder,
                    lic.commercialRightNote,
                  ),
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
        _heading(_s.lgPurgeTitle, palette),
        const SizedBox(height: 6),
        Text(
          _s.lgPurgeIntro,
          style: TextStyle(fontSize: 14, color: palette.muted, height: 1.5),
        ),
        if (store.lastPurgeReceiptCode != null) ...[
          const SizedBox(height: 12),
          Text(
            _s.lgPurgeReceipt(store.lastPurgeReceiptCode!),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: palette.body,
            ),
          ),
        ],
        const SizedBox(height: 20),
        ReloTextField(
          label: _s.lgPurgePassword,
          controller: _deletePassCtrl,
          obscureText: true,
          hint: _s.lgPurgePasswordHint,
          fillColor: palette.raised,
        ),
        const SizedBox(height: 6),
        ReloConsentRow(
          value: _confirmImmediateDelete,
          onChanged: (v) => setState(() => _confirmImmediateDelete = v),
          isRequired: true,
          title: _s.lgPurgeConsent,
        ),
        const SizedBox(height: 10),
        // 되돌릴 수 없는 일이라 이 버튼만 빨갛게 둔다
        ReloButton(
          text: _deleting ? _s.lgPurging : _s.lgPurgeButton,
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
