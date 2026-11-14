import 'package:flutter/material.dart';

import '../../core/i18n/relo_i18n.dart';
import '../../core/theme/relo_theme.dart';
import '../../shared/models/domain_models.dart';
import '../../shared/state/relo_store.dart';
import '../../shared/widgets/relo_icons.dart';
import '../../shared/widgets/relo_primitives.dart';

/// @module features/claims/deadline_sheet
/// @purpose 판매자가 정한 기한(언제까지 반품 · 환불을 요청해야 하는지)을 적는 아래 시트.
///          마감 알림은 이 날짜를 보고 맞춘다. 서버는 기한을 "판매자가 쓴 말 그대로"와 함께만 받으므로
///          (지어낸 기한이 근거처럼 남지 않게) 두 칸을 같이 받는다.
///          저장했으면 true, 지웠으면 false, 그만뒀으면 null을 돌려준다.
Future<bool?> showDeadlineSheet(BuildContext context, ClaimView claim) {
  final palette = ReloPalette.of(context);
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: palette.canvas,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _DeadlineSheet(claim: claim),
  );
}

class _DeadlineSheet extends StatefulWidget {
  final ClaimView claim;
  const _DeadlineSheet({required this.claim});

  @override
  State<_DeadlineSheet> createState() => _DeadlineSheetState();
}

class _DeadlineSheetState extends State<_DeadlineSheet> {
  late final TextEditingController _dateCtrl =
      TextEditingController(text: widget.claim.deadline ?? '');
  late final TextEditingController _quoteCtrl =
      TextEditingController(text: widget.claim.deadlineQuote);
  String? _dateError;
  String? _quoteError;
  bool _saving = false;

  ReloStrings get _s => ReloScope.of(context).strings;

  @override
  void dispose() {
    _dateCtrl.dispose();
    _quoteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final current = DateTime.tryParse(_dateCtrl.text);
    final picked = await showDatePicker(
      context: context,
      initialDate: current != null && !current.isBefore(today)
          ? current
          : today.add(const Duration(days: 7)),
      firstDate: today,
      lastDate: DateTime(now.year + 2, 12, 31),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _dateCtrl.text = picked.toIso8601String().substring(0, 10);
      _dateError = null;
    });
  }

  Future<void> _save() async {
    final date = _dateCtrl.text.trim();
    final quote = _quoteCtrl.text.trim();
    setState(() {
      _dateError = date.isEmpty ? _s.dlErrDate : null;
      _quoteError = quote.isEmpty ? _s.dlErrQuote : null;
    });
    if (_dateError != null || _quoteError != null) return;
    setState(() => _saving = true);
    await ReloScope.of(context).setClaimDeadline(
      claimId: widget.claim.id,
      deadline: date,
      quote: quote,
    );
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _clear() async {
    setState(() => _saving = true);
    await ReloScope.of(context).setClaimDeadline(claimId: widget.claim.id);
    if (mounted) Navigator.pop(context, false);
  }

  @override
  Widget build(BuildContext context) {
    final p = ReloPalette.of(context);
    final hadDeadline = (widget.claim.deadline ?? '').isNotEmpty;
    return SafeArea(
      child: Padding(
        // 글자판이 올라와도 칸과 버튼이 가려지지 않게 올린다
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _s.dlTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: p.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _s.dlSub,
                style: TextStyle(fontSize: 13, color: p.muted, height: 1.45),
              ),
              const SizedBox(height: 18),
              ReloTextField(
                label: _s.dlDate,
                controller: _dateCtrl,
                readOnly: true,
                onTap: _pickDate,
                trailingIcon: ReloIcons.calendar,
                fillColor: p.raised,
                errorText: _dateError,
              ),
              const SizedBox(height: 12),
              ReloTextField(
                label: _s.dlQuote,
                hint: 'Return within 30 days of delivery',
                controller: _quoteCtrl,
                maxLines: 2,
                fillColor: p.raised,
                errorText: _quoteError,
                onChanged: (_) {
                  if (_quoteError != null) setState(() => _quoteError = null);
                },
              ),
              const SizedBox(height: 18),
              ReloButton(
                text: _saving ? _s.cmSaving : _s.cmSave,
                busy: _saving,
                onPressed: _saving ? null : _save,
              ),
              if (hadDeadline) ...[
                const SizedBox(height: 6),
                Center(
                  child: ReloTextAction(
                    label: _s.dlClear,
                    onTap: _saving ? null : _clear,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
