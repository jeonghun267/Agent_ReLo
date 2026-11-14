import 'package:flutter/services.dart';

import 'money_format.dart';

/// @module core/utils/input_rules
/// @purpose 입력칸에 칠 수 있는 글자와, 저장하기 전에 보는 검사를 한곳에 둔다.
///          금액은 숫자와 소수점 하나만 받고, 소수 자릿수는 통화에 맞춘다 (원·엔은 소수가 없다).

/// 금액 칸에 붙이는 제한: 숫자와 소수점 하나, 통화에 맞는 소수 자릿수까지만.
/// 붙여 넣은 값의 쉼표(1,234.50)는 빼고 받는다. 규칙에 맞지 않는 글자는 들어가지 않는다.
class MoneyInputFormatter extends TextInputFormatter {
  /// 소수 자릿수 (USD 2, KRW · JPY 0)
  final int digits;

  MoneyInputFormatter(this.digits);

  factory MoneyInputFormatter.of(String currency) =>
      MoneyInputFormatter(MoneyFormat.currencies[currency]?.digits ?? 2);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(',', '');
    final pattern = digits == 0
        ? RegExp(r'^\d{0,12}$')
        : RegExp('^\\d{0,12}(\\.\\d{0,$digits})?\$');
    if (!pattern.hasMatch(text)) return oldValue;
    if (text == newValue.text) return newValue;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class InputRules {
  InputRules._();

  /// 금액으로 읽는다. 0보다 큰 숫자가 아니면 null.
  static double? amount(String text) {
    final value = double.tryParse(text.trim().replaceAll(',', ''));
    if (value == null || value <= 0 || value.isNaN || value.isInfinite) {
      return null;
    }
    return value;
  }

  /// 통화를 바꿨을 때 금액 글자를 그 통화에 맞춘다.
  /// 소수가 없는 통화(원 · 엔)면 소수점 아래를 떼어 내고, 있으면 자릿수를 넘는 부분만 자른다.
  static String fitCurrency(String text, String currency) {
    final digits = MoneyFormat.currencies[currency]?.digits ?? 2;
    final clean = text.trim().replaceAll(',', '');
    final dot = clean.indexOf('.');
    if (dot < 0) return clean;
    if (digits == 0) return clean.substring(0, dot);
    final end = dot + 1 + digits;
    return end < clean.length ? clean.substring(0, end) : clean;
  }

  /// 이메일 모양인지 (정확한 검증은 서버가 한다. 여기서는 빠뜨린 @ · 점을 잡는다)
  static bool email(String text) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text.trim());

  /// YYYY-MM-DD 모양의 실제 날짜인지
  static bool isoDate(String text) {
    final t = text.trim();
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(t)) return false;
    final date = DateTime.tryParse(t);
    // "2026-02-31"처럼 달력에 없는 날은 다른 날로 바뀌어 읽히므로 다시 맞춰 본다
    return date != null && date.toIso8601String().substring(0, 10) == t;
  }
}
