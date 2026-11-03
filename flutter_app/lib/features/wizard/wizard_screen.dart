import 'dart:convert';
import 'package:animations/animations.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import '../../core/theme/motion_tokens.dart';
import '../../core/theme/relo_theme.dart';
import '../../core/utils/money_format.dart';
import '../../shared/models/domain_models.dart';
import '../../shared/state/relo_store.dart';
import '../../shared/widgets/refund_globe.dart';
import '../../shared/widgets/relo_primitives.dart';

/// @module features/wizard/wizard_screen
/// @layer Feature Module — 5-Step Claim Wizard with Explicit Consent & Data Minimization
/// @purpose [법적 안전장치 #6 양식 동의항목 확인, #7 불필요한 개인정보 미수집, #9 다크패턴 방지, #10 숨겨진 요금 0원]
///          Step 1~5 간편 신청 과정과 함께 영수증 집 주소 마스킹 및 제출 전 명시적 동의 확인을 제공합니다.
class WizardScreen extends StatefulWidget {
  const WizardScreen({super.key});

  @override
  State<WizardScreen> createState() => _WizardScreenState();
}

class _WizardScreenState extends State<WizardScreen> {
  int _step = 1;

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

  static const List<String> _quickIssues = [
    '택배 상자를 열었을 때 겉상자와 상품 외관이 깨진 상태로 도착했습니다.',
    '주문한 옵션과 다른 색상·모델의 상품이 잘못 배송되었습니다.',
    '전원을 연결해도 켜지지 않는 작동 불량 상품입니다.',
    '배송 완료로 표시되었지만 실제로 택배를 받지 못했습니다.',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = ReloScope.of(context);
    if (store.wizardPresetVendor != null) {
      _vendorCtrl.text = store.wizardPresetVendor!;
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
                      Icon(Icons.receipt_long_outlined, color: p.muted),
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
  }

  Future<void> _handleSubmitWizard() async {
    if (!_consentClaimStorageRequired || !_consentNoFalseClaimRequired) {
      setState(() {
        _formError = '제출 전 필수 동의 항목 2가지를 확인하고 체크해 주세요.';
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

  @override
  Widget build(BuildContext context) {
    final store = ReloScope.of(context);
    final p = ReloPalette.of(context);

    if (_createdClaim != null) {
      return _buildSuccess(store, p, _createdClaim!);
    }

    final title = _stepTitles[_step - 1];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 뒤로 · 몇 단계째인지 · 진행 막대. 머리말은 이것만 둔다.
          Row(
            children: [
              IconButton(
                tooltip: _step > 1 ? '이전 단계' : '홈으로',
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  if (_step > 1) {
                    setState(() {
                      _stepReverse = true;
                      _step -= 1;
                    });
                  } else {
                    store.navigateToTab(0);
                  }
                },
                icon: Icon(Icons.arrow_back_rounded, color: p.body),
              ),
              const SizedBox(width: 4),
              Text(
                '$_step / 5',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: p.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: _step / 5.0,
              minHeight: 4,
              backgroundColor: p.sunken,
              valueColor: AlwaysStoppedAnimation<Color>(p.brand),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: p.ink,
            ),
          ),
          if (_formError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: p.dangerSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: p.danger),
              ),
              child: Text(
                _formError!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: p.danger,
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
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
              child: _buildStepCard(store, p),
            ),
          ),
          const SizedBox(height: 16),
          if (_step < 5)
            ReloButton(
              text: '다음',
              onPressed: _goNextStep,
            )
          else
            ReloButton(
              text: _isSubmitting ? '등록 중…' : '환불 신청 등록하기',
              onPressed: _isSubmitting ? null : _handleSubmitWizard,
            ),
          // [항목 #7 불필요한 개인정보 미수집 안내] 첫 단계 맨 아래 한 줄
          if (_step == 1) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline_rounded, size: 14, color: p.muted),
                const SizedBox(width: 6),
                Text(
                  '주민번호·통관번호·카드번호는 받지 않아요',
                  style: TextStyle(fontSize: 12, color: p.muted),
                ),
              ],
            ),
          ],
        ],
      ),
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
                text: '외국어 메시지 복사하러 가기',
                showTrailingArrow: true,
                onPressed: () => store.openClaimDetail(claim.id),
              ),
              const SizedBox(height: 8),
              ReloButton(
                text: '내 환불 목록 보기',
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

  Widget _buildStepCard(ReloStore store, ReloPalette p) {
    switch (_step) {
      case 1:
        final knownMall = _quickMalls.any((m) => m.name == _vendorCtrl.text);
        final showVendorField = _customVendor || !knownMall;
        Widget mallChip(String label, bool selected, VoidCallback onTap) {
          return GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: selected ? p.brand : p.surface,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : p.body,
                ),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 영수증으로 채우기 하나만 크게. 샘플 고르기는 누르면 아래에서 열린다.
            Material(
              color: p.surface,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _isScanning ? null : () => _openSampleReceipts(p),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          size: 20, color: p.brandHover),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _isScanning ? '영수증 읽는 중…' : '영수증으로 자동 채우기',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: p.ink,
                          ),
                        ),
                      ),
                      if (_isScanning)
                        const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(Icons.chevron_right_rounded, color: p.subtle),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              '또는 직접 고르기',
              style: TextStyle(fontSize: 13, color: p.muted),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 8,
              children: [
                for (final mall in _quickMalls)
                  mallChip(
                    mall.label,
                    !_customVendor && _vendorCtrl.text == mall.name,
                    () => setState(() {
                      _customVendor = false;
                      _vendorCtrl.text = mall.name;
                      _currency = mall.currency;
                    }),
                  ),
                mallChip(
                  '직접 입력',
                  showVendorField,
                  () => setState(() {
                    _customVendor = true;
                    _vendorCtrl.clear();
                  }),
                ),
              ],
            ),
            if (showVendorField) ...[
              const SizedBox(height: 14),
              ReloTextField(
                label: '쇼핑몰 이름',
                controller: _vendorCtrl,
                hint: '예: Coupang Global, eBay',
              ),
            ],
            const SizedBox(height: 18),
            ReloTextField(
              label: '주문번호',
              controller: _orderRefCtrl,
              hint: '예: 114-8920411-33012',
            ),
            const SizedBox(height: 14),
            ReloTextField(
              label: '주문일',
              controller: _orderedOnCtrl,
              readOnly: true,
              onTap: _pickOrderedOn,
              trailingIcon: Icons.calendar_today_outlined,
            ),
          ],
        );

      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReloTextField(
              label: '문제가 생긴 상품 이름',
              controller: _titleCtrl,
              hint: '예: 무선 노이즈캔슬링 헤드폰 블랙',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ReloTextField(
                    label: '전체 주문 수량',
                    controller: _orderedQtyCtrl,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ReloTextField(
                    label: '문제가 생긴 수량',
                    controller: _claimQtyCtrl,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '결제한 통화 (8개국 통화 지원)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: p.body,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: MoneyFormat.currencies.keys.map((code) {
                final active = _currency == code;
                return GestureDetector(
                  onTap: () => setState(() => _currency = code),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: active ? p.brand : p.sunken,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$code (${MoneyFormat.symbolOf(code)})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: active ? Colors.white : p.body,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            ReloTextField(
              label: '돌려받을 금액 ($_currency)',
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              hint: '예: 289.00',
            ),
          ],
        );

      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '원하는 해결 방법',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: p.body,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildKindChip('refund', '반품 · 전액 환불', p),
                const SizedBox(width: 8),
                _buildKindChip('exchange', '새 상품 교환', p),
                const SizedBox(width: 8),
                _buildKindChip('repair', '부분 환불 · 수리', p),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _quickIssues.map((q) {
                return _buildActionChip(
                  label: q.length > 22 ? '${q.substring(0, 22)}…' : q,
                  onTap: () => setState(() => _issueCtrl.text = q),
                  p: p,
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            ReloTextField(
              label: '우리말 문제 설명',
              controller: _issueCtrl,
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            ReloButton(
              text: _isTranslating ? '외국어로 번역 중...' : 'AI 쇼핑몰 제출용 외국어 자동 번역',
              isPrimary: false,
              height: 44,
              icon: Icons.translate_rounded,
              onPressed: _isTranslating ? null : _handleAutoTranslate,
            ),
            const SizedBox(height: 10),
            ReloTextField(
              label: '쇼핑몰 제출용 외국어 설명 (자동 생성됨)',
              controller: _issueEnCtrl,
              maxLines: 3,
            ),
          ],
        );

      case 4:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '첨부된 증빙 서류 (${_stagedFiles.length}개)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: p.ink,
                  ),
                ),
                const ReloBadge(
                  label: '집 주소 마스킹 완료',
                  tone: ReloBadgeTone.neutral,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '영수증 내 집 주소·전화번호 영역은 개인정보 보호를 위해 자동 마스킹 처리됩니다.',
              style: TextStyle(fontSize: 11.5, color: p.body),
            ),
            const SizedBox(height: 12),
            ..._stagedFiles.map(
              (f) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: p.sunken,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: p.line),
                ),
                child: Row(
                  children: [
                    Icon(
                      f.mime.contains('pdf')
                          ? Icons.picture_as_pdf_rounded
                          : Icons.image_rounded,
                      color: p.brandHover,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        f.name,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: p.ink,
                        ),
                      ),
                    ),
                    const ReloBadge(
                      label: '주소 가려짐',
                      tone: ReloBadgeTone.neutral,
                    ),
                    if (_stagedFiles.length > 1) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => setState(
                          () => _stagedFiles.removeWhere(
                            (item) => item.id == f.id,
                          ),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: p.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            ReloButton(
              text: '불량 사진 · 영수증 파일 추가 첨부 (10MB 이하)',
              isPrimary: false,
              height: 44,
              icon: Icons.add_photo_alternate_rounded,
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
          ],
        );

      case 5:
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // [항목 #10 숨겨진 요금 0원 확인 박스]
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '서비스 이용 수수료 · 환불 성공보수',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: p.ink,
                    ),
                  ),
                  Text(
                    '0원 (100% 무료)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: p.ink,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '최종 신청 요약',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: p.ink,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: p.sunken,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: p.line),
              ),
              child: Text(
                '• 쇼핑몰: ${_vendorCtrl.text} (주문번호 #${_orderRefCtrl.text})\n'
                '• 상품명: ${_titleCtrl.text}\n'
                '• 요청 금액: $_currency ${_amountCtrl.text}\n'
                '• 첨부 증빙: ${_stagedFiles.length}개 (집 주소 마스킹 적용)',
                style: TextStyle(
                  fontSize: 12,
                  color: p.body,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // [항목 #6 입력 양식 동의항목 확인 & #9 다크패턴 방지]
            Text(
              '환불 신청 제출 전 필수 동의 확인 (기본 미체크 원칙)',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                color: p.ink,
              ),
            ),
            const SizedBox(height: 8),
            ReloConsentCheckbox(
              value: _consentClaimStorageRequired,
              onChanged: (v) =>
                  setState(() => _consentClaimStorageRequired = v),
              isRequired: true,
              title: '환불 내역 및 증빙 사진 보관 동의',
              subtitle: '입력한 주문 정보와 사진은 내 전용 보관함에만 암호화 격리되며 언제든 즉시 파기할 수 있습니다.',
              onViewDetail: () => store.openLegalDocument('privacy'),
            ),
            ReloConsentCheckbox(
              value: _consentNoFalseClaimRequired,
              onChanged: (v) =>
                  setState(() => _consentNoFalseClaimRequired = v),
              isRequired: true,
              title: '실제 구매 및 사실에 기반한 클레임 확인',
              subtitle: '허위 파손 신고가 아닌 실제 주문 사실에 기반함을 확인하며 이용약관에 동의합니다.',
              onViewDetail: () => store.openLegalDocument('terms'),
            ),
            ReloConsentCheckbox(
              value: _consentAiDraftOptional,
              onChanged: (v) => setState(() => _consentAiDraftOptional = v),
              isRequired: false,
              title: 'AI 맞춤 외국어 요청서 초안 생성 동의 (선택)',
              subtitle: '선택하지 않아도 기본 영문/일문/중문 템플릿을 무료로 이용할 수 있어요.',
            ),
          ],
        );
    }
  }

  Widget _buildKindChip(String id, String label, ReloPalette p) {
    final active = _kind == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _kind = id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? p.brand : p.sunken,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: active ? Colors.white : p.body,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionChip({
    required String label,
    required VoidCallback onTap,
    required ReloPalette p,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: p.line),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: p.body,
          ),
        ),
      ),
    );
  }
}
