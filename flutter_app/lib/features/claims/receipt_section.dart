import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/i18n/relo_i18n.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/relo_theme.dart';
import '../../core/utils/input_rules.dart';
import '../../core/utils/money_format.dart';
import '../../shared/models/claim_rules.dart';
import '../../shared/models/claim_words.dart';
import '../../shared/models/domain_models.dart';
import '../../shared/state/relo_store.dart';
import '../../shared/widgets/relo_icons.dart';
import '../../shared/widgets/relo_primitives.dart';

/// @module features/claims/receipt_section
/// @purpose 상세의 입금 탭 윗부분: 실제로 받은 것을 기록하는 칸과 받은 기록 목록.
///          환불은 돈(입금 번호, 없으면 메모와 확인), 교환은 받은 수량, 수리는 결과만 적는다.
///          잘못 적은 기록은 고치지 않고 이유를 적어 되돌린다. 되돌린 기록은 줄이 그어진 채 남는다.
///          받을 것이 바뀌면(기록 · 되돌리기 · 약속 금액) 부모가 key를 바꿔 칸을 새로 채운다.
class ReceiptSection extends StatefulWidget {
  final ClaimView claim;

  /// 기록이 저장됐을 때 (부모가 축하 효과를 낸다)
  final VoidCallback onRecorded;

  /// 기록을 되돌렸을 때 (부모가 축하 문구를 치운다)
  final VoidCallback? onUndone;

  const ReceiptSection({
    super.key,
    required this.claim,
    required this.onRecorded,
    this.onUndone,
  });

  @override
  State<ReceiptSection> createState() => _ReceiptSectionState();
}

class _ReceiptSectionState extends State<ReceiptSection> {
  ReloStrings get _s => ReloScope.of(context).strings;

  late final TextEditingController _amountCtrl;
  late final TextEditingController _qtyCtrl;
  final _refCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _dateCtrl = TextEditingController(
    text: DateTime.now().toIso8601String().substring(0, 10),
  );
  bool _noRefChecked = false;
  bool _busy = false;

  /// 되돌리려고 펼친 기록
  String? _undoId;

  /// 칸 아래 빨간 글자. 키: amount, date, note, noRef, qty, reason
  final Map<String, String> _errors = {};

  /// 아직 받지 못한 교환품 수
  int get _left {
    final s = widget.claim.summary;
    return s.requestedQty > s.goods ? s.requestedQty - s.goods : 0;
  }

  @override
  void initState() {
    super.initState();
    final c = widget.claim;
    final owed = (c.agreed ?? c.claimed) - c.summary.cash;
    _amountCtrl = TextEditingController(
      text: MoneyFormat.minorToDecimalString(owed > 0 ? owed : 0, c.currency),
    );
    _qtyCtrl = TextEditingController(text: '${_left < 1 ? 1 : _left}');
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _qtyCtrl.dispose();
    _refCtrl.dispose();
    _noteCtrl.dispose();
    _reasonCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  void _clear(String key) {
    if (_errors.containsKey(key)) setState(() => _errors.remove(key));
  }

  /// 받은 날은 달력에서 고른다 (오늘까지만)
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final current = DateTime.tryParse(_dateCtrl.text) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: current.isAfter(now) ? now : current,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _dateCtrl.text = picked.toIso8601String().substring(0, 10);
      _errors.remove('date');
    });
  }

  Future<void> _record(ReloStore store) async {
    final c = widget.claim;
    final ref = _refCtrl.text.trim();
    final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
    final errors = <String, String>{};
    if (c.kind == 'refund') {
      if (InputRules.amount(_amountCtrl.text) == null) {
        errors['amount'] = _s.cmErrAmount;
      }
      // 번호가 없는 입금: 어디에서 확인했는지와, 같은 입금이 아니라는 확인을 받는다
      if (ref.isEmpty && _noteCtrl.text.trim().length < 10) {
        errors['note'] = _s.cwErrNote;
      }
      if (ref.isEmpty && !_noRefChecked) errors['noRef'] = _s.cwErrNoRefCheck;
    }
    if (c.kind == 'exchange' && (qty < 1 || qty > _left)) {
      errors['qty'] = _s.cwErrQty;
    }
    if (!InputRules.isoDate(_dateCtrl.text)) errors['date'] = _s.dErrDate;
    if (errors.isNotEmpty) {
      setState(() {
        _errors
          ..clear()
          ..addAll(errors);
      });
      return;
    }

    // 저장되면 부모가 이 칸을 새로 만들기 때문에, 알릴 것은 미리 잡아 둔다
    final messenger = ScaffoldMessenger.of(context);
    final onRecorded = widget.onRecorded;
    final doneText = _s.cwRecorded(c.kind);
    setState(() {
      _busy = true;
      _errors.clear();
    });
    try {
      await store.recordReceipt(
        claimId: c.id,
        receivedOn: _dateCtrl.text.trim(),
        amountStr: _amountCtrl.text.trim(),
        transactionRef: ref,
        note: _noteCtrl.text.trim(),
        noRefConfirmed: _noRefChecked,
        quantity: qty < 1 ? 1 : qty,
      );
    } on ApiError catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(store.refusalText(e))));
      if (mounted) setState(() => _busy = false);
      return;
    }
    onRecorded();
    messenger.showSnackBar(SnackBar(content: Text(doneText)));
    if (mounted) setState(() => _busy = false);
  }

  void _openUndo(String? id) {
    setState(() {
      _undoId = id;
      _reasonCtrl.clear();
      _errors.remove('reason');
    });
  }

  Future<void> _undo(ReloStore store, LedgerEntry entry) async {
    final reason = _reasonCtrl.text.trim();
    if (reason.length < 3) {
      setState(() => _errors['reason'] = _s.cwErrReason);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final doneText = _s.cwToastUndone;
    final onUndone = widget.onUndone;
    setState(() => _busy = true);
    try {
      await store.undoReceipt(
        claimId: widget.claim.id,
        entryId: entry.id,
        reason: reason,
      );
    } on ApiError catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(store.refusalText(e))));
      if (mounted) setState(() => _busy = false);
      return;
    }
    onUndone?.call();
    messenger.showSnackBar(SnackBar(content: Text(doneText)));
    if (mounted) {
      setState(() {
        _busy = false;
        _undoId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = ReloScope.of(context);
    final palette = ReloPalette.of(context);
    final c = widget.claim;
    final locked = isClaimLocked(c);
    final rows = receivedRows(c.ledger);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _s.cwReceiveTitle(c.kind),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: palette.ink,
          ),
        ),
        const SizedBox(height: 12),
        if (locked || isAllReceived(c))
          _note(locked ? _s.cwLocked : _s.cwAllDone, palette)
        else
          ..._form(store, c, palette),
        if (rows.isNotEmpty) ...[
          const SizedBox(height: 28),
          Text(
            _s.cwLedgerCount(c.kind, rows.where((r) => !r.undone).length),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: palette.subtle,
            ),
          ),
          for (final row in rows) _ledgerRow(store, c, row, !locked, palette),
        ],
      ],
    );
  }

  Widget _note(String text, ReloPalette palette) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.raised,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 14, color: palette.body, height: 1.45),
        ),
      );

  Widget _caption(String text, ReloPalette palette) => Text(
        text,
        style: TextStyle(fontSize: 12, color: palette.subtle, height: 1.4),
      );

  List<Widget> _form(ReloStore store, ClaimView c, ReloPalette palette) {
    final dateField = ReloTextField(
      label: _s.dDateField,
      controller: _dateCtrl,
      fillColor: palette.raised,
      // 글자로 치지 않고 달력에서 고른다
      readOnly: true,
      onTap: _pickDate,
      trailingIcon: ReloIcons.calendar,
      errorText: _errors['date'],
    );
    final noFile = c.files.isEmpty;

    return [
      if (c.kind == 'repair')
        dateField
      else
        Row(
          // 한쪽에만 오류 글자가 나와도 칸 높이가 어긋나지 않게 위에 맞춘다
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: c.kind == 'exchange'
                  ? ReloTextField(
                      label: _s.cwQtyField(_left),
                      controller: _qtyCtrl,
                      keyboardType: TextInputType.number,
                      fillColor: palette.raised,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      errorText: _errors['qty'],
                      onChanged: (_) => _clear('qty'),
                    )
                  : ReloTextField(
                      label: _s.dDepositField(c.currency),
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      fillColor: palette.raised,
                      inputFormatters: [MoneyInputFormatter.of(c.currency)],
                      errorText: _errors['amount'],
                      onChanged: (_) => _clear('amount'),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(child: dateField),
          ],
        ),
      if (c.kind == 'refund') ...[
        const SizedBox(height: 12),
        ReloTextField(
          label: _s.cwRefField,
          controller: _refCtrl,
          fillColor: palette.raised,
          // 번호를 적거나 지우면 아래 메모 칸이 사라지거나 나타난다
          onChanged: (_) => setState(() {}),
        ),
        if (_refCtrl.text.trim().isEmpty) ...[
          const SizedBox(height: 12),
          ReloTextField(
            label: _s.cwNoRefNote,
            hint: _s.cwNoRefHint,
            controller: _noteCtrl,
            fillColor: palette.raised,
            errorText: _errors['note'],
            onChanged: (_) => _clear('note'),
          ),
          const SizedBox(height: 4),
          _CheckLine(
            label: _s.cwNoRefCheck,
            value: _noRefChecked,
            errorText: _errors['noRef'],
            onChanged: (v) => setState(() {
              _noRefChecked = v;
              _errors.remove('noRef');
            }),
          ),
        ],
      ],
      const SizedBox(height: 8),
      _caption(noFile ? _s.cwNeedFile : _s.cwCaption(c.kind), palette),
      const SizedBox(height: 16),
      ReloButton(
        text: _busy ? _s.dRecording : _s.cwRecord(c.kind),
        busy: _busy,
        onPressed: _busy || noFile ? null : () => _record(store),
      ),
    ];
  }

  Widget _ledgerRow(
    ReloStore store,
    ClaimView c,
    ReceivedRow row,
    bool canUndo,
    ReloPalette palette,
  ) {
    final entry = row.entry;
    final amount = switch (entry.kind) {
      'goods' => _s.cwGoods(entry.quantity),
      'repair' => _s.cwRepairEntry,
      _ => MoneyFormat.formatMinor(entry.amount, c.currency),
    };
    final head = [
      entry.receivedOn,
      if (entry.transactionRef.isNotEmpty) entry.transactionRef,
      if (row.undone) _s.cwUndone,
    ].join(' · ');
    final opened = _undoId == entry.id;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: palette.line.withValues(alpha: 0.5)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        head,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: row.undone ? palette.subtle : palette.ink,
                        ),
                      ),
                      if (entry.note.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          entry.note,
                          style:
                              TextStyle(fontSize: 13, color: palette.subtle),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  amount,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: row.undone ? palette.subtle : palette.ink,
                    decoration:
                        row.undone ? TextDecoration.lineThrough : null,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            if (canUndo && !row.undone && !opened)
              Align(
                alignment: Alignment.centerLeft,
                child: Transform.translate(
                  // 글자 버튼의 안쪽 여백만큼 당겨서, 왼쪽 줄을 위 글자와 맞춘다
                  offset: const Offset(-6, 4),
                  child: ReloMutedAction(
                    label: _s.cwUndo,
                    onTap: _busy ? null : () => _openUndo(entry.id),
                  ),
                ),
              ),
            if (opened) ...[
              const SizedBox(height: 12),
              ReloTextField(
                label: _s.cwUndoReason,
                hint: _s.cwUndoHint,
                controller: _reasonCtrl,
                fillColor: palette.raised,
                errorText: _errors['reason'],
                onChanged: (_) => _clear('reason'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ReloButton(
                      text: _s.cwCancel,
                      isPrimary: false,
                      height: 48,
                      onPressed: _busy ? null : () => _openUndo(null),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ReloButton(
                      text: _s.cwUndoConfirm,
                      isPrimary: false,
                      height: 48,
                      busy: _busy,
                      onPressed: _busy ? null : () => _undo(store, entry),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 체크 한 줄 (상자 없이). 누르는 자리는 글자까지다.
class _CheckLine extends StatelessWidget {
  final String label;
  final bool value;
  final String? errorText;
  final ValueChanged<bool> onChanged;
  const _CheckLine({
    required this.label,
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final p = ReloPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          checked: value,
          label: label,
          excludeSemantics: true,
          child: InkWell(
            onTap: () => onChanged(!value),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: value,
                      activeColor: p.brand,
                      side: BorderSide(color: p.subtle, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      onChanged: (v) => onChanged(v ?? false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: p.ink,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: Text(
              errorText!,
              style: TextStyle(fontSize: 12, color: p.danger, height: 1.4),
            ),
          ),
      ],
    );
  }
}
