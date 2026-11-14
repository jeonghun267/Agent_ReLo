import 'dart:convert';
import 'package:animations/animations.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import '../../core/theme/motion_tokens.dart';
import '../../core/theme/relo_theme.dart';
import '../../core/utils/money_format.dart';
import '../../shared/models/domain_models.dart';
import '../../shared/state/relo_store.dart';
import '../../shared/widgets/claim_row.dart';
import '../../shared/widgets/refund_globe.dart';
import '../../shared/widgets/relo_primitives.dart';
import '../../shared/widgets/relo_icons.dart';

/// @module features/wizard/wizard_screen
/// @layer Feature Module — 5-Step Claim Wizard with Explicit Consent & Data Minimization
/// @purpose [법적 안전장치 #6 양식 동의항목 확인, #7 불필요한 개인정보 미수집, #9 다크패턴 방지, #10 숨겨진 요금 0원]
///          Step 1~5 간편 신청 과정과 함께 영수증 집 주소 마스킹 및 제출 전 명시적 동의 확인을 제공합니다.
///          화면 구성은 DESIGN.md 7절 "신청": 머리말 한 줄(뒤로 · 진행 막대 · 1 / 5) → 질문 하나 →
///          상자 없이 바탕 위에 놓은 입력칸과 고르는 칩 → 아래 고정 주 버튼 하나.
class WizardScreen extends StatefulWidget {
  const WizardScreen({super.key});

  @override
  State<WizardScreen> createState() => _WizardScreenState();
}

class _WizardScreenState extends State<WizardScreen> {
  int _step = 1;
  final _scroll = ScrollController();

  /// 단계 전환 방향. 다음이면 오른쪽에서, 이전이면 왼쪽에서 들어온다
  bool _stepReverse = false;
  late final ConfettiController _confetti =
      ConfettiController(duration: ReloMotion.celebrate);
  bool _isScanning = false;
  bool _isTranslating = false;
  bool _isSubmitting = false;
  ClaimView? _createdClaim;
  String? _formError;

  // [항목 #6 & #9] 5단계 양식 제출 시 필수/선택 동의 상태 (기본 미체크 원칙)
  bool _consentClaimStorageRequired = false;
  bool _consentNoFalseClaimRequired = false;
  bool _consentAiDraftOptional = false;

  final _vendorCtrl = TextEditingController(text: 'Amazon US');
  final _orderRefCtrl = TextEditingController(text: '114-8920411-33012');
  final _orderedOnCtrl = TextEditingController(
    text: DateTime.now().toIso8601String().substring(0, 10),
  );
  final _titleCtrl = TextEditingController(
    text: 'Sony WH-1000XM5 무선 노이즈캔슬링 헤드폰',
  );
  final _orderedQtyCtrl = TextEditingController(text: '1');
  final _claimQtyCtrl = TextEditingController(text: '1');
  String _currency = 'USD';
  final _amountCtrl = TextEditingController(text: '289.00');
  String _kind = 'refund';
  final _issueCtrl = TextEditingController(
    text:
        '배송받아서 전원을 켰는데 오른쪽 유닛에서 심한 노이즈가 발생하고 블루투스 연결이 계속 끊어집니다. 교환 또는 전액 환불 원합니다.',
  );
  final _issueEnCtrl = TextEditingController(
    text:
        'Upon unboxing and powering on the device, there is severe static noise in the right earpiece and Bluetooth continuously disconnects. I request an immediate replacement or full refund.',
  );

  final List<StagedEvidenceFile> _stagedFiles = [
    StagedEvidenceFile(
      id: 'stg_default_01',
      name: 'Amazon_Order_Receipt_Masked.pdf',
      mime: 'application/pdf',
      bytes: ReloStore.ensureValidFileSignature(
        'application/pdf',
        utf8.encode('RELO_MASKED_RECEIPT_PDF_CONTENT'),
      ),
      addressMasked: true,
    ),
    StagedEvidenceFile(
      id: 'stg_default_02',
      name: '우측_하우징_파손_부위_확대.jpg',
      mime: 'image/jpeg',
      bytes: ReloStore.ensureValidFileSignature(
        'image/jpeg',
        utf8.encode('RELO_DAMAGE_PHOTO_JPEG_CONTENT'),
      ),
      addressMasked: true,
      defectTag: '파손 부위 표시됨',
    ),
  ];

  // 한 화면에 질문 하나. 말투는 DESIGN.md 6절("어디서 샀어요?")
  static const List<String> _stepTitles = [
    '어디서 샀어요?',
    '어떤 상품이에요?',
    '어떻게 해결할까요?',
    '영수증이나 사진이 있어요?',
    '마지막으로 확인해요',
  ];

  // label은 칩에 짧게 보이는 이름, name은 저장되는 쇼핑몰 이름
  static const List<({String label, String name, String currency})>
      _quickMalls = [
    (label: 'Amazon US', name: 'Amazon US', currency: 'USD'),
    (label: 'AliExpress', name: 'AliExpress', currency: 'USD'),
    (label: 'Taobao', name: 'Taobao · Tmall', currency: 'CNY'),
    (label: 'Mercari', name: 'Mercari · Amazon JP', currency: 'JPY'),
    (label: 'iHerb', name: 'iHerb', currency: 'USD'),
    (label: 'Farfetch', name: 'Farfetch · SSENSE', currency: 'EUR'),
  ];

  /// "직접 입력"을 눌렀을 때만 쇼핑몰 이름 칸을 보여 준다
  bool _customVendor = false;

  // label은 칩에 보이는 짧은 말, text는 설명 칸에 채워지는 문장
  static const List<({String label, String text})> _quickIssues = [
    (label: '깨져서 왔어요', text: '택배 상자를 열었을 때 겉상자와 상품 외관이 깨진 상태로 도착했습니다.'),
    (label: '다른 물건이 왔어요', text: '주문한 옵션과 다른 색상·모델의 상품이 잘못 배송되었습니다.'),
    (label: '작동이 안 돼요', text: '전원을 연결해도 켜지지 않는 작동 불량 상품입니다.'),
    (label: '물건이 안 왔어요', text: '배송 완료로 표시되었지만 실제로 택배를 받지 못했습니다.'),
  ];

  static const List<({String id, String label})> _kinds = [
    (id: 'refund', label: '전액 환불'),
    (id: 'exchange', label: '새 상품 교환'),
    (id: 'repair', label: '부분 환불 · 수리'),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = ReloScope.of(context);
    // 쇼핑몰 없이 문제만 미리 채워 여는 경우도 있다 (홈 처음 화면의 "무슨 일이 있었어요?")
    final hasPreset = store.wizardPresetVendor != null ||
        store.wizardPresetCurrency != null ||
        store.wizardPresetKind != null ||
        store.wizardPresetIssue != null;
    if (hasPreset) {
      if (store.wizardPresetVendor != null) {
        _vendorCtrl.text = store.wizardPresetVendor!;
      }
      if (store.wizardPresetCurrency != null) {
        _currency = store.wizardPresetCurrency!;
      }
      if (store.wizardPresetKind != null) {
        _kind = store.wizardPresetKind!;
      }
      if (store.wizardPresetIssue != null) {
        _issueCtrl.text = store.wizardPresetIssue!;
      }
      store.clearWizardPresets();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _confetti.dispose();
    _vendorCtrl.dispose();
    _orderRefCtrl.dispose();
    _orderedOnCtrl.dispose();
    _titleCtrl.dispose();
    _orderedQtyCtrl.dispose();
    _claimQtyCtrl.dispose();
    _amountCtrl.dispose();
    _issueCtrl.dispose();
    _issueEnCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickOrderedOn() async {
    final now = DateTime.now();
    final current = DateTime.tryParse(_orderedOnCtrl.text) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: current.isAfter(now) ? now : current,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
    );
    if (picked == null || !mounted) return;
    setState(
        () => _orderedOnCtrl.text = picked.toIso8601String().substring(0, 10));
  }

  // 영수증으로 채우기. 사진·파일 올리기가 아직 없어서 지금은 데모용 샘플 영수증만 고른다.
  Future<void> _openSampleReceipts(ReloPalette p) async {
    const samples = [
      (label: 'Amazon US 영수증', file: 'Amazon_Order_Receipt.pdf'),
      (label: 'AliExpress 주문서', file: 'AliExpress_Order_Slip.jpg'),
      (label: 'Mercari JP 영수증', file: 'Mercari_JP_Receipt.jpg'),
    ];
    final file = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: p.canvas,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Text(
                  '샘플 영수증으로 해 보기',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800, color: p.ink),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  '사진·파일 올리기는 아직 준비 중이에요.',
                  style: TextStyle(fontSize: 13, color: p.muted),
                ),
              ),
              for (final s in samples)
                ListTile(
                  leading:
                      Icon(ReloIcons.receipt, color: p.muted),
                  title: Text(
                    s.label,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: p.ink),
                  ),
                  onTap: () => Navigator.pop(context, s.file),
                ),
            ],
          ),
        ),
      ),
    );
    if (file != null) await _handleScanSampleReceipt(file);
  }

  Future<void> _handleScanSampleReceipt(String sampleFileName) async {
    final store = ReloScope.of(context);
    setState(() {
      _isScanning = true;
      _formError = null;
    });
    final extracted = await store.scanReceiptDocument(
      fileName: sampleFileName,
      bytes: utf8.encode('SAMPLE_RECEIPT_$sampleFileName'),
    );
    if (!mounted) return;
    setState(() {
      _isScanning = false;
      if (extracted['vendor'] != null) {
        _vendorCtrl.text = extracted['vendor'].toString();
      }
      if (extracted['orderRef'] != null) {
        _orderRefCtrl.text = extracted['orderRef'].toString();
      }
      if (extracted['orderedOn'] != null) {
        _orderedOnCtrl.text = extracted['orderedOn'].toString();
      }
      if (extracted['currency'] != null) {
        _currency = extracted['currency'].toString();
      }
      if (extracted['title'] != null) {
        _titleCtrl.text = extracted['title'].toString();
      }
      if (extracted['amount'] != null) {
        _amountCtrl.text = extracted['amount'].toString();
      }
      _stagedFiles.insert(
        0,
        StagedEvidenceFile(
          id: 'stg_${DateTime.now().millisecondsSinceEpoch}',
          name: sampleFileName,
          mime: sampleFileName.endsWith('.pdf')
              ? 'application/pdf'
              : 'image/jpeg',
          bytes: utf8.encode('SCANNED_RECEIPT_$sampleFileName'),
          addressMasked: true,
        ),
      );
    });
  }

  Future<void> _handleAutoTranslate() async {
    final store = ReloScope.of(context);
    final kor = _issueCtrl.text.trim();
    if (kor.length < 5) {
      setState(() => _formError = '먼저 우리말 문제 설명을 5자 이상 적어 주세요.');
      return;
    }
    setState(() {
      _isTranslating = true;
      _formError = null;
    });
    final en = await store.translateIssueToEnglish(kor);
    if (!mounted) return;
    setState(() {
      _isTranslating = false;
      _issueEnCtrl.text = en;
    });
  }

  void _goNextStep() {
    setState(() => _formError = null);
    if (_step == 1) {
      if (_vendorCtrl.text.trim().isEmpty ||
          _orderRefCtrl.text.trim().isEmpty) {
        setState(() => _formError = '쇼핑몰 이름과 주문번호를 입력해 주세요.');
        return;
      }
    } else if (_step == 2) {
      final ordQty = int.tryParse(_orderedQtyCtrl.text) ?? 1;
      final clmQty = int.tryParse(_claimQtyCtrl.text) ?? 1;
      final amt = double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;
      if (_titleCtrl.text.trim().isEmpty || amt <= 0) {
        setState(() => _formError = '상품 이름과 돌려받을 금액을 입력해 주세요.');
        return;
      }
      if (clmQty > ordQty) {
        setState(
          () => _formError = '문제가 생긴 수량은 전체 주문 수량보다 많을 수 없어요.',
        );
        return;
      }
    } else if (_step == 3) {
      if (_issueCtrl.text.trim().length < 5) {
        setState(() => _formError = '어떤 문제가 있었는지 5자 이상 적어 주세요.');
        return;
      }
    }
    setState(() {
      _stepReverse = false;
      _step = (_step + 1).clamp(1, 5);
    });
    _scrollToTop();
  }

  Future<void> _handleSubmitWizard() async {
    if (!_consentClaimStorageRequired || !_consentNoFalseClaimRequired) {
      setState(() {
        _formError = '필수 동의 두 가지를 체크해 주세요.';
      });
      return;
    }

    final store = ReloScope.of(context);
    setState(() {
      _isSubmitting = true;
      _formError = null;
    });
    final created = await store.createClaimFromWizard(
      vendor: _vendorCtrl.text.trim(),
      orderRef: _orderRefCtrl.text.trim(),
      orderedOn: _orderedOnCtrl.text.trim(),
      title: _titleCtrl.text.trim(),
      orderedQty: int.tryParse(_orderedQtyCtrl.text) ?? 1,
      claimQty: int.tryParse(_claimQtyCtrl.text) ?? 1,
      currency: _currency,
      claimedAmount: _amountCtrl.text.trim(),
      kind: _kind,
      issue: _issueCtrl.text.trim(),
      issueEnglish: _issueEnCtrl.text.trim(),
      stagedFiles: _stagedFiles,
    );
    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _createdClaim = created;
    });
    _confetti.play();
  }

  void _goBack(ReloStore store) {
    if (_step > 1) {
      setState(() {
        _formError = null;
        _stepReverse = true;
        _step -= 1;
      });
      _scrollToTop();
    } else {
      store.navigateToTab(0);
    }
  }

  void _scrollToTop() {
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final store = ReloScope.of(context);
    final p = ReloPalette.of(context);

    if (_createdClaim != null) {
      return _buildSuccess(store, p, _createdClaim!);
    }

    final title = _stepTitles[_step - 1];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 머리말은 한 줄: 뒤로 · 진행 막대 · 몇 단계째인지
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
          child: Row(
            children: [
              IconButton(
                tooltip: _step > 1 ? '이전 단계' : '홈으로',
                onPressed: () => _goBack(store),
                icon: Icon(ReloIcons.back, color: p.ink),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Semantics(
                  label: '다섯 단계 중 $_step단계',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(end: _step / 5.0),
                      duration: ReloMotion.wizardStep,
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => LinearProgressIndicator(
                        value: value,
                        minHeight: 4,
                        backgroundColor: p.raised,
                        valueColor: AlwaysStoppedAnimation<Color>(p.focusRing),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ExcludeSemantics(
                child: Text(
                  '$_step / 5',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: p.subtle,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: p.ink,
                  ),
                ),
                const SizedBox(height: 22),
                PageTransitionSwitcher(
                  duration: ReloMotion.wizardStep,
                  reverse: _stepReverse,
                  transitionBuilder: (child, primary, secondary) =>
                      SharedAxisTransition(
                    animation: primary,
                    secondaryAnimation: secondary,
                    transitionType: SharedAxisTransitionType.horizontal,
                    fillColor: Colors.transparent,
                    child: child,
                  ),
                  child: KeyedSubtree(
                    key: ValueKey<int>(_step),
                    child: _buildStep(store, p),
                  ),
                ),
              ],
            ),
          ),
        ),
        // 아래 고정: 고칠 것이 있으면 빨간 글자 한 줄, 그리고 주 버튼 하나.
        // 단계가 바뀌어도 버튼은 늘 같은 자리에 있다.
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_formError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      _formError!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: p.danger,
                      ),
                    ),
                  ),
                ),
              if (_step < 5)
                ReloButton(text: '다음', onPressed: _goNextStep)
              else
                ReloButton(
                  text: _isSubmitting ? '등록 중…' : '환불 신청 등록하기',
                  onPressed: _isSubmitting ? null : _handleSubmitWizard,
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// 신청 완료. 지구본이 앞으로 나와 그 나라에서 비행기가 출발한다 (DESIGN.md 1절).
  Widget _buildSuccess(ReloStore store, ReloPalette p, ClaimView claim) {
    final corridor = GlobeCorridor.fromClaim(claim);
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 280,
                child: RefundGlobe(
                  corridors: [corridor],
                  animate: !reduceMotion,
                  hubLabel: '서울 · 내 계좌로',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${corridor.city}에서 출발했어요',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: p.ink),
              ),
              const SizedBox(height: 6),
              Text(
                '${claim.vendor} · 주문번호 ${claim.orderRef}\n환불 신청과 증빙이 내 보관함에 저장됐어요.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: p.muted, height: 1.5),
              ),
              const SizedBox(height: 24),
              ReloButton(
                text: '판매자 메시지 보내러 가기',
                showTrailingArrow: true,
                onPressed: () => store.openClaimDetail(claim.id),
              ),
              const SizedBox(height: 8),
              ReloButton(
                text: '내 환불 보기',
                isPrimary: false,
                onPressed: () => store.navigateToTab(2),
              ),
            ],
          ),
        ),
        ConfettiWidget(
          confettiController: _confetti,
          blastDirectionality: BlastDirectionality.explosive,
          numberOfParticles: 24,
          gravity: 0.25,
          colors: [p.brand, p.brandHover, Colors.white],
        ),
      ],
    );
  }

  /// 입력칸 위에 붙는 작은 이름표 (입력칸의 이름표와 같은 글자)
  Widget _label(String text, ReloPalette p) => Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: p.muted,
        ),
      );

  /// 상자 없이 가는 선으로만 나눈 한 줄
  Widget _hairlineRow(ReloPalette p,
          {required Widget child, double vertical = 13}) =>
      DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: p.line.withValues(alpha: 0.5)),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: vertical),
          child: child,
        ),
      );

  Widget _buildStep(ReloStore store, ReloPalette p) {
    switch (_step) {
      case 1:
        return _buildWhereStep(p);
      case 2:
        return _buildItemStep(p);
      case 3:
        return _buildIssueStep(p);
      case 4:
        return _buildFilesStep(p);
      case 5:
      default:
        return _buildConfirmStep(store, p);
    }
  }

  // ── 1. 어디서 샀어요? ────────────────────────────────────────────────
  Widget _buildWhereStep(ReloPalette p) {
    final knownMall = _quickMalls.any((m) => m.name == _vendorCtrl.text);
    final showVendorField = _customVendor || !knownMall;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 영수증으로 채우기. 이 화면의 상자는 이것 하나다. 샘플 고르기는 누르면 아래에서 열린다.
        Semantics(
          button: true,
          child: Material(
            color: p.raised,
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _isScanning ? null : () => _openSampleReceipts(p),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                child: Row(
                  children: [
                    ReloIconTile(
                      icon: ReloIcons.receipt,
                      color: p.inset,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isScanning ? '영수증 읽는 중…' : '영수증으로 자동 채우기',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: p.ink,
                        ),
                      ),
                    ),
                    if (_isScanning)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else
                      Icon(ReloIcons.chevronRight,
                          size: 22, color: p.subtle),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _label('또는 직접 고르기', p),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final mall in _quickMalls)
              ReloChoiceChip(
                label: mall.label,
                selected: !_customVendor && _vendorCtrl.text == mall.name,
                onTap: () => setState(() {
                  _customVendor = false;
                  _vendorCtrl.text = mall.name;
                  _currency = mall.currency;
                }),
              ),
            ReloChoiceChip(
              label: '직접 입력',
              selected: showVendorField,
              onTap: () => setState(() {
                _customVendor = true;
                _vendorCtrl.clear();
              }),
            ),
          ],
        ),
        if (showVendorField) ...[
          const SizedBox(height: 16),
          ReloTextField(
            label: '쇼핑몰 이름',
            controller: _vendorCtrl,
            hint: '예: Coupang Global, eBay',
            fillColor: p.raised,
          ),
        ],
        const SizedBox(height: 22),
        ReloTextField(
          label: '주문번호',
          controller: _orderRefCtrl,
          hint: '예: 114-8920411-33012',
          fillColor: p.raised,
        ),
        const SizedBox(height: 14),
        ReloTextField(
          label: '주문일',
          controller: _orderedOnCtrl,
          readOnly: true,
          onTap: _pickOrderedOn,
          trailingIcon: ReloIcons.calendar,
          fillColor: p.raised,
        ),
        // [항목 #7 불필요한 개인정보 미수집 안내] 첫 단계 맨 아래 한 줄
        const SizedBox(height: 18),
        Row(
          children: [
            Icon(ReloIcons.lock, size: 14, color: p.subtle),
            const SizedBox(width: 6),
            Text(
              '주민번호·통관번호·카드번호는 받지 않아요',
              style: TextStyle(fontSize: 12, color: p.subtle),
            ),
          ],
        ),
      ],
    );
  }

  // ── 2. 어떤 상품이에요? ──────────────────────────────────────────────
  Widget _buildItemStep(ReloPalette p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReloTextField(
          label: '문제가 생긴 상품 이름',
          controller: _titleCtrl,
          hint: '예: 무선 노이즈캔슬링 헤드폰 블랙',
          fillColor: p.raised,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: ReloTextField(
                label: '주문한 수량',
                controller: _orderedQtyCtrl,
                keyboardType: TextInputType.number,
                fillColor: p.raised,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ReloTextField(
                label: '문제가 생긴 수량',
                controller: _claimQtyCtrl,
                keyboardType: TextInputType.number,
                fillColor: p.raised,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        _label('결제한 통화', p),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final code in MoneyFormat.currencies.keys)
              ReloChoiceChip(
                label: code,
                selected: _currency == code,
                onTap: () => setState(() => _currency = code),
              ),
          ],
        ),
        const SizedBox(height: 22),
        ReloTextField(
          label: '돌려받을 금액 ($_currency)',
          controller: _amountCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          hint: '예: 289.00',
          fillColor: p.raised,
        ),
      ],
    );
  }

  // ── 3. 어떻게 해결할까요? ────────────────────────────────────────────
  Widget _buildIssueStep(ReloPalette p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('원하는 해결 방법', p),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final kind in _kinds)
              ReloChoiceChip(
                label: kind.label,
                selected: _kind == kind.id,
                onTap: () => setState(() => _kind = kind.id),
              ),
          ],
        ),
        const SizedBox(height: 22),
        _label('무슨 문제가 있었어요?', p),
        const SizedBox(height: 10),
        // 자주 있는 문제를 고르면 아래 설명 칸에 문장이 채워진다
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final q in _quickIssues)
              ReloChoiceChip(
                label: q.label,
                selected: _issueCtrl.text == q.text,
                onTap: () => setState(() => _issueCtrl.text = q.text),
              ),
          ],
        ),
        const SizedBox(height: 14),
        ReloTextField(
          label: '자세한 설명',
          controller: _issueCtrl,
          maxLines: 3,
          fillColor: p.raised,
          // 고른 칩 표시를 글자에 맞춘다
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: Text(
                '판매자에게 보낼 설명',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: p.ink,
                ),
              ),
            ),
            ReloTextAction(
              label: _isTranslating ? '번역하는 중…' : 'AI로 번역',
              onTap: _isTranslating ? null : _handleAutoTranslate,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ReloTextField(
          label: '영어로 쓴 설명',
          controller: _issueEnCtrl,
          maxLines: 3,
          fillColor: p.raised,
        ),
      ],
    );
  }

  // ── 4. 영수증이나 사진이 있어요? ─────────────────────────────────────
  Widget _buildFilesStep(ReloPalette p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '영수증에 적힌 집 주소와 전화번호는 자동으로 가려요.',
          style: TextStyle(fontSize: 14, color: p.muted, height: 1.45),
        ),
        const SizedBox(height: 6),
        for (final f in _stagedFiles)
          _hairlineRow(
            p,
            vertical: 12,
            child: Row(
              children: [
                ReloIconTile(
                  icon: f.mime.contains('pdf')
                      ? ReloIcons.document
                      : ReloIcons.image,
                  color: p.raised,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        f.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: p.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        f.addressMasked ? '주소 가려짐' : '주소 확인 필요',
                        style: TextStyle(fontSize: 13, color: p.subtle),
                      ),
                    ],
                  ),
                ),
                if (_stagedFiles.length > 1)
                  IconButton(
                    tooltip: '파일 빼기',
                    icon: Icon(ReloIcons.close, size: 20, color: p.subtle),
                    onPressed: () => setState(
                      () => _stagedFiles.removeWhere((item) => item.id == f.id),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        ReloButton(
          text: '사진 · 영수증 추가',
          isPrimary: false,
          height: 48,
          icon: ReloIcons.add,
          onPressed: () {
            setState(() {
              _stagedFiles.add(
                StagedEvidenceFile(
                  id: 'stg_${DateTime.now().millisecondsSinceEpoch}',
                  name: '추가_파손증빙_${_stagedFiles.length + 1}.jpg',
                  mime: 'image/jpeg',
                  bytes: ReloStore.ensureValidFileSignature(
                    'image/jpeg',
                    utf8.encode('EXTRA_DAMAGE_EVIDENCE_PHOTO'),
                  ),
                  addressMasked: true,
                  defectTag: '추가 증빙',
                ),
              );
            });
          },
        ),
        const SizedBox(height: 10),
        Text(
          '파일 하나에 10MB까지 올릴 수 있어요.',
          style: TextStyle(fontSize: 12, color: p.subtle),
        ),
      ],
    );
  }

  // ── 5. 마지막으로 확인해요 ───────────────────────────────────────────
  Widget _buildConfirmStep(ReloStore store, ReloPalette p) {
    Widget summary(String label, String value) => _hairlineRow(
          p,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 112,
                child: Text(
                  label,
                  style: TextStyle(fontSize: 14, color: p.subtle),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: p.ink,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 신청 내용 (상자 없이 줄로)
        summary('쇼핑몰', _vendorCtrl.text),
        summary('주문번호', _orderRefCtrl.text),
        summary('상품', _titleCtrl.text),
        summary(
          '요청 금액',
          '${MoneyFormat.symbolOf(_currency)}${_amountCtrl.text} $_currency',
        ),
        summary('첨부', '${_stagedFiles.length}개 · 주소 가려짐'),
        // [항목 #10 숨겨진 요금 0원 확인]
        summary('수수료 · 성공보수', '0원'),
        const SizedBox(height: 24),

        // [항목 #6 입력 양식 동의항목 확인 & #9 다크패턴 방지] 기본은 체크하지 않은 상태
        _label('동의', p),
        const SizedBox(height: 4),
        ReloConsentRow(
          value: _consentClaimStorageRequired,
          onChanged: (v) => setState(() => _consentClaimStorageRequired = v),
          isRequired: true,
          title: '환불 내역과 증빙 사진 보관에 동의해요',
          subtitle: '내 보관함에만 암호화해서 두고, 언제든 바로 지울 수 있어요.',
          onViewDetail: () => store.openLegalDocument('privacy'),
        ),
        ReloConsentRow(
          value: _consentNoFalseClaimRequired,
          onChanged: (v) => setState(() => _consentNoFalseClaimRequired = v),
          isRequired: true,
          title: '실제로 산 물건이고 사실대로 적었어요',
          subtitle: '거짓 신고가 아님을 확인하고 이용약관에 동의해요.',
          onViewDetail: () => store.openLegalDocument('terms'),
        ),
        ReloConsentRow(
          value: _consentAiDraftOptional,
          onChanged: (v) => setState(() => _consentAiDraftOptional = v),
          isRequired: false,
          title: 'AI로 외국어 요청서 초안 만들기에 동의해요',
          subtitle: '고르지 않아도 기본 영어·일본어·중국어 문장은 무료로 쓸 수 있어요.',
        ),
      ],
    );
  }
}
