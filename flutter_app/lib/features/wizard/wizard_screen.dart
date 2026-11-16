import 'dart:convert';
import 'package:animations/animations.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/i18n/relo_i18n.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/motion_tokens.dart';
import '../../core/theme/relo_theme.dart';
import '../../core/utils/input_rules.dart';
import '../../core/utils/money_format.dart';
import '../../shared/models/claim_words.dart';
import '../../shared/models/domain_models.dart';
import '../../shared/state/relo_store.dart';
import '../../core/attachments/evidence_rules.dart';
import '../../shared/widgets/claim_row.dart';
import '../../shared/widgets/evidence_source_sheet.dart';
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
  /// 지금 언어의 문구
  ReloStrings get _s => ReloScope.of(context).strings;

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

  /// 버튼 위에 한 줄로 보여 주는 알림 (예: "영수증을 붙였어요"). 단계를 옮기면 지운다.
  String? _notice;

  /// 칸마다의 오류 (칸 아래 빨간 글자). 키: vendor, orderRef, title, orderedQty, claimQty, amount, issue
  final Map<String, String> _fieldErrors = {};

  /// 수량 칸: 숫자만, 세 자리까지
  static final List<TextInputFormatter> _qtyFormatters = [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(3),
  ];

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
  List<String> get _stepTitles => [
    _s.wStep1,
    _s.wStep2,
    _s.wStep3,
    _s.wStep4,
    _s.wStep5,
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
  List<({String label, String text})> get _quickIssues => [
    (label: _s.wIssueBroken, text: _s.wIssueBrokenText),
    (label: _s.wIssueWrong, text: _s.wIssueWrongText),
    (label: _s.wIssueDead, text: _s.wIssueDeadText),
    (label: _s.wIssueMissing, text: _s.wIssueMissingText),
  ];

  List<({String id, String label})> get _kinds => [
    (id: 'refund', label: _s.wKindRefund),
    (id: 'exchange', label: _s.wKindExchange),
    (id: 'repair', label: _s.wKindRepair),
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
    // 다른 앱에서 "공유 → ReLo"로 넘어온 영수증이 있으면 가져와 붙인다
    final shared = store.takeIncomingEvidence();
    if (shared != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _useReceipt(shared, announce: true);
      });
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

  // 영수증으로 채우기: 진짜 영수증을 찍거나 골라 붙이고, 서버의 AI가 읽은 내용으로 칸을 채운다.
  // 파일을 고를 수 없는 곳(웹 미리보기)에서는 샘플 영수증만 고른다.
  Future<void> _fillFromReceipt(ReloPalette p) async {
    final store = ReloScope.of(context);
    if (!store.evidencePicker.isSupported) return _openSampleReceipts(p);
    final picked = await pickEvidenceWithSheet(
      context,
      extra: (label: _s.wSampleTitle, onTap: () => _openSampleReceipts(p)),
    );
    if (picked == null || !mounted) return;
    await _useReceipt(picked);
  }

  /// 진짜 영수증 하나를 붙이고, 첫 단계라면 서버의 AI가 읽은 내용으로 칸을 채운다.
  /// (공유로 넘어온 영수증도 이 길로 온다.)
  Future<void> _useReceipt(PickedEvidence picked, {bool announce = false}) async {
    if (_createdClaim != null) return;
    final store = ReloScope.of(context);
    if (_step != 1) {
      // 이미 적어 둔 내용을 덮어쓰지 않게, 첫 단계가 아니면 붙이기만 한다
      setState(() => _attach(picked, first: true));
      _toast(_s.evSharedAttached);
      return;
    }
    setState(() {
      _isScanning = true;
      _formError = null;
      _notice = null;
    });
    // 진짜 파일에서는 읽지 못했을 때 예시 값을 지어내지 않는다
    final extracted = await store.scanReceiptDocument(
      fileName: picked.name,
      bytes: picked.bytes,
      mime: picked.mime,
      allowSample: false,
    );
    if (!mounted) return;
    setState(() {
      _isScanning = false;
      _applyExtracted(extracted);
      _attach(picked, first: true);
    });
    if (extracted.isEmpty) {
      _toast(_s.evReceiptAttachedOnly);
    } else if (announce) {
      _toast(_s.evSharedAttached);
    }
  }

  /// 진짜 파일을 붙인다. 미리 넣어 둔 예시 파일은 이때 뺀다. setState 안에서 부른다.
  void _attach(PickedEvidence picked, {bool first = false}) {
    _stagedFiles.removeWhere((f) => f.id.startsWith('stg_default_'));
    final staged = _stagedFrom(picked);
    if (first) {
      _stagedFiles.insert(0, staged);
    } else {
      _stagedFiles.add(staged);
    }
  }

  StagedEvidenceFile _stagedFrom(PickedEvidence picked) => StagedEvidenceFile(
        id: 'stg_${DateTime.now().microsecondsSinceEpoch}',
        name: picked.name,
        mime: picked.mime,
        bytes: picked.bytes,
        // 앱이 그림 속 주소를 가려 주지는 않는다: 사용자가 확인하도록 표시한다
        addressMasked: false,
      );

  /// 신청하는 동안에는 아래 고정 버튼을 가리지 않게, 알림을 버튼 위 한 줄로 보여 준다.
  /// 신청을 마친 화면에서는 다른 화면처럼 아래 알림으로 보여 준다.
  void _toast(String text) {
    if (_createdClaim != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    } else {
      setState(() => _notice = text);
    }
  }

  /// 영수증에서 읽은 값으로 칸을 채운다 (읽지 못한 칸은 그대로 둔다). setState 안에서 부른다.
  void _applyExtracted(Map<String, dynamic> extracted) {
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
  }

  Future<void> _addEvidence() async {
    final picked = await pickEvidenceWithSheet(context);
    if (picked == null || !mounted) return;
    setState(() => _attach(picked));
  }

  // 데모용 샘플 영수증 고르기
  Future<void> _openSampleReceipts(ReloPalette p) async {
    final samples = [
      (label: _s.wSampleAmazon, file: 'Amazon_Order_Receipt.pdf'),
      (label: _s.wSampleAli, file: 'AliExpress_Order_Slip.jpg'),
      (label: _s.wSampleMercari, file: 'Mercari_JP_Receipt.jpg'),
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
                  _s.wSampleTitle,
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800, color: p.ink),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  _s.wSampleNote,
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
      _notice = null;
    });
    final extracted = await store.scanReceiptDocument(
      fileName: sampleFileName,
      bytes: utf8.encode('SAMPLE_RECEIPT_$sampleFileName'),
    );
    if (!mounted) return;
    setState(() {
      _isScanning = false;
      _applyExtracted(extracted);
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
      setState(
        () => _fieldErrors['issue'] = _s.wErrIssueFirst,
      );
      return;
    }
    setState(() {
      _isTranslating = true;
      _formError = null;
      _notice = null;
      _fieldErrors.remove('issue');
    });
    final en = await store.translateIssueToEnglish(kor);
    if (!mounted) return;
    setState(() {
      _isTranslating = false;
      _issueEnCtrl.text = en;
    });
  }

  void _clearFieldError(String key) {
    if (_fieldErrors.containsKey(key)) setState(() => _fieldErrors.remove(key));
  }

  /// 다음 단계로 가기 전에 이 단계의 칸을 본다. 고칠 것이 있으면 그 칸 아래에 알리고 머문다.
  void _goNextStep() {
    final errors = <String, String>{};
    if (_step == 1) {
      if (_vendorCtrl.text.trim().isEmpty) {
        errors['vendor'] = _s.wErrVendor;
      }
      if (_orderRefCtrl.text.trim().isEmpty) {
        errors['orderRef'] = _s.wErrOrderRef;
      }
    } else if (_step == 2) {
      final ordQty = int.tryParse(_orderedQtyCtrl.text) ?? 0;
      final clmQty = int.tryParse(_claimQtyCtrl.text) ?? 0;
      if (_titleCtrl.text.trim().isEmpty) {
        errors['title'] = _s.wErrTitle;
      }
      if (ordQty < 1) {
        errors['orderedQty'] = _s.wErrQtyMin;
      }
      if (clmQty < 1) {
        errors['claimQty'] = _s.wErrQtyMin;
      } else if (ordQty >= 1 && clmQty > ordQty) {
        errors['claimQty'] = _s.wErrQtyMax;
      }
      if (InputRules.amount(_amountCtrl.text) == null) {
        errors['amount'] = _s.cmErrAmount;
      }
    } else if (_step == 3) {
      if (_issueCtrl.text.trim().length < 5) {
        errors['issue'] = _s.wErrIssue;
      }
    }
    setState(() {
      _formError = null;
      _notice = null;
      _fieldErrors
        ..clear()
        ..addAll(errors);
    });
    if (errors.isNotEmpty) return;
    setState(() {
      _stepReverse = false;
      _step = (_step + 1).clamp(1, 5);
    });
    _scrollToTop();
  }

  Future<void> _handleSubmitWizard() async {
    if (!_consentClaimStorageRequired || !_consentNoFalseClaimRequired) {
      setState(() {
        _formError = _s.wErrConsent;
      });
      return;
    }

    final store = ReloScope.of(context);
    setState(() {
      _isSubmitting = true;
      _formError = null;
      _notice = null;
    });
    final ClaimView created;
    try {
      created = await store.createClaimFromWizard(
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
    } on ApiError catch (e) {
      // 서버가 신청을 받지 않았다. 된 것처럼 넘어가지 않고 까닭을 보여 준다.
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _formError = store.locale == ReloLocale.ko ? e.message : _s.cwFailed;
      });
      return;
    }
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
        _notice = null;
        _fieldErrors.clear();
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
    // 안드로이드 뒤로 가기: 앱을 끄지 않고 이전 단계로 간다.
    // 첫 단계와 신청 완료 화면에서는 홈으로 돌아간다.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_createdClaim != null) {
          store.navigateToTab(0);
        } else {
          _goBack(store);
        }
      },
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
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
                tooltip: _step > 1 ? _s.wPrevStep : _s.wToHome,
                onPressed: () => _goBack(store),
                icon: Icon(ReloIcons.back, color: p.ink),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Semantics(
                  label: _s.wStepOf(_step),
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
                )
              else if (_notice != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      _notice!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: p.muted,
                      ),
                    ),
                  ),
                ),
              if (_step < 5)
                ReloButton(text: _s.wNext, onPressed: _goNextStep)
              else
                ReloButton(
                  text: _isSubmitting ? _s.wSubmitting : _s.wSubmit,
                  busy: _isSubmitting,
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
                  hubLabel: _s.wGlobeHub,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _s.wDeparted(corridor.city),
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: p.ink),
              ),
              const SizedBox(height: 6),
              Text(
                _s.wSavedLine(claim.vendor, claim.orderRef),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: p.muted, height: 1.5),
              ),
              const SizedBox(height: 24),
              ReloButton(
                text: _s.wGoMessage,
                showTrailingArrow: true,
                onPressed: () => store.openClaimDetail(claim.id),
              ),
              const SizedBox(height: 8),
              ReloButton(
                text: _s.wViewClaims,
                isPrimary: false,
                onPressed: () => store.navigateToTab(2),
              ),
              // 마감이 있는 건을 처음 등록했을 때 한 번, 마감 알림을 권한다 (권한은 눌렀을 때만 묻는다)
              if (store.reminders.isSupported &&
                  !store.deadlineRemindersOn &&
                  !store.reminderChoiceMade) ...[
                const SizedBox(height: 6),
                Center(
                  child: ReloTextAction(
                    label: _s.rmAskAction,
                    onTap: () async {
                      final ok = await store.setDeadlineReminders(true);
                      if (!mounted) return;
                      _toast(ok ? _s.rmTurnedOn : _s.stRemindersDenied);
                    },
                  ),
                ),
              ],
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
              onTap: _isScanning ? null : () => _fillFromReceipt(p),
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
                        _isScanning ? _s.wReceiptReading : _s.wReceiptFill,
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
        _label(_s.wOrPick, p),
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
                  _amountCtrl.text =
                      InputRules.fitCurrency(_amountCtrl.text, mall.currency);
                  _fieldErrors.remove('vendor');
                }),
              ),
            ReloChoiceChip(
              label: _s.wCustomVendor,
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
            label: _s.wVendorName,
            controller: _vendorCtrl,
            hint: _s.wVendorHint,
            fillColor: p.raised,
            errorText: _fieldErrors['vendor'],
            onChanged: (_) => _clearFieldError('vendor'),
          ),
        ],
        const SizedBox(height: 22),
        ReloTextField(
          label: _s.cmOrderNo,
          controller: _orderRefCtrl,
          hint: _s.wOrderHint,
          fillColor: p.raised,
          errorText: _fieldErrors['orderRef'],
          onChanged: (_) => _clearFieldError('orderRef'),
        ),
        const SizedBox(height: 14),
        ReloTextField(
          label: _s.wOrderDate,
          controller: _orderedOnCtrl,
          readOnly: true,
          onTap: _pickOrderedOn,
          trailingIcon: ReloIcons.calendar,
          fillColor: p.raised,
        ),
        // [항목 #7 불필요한 개인정보 미수집 안내] 첫 단계 맨 아래 한 줄
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(ReloIcons.lock, size: 14, color: p.subtle),
            ),
            const SizedBox(width: 6),
            // 다른 언어에서는 문장이 길어지므로, 넘치면 다음 줄로 내린다
            Expanded(
              child: Text(
                _s.wPrivacyLine,
                style: TextStyle(fontSize: 12, color: p.subtle, height: 1.4),
              ),
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
          label: _s.wItemName,
          controller: _titleCtrl,
          hint: _s.wItemHint,
          fillColor: p.raised,
          errorText: _fieldErrors['title'],
          onChanged: (_) => _clearFieldError('title'),
        ),
        const SizedBox(height: 14),
        Row(
          // 한쪽에만 오류 글자가 나와도 칸 높이가 어긋나지 않게 위에 맞춘다
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ReloTextField(
                label: _s.wQtyOrdered,
                controller: _orderedQtyCtrl,
                keyboardType: TextInputType.number,
                fillColor: p.raised,
                inputFormatters: _qtyFormatters,
                errorText: _fieldErrors['orderedQty'],
                onChanged: (_) => _clearFieldError('orderedQty'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ReloTextField(
                label: _s.wQtyProblem,
                controller: _claimQtyCtrl,
                keyboardType: TextInputType.number,
                fillColor: p.raised,
                inputFormatters: _qtyFormatters,
                errorText: _fieldErrors['claimQty'],
                onChanged: (_) => _clearFieldError('claimQty'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        _label(_s.wCurrency, p),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final code in MoneyFormat.currencies.keys)
              ReloChoiceChip(
                label: code,
                selected: _currency == code,
                onTap: () => setState(() {
                  _currency = code;
                  // 원 · 엔처럼 소수가 없는 통화로 바꾸면 소수점 아래를 떼어 낸다
                  _amountCtrl.text =
                      InputRules.fitCurrency(_amountCtrl.text, code);
                }),
              ),
          ],
        ),
        const SizedBox(height: 22),
        ReloTextField(
          label: _s.wAmount(_currency),
          controller: _amountCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          hint: _s.wAmountHint,
          fillColor: p.raised,
          inputFormatters: [MoneyInputFormatter.of(_currency)],
          errorText: _fieldErrors['amount'],
          onChanged: (_) => _clearFieldError('amount'),
        ),
      ],
    );
  }

  // ── 3. 어떻게 해결할까요? ────────────────────────────────────────────
  Widget _buildIssueStep(ReloPalette p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(_s.wResolution, p),
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
        _label(_s.wWhatProblem, p),
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
                onTap: () => setState(() {
                  _issueCtrl.text = q.text;
                  _fieldErrors.remove('issue');
                }),
              ),
          ],
        ),
        const SizedBox(height: 14),
        ReloTextField(
          label: _s.wDetail,
          controller: _issueCtrl,
          maxLines: 3,
          fillColor: p.raised,
          errorText: _fieldErrors['issue'],
          // 고른 칩 표시를 글자에 맞추고, 오류가 있었으면 지운다
          onChanged: (_) => setState(() => _fieldErrors.remove('issue')),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: Text(
                _s.wSellerDesc,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: p.ink,
                ),
              ),
            ),
            ReloTextAction(
              label: _isTranslating ? _s.wTranslating : _s.wTranslate,
              onTap: _isTranslating ? null : _handleAutoTranslate,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ReloTextField(
          label: _s.wEnglishDesc,
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
          _s.wMaskNote,
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
                        f.addressMasked ? _s.cmAddressMasked : _s.wAddressCheck,
                        style: TextStyle(fontSize: 13, color: p.subtle),
                      ),
                    ],
                  ),
                ),
                // 진짜 파일은 언제든 뺄 수 있고, 예시 파일은 하나는 남긴다
                if (_stagedFiles.length > 1 || !f.id.startsWith('stg_default_'))
                  IconButton(
                    tooltip: _s.wRemoveFile,
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
          text: _s.wAddFile,
          isPrimary: false,
          height: 48,
          icon: ReloIcons.add,
          onPressed: _addEvidence,
        ),
        const SizedBox(height: 10),
        Text(
          _s.wFileLimit,
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
        summary(_s.wSumVendor, _vendorCtrl.text),
        summary(_s.cmOrderNo, _orderRefCtrl.text),
        summary(_s.wSumItem, _titleCtrl.text),
        summary(
          _s.wSumAmount,
          '${MoneyFormat.symbolOf(_currency)}${_amountCtrl.text} $_currency',
        ),
        summary(
          _s.wSumFiles,
          _s.wSumFilesValue(
            _stagedFiles.length,
            masked: _stagedFiles.every((f) => f.addressMasked),
          ),
        ),
        // [항목 #10 숨겨진 요금 0원 확인]
        summary(_s.wSumFee, _s.wFree),
        const SizedBox(height: 24),

        // [항목 #6 입력 양식 동의항목 확인 & #9 다크패턴 방지] 기본은 체크하지 않은 상태
        _label(_s.cmConsent, p),
        const SizedBox(height: 4),
        ReloConsentRow(
          value: _consentClaimStorageRequired,
          onChanged: (v) => setState(() => _consentClaimStorageRequired = v),
          isRequired: true,
          title: _s.wConsent1Title,
          subtitle: _s.wConsent1Sub,
          onViewDetail: () => store.openLegalDocument('privacy'),
        ),
        ReloConsentRow(
          value: _consentNoFalseClaimRequired,
          onChanged: (v) => setState(() => _consentNoFalseClaimRequired = v),
          isRequired: true,
          title: _s.wConsent2Title,
          subtitle: _s.wConsent2Sub,
          onViewDetail: () => store.openLegalDocument('terms'),
        ),
        ReloConsentRow(
          value: _consentAiDraftOptional,
          onChanged: (v) => setState(() => _consentAiDraftOptional = v),
          isRequired: false,
          title: _s.wConsent3Title,
          subtitle: _s.wConsent3Sub,
        ),
      ],
    );
  }
}
