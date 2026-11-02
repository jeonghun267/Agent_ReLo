import 'dart:math' as math;

/// 8개국 다중 통화(USD, EUR, GBP, JPY, CNY, KRW, CAD, AUD) 정밀 계산 및 포맷팅 유틸리티
/// 부동소수점 오차를 방지하기 위해 백엔드와 동일하게 Minor Unit(센트/원) 정수 단위를 사용합니다.
class CurrencySpec {
  final String code;
  final String symbol;
  final int digits;
  final String labelKo;

  const CurrencySpec({
    required this.code,
    required this.symbol,
    required this.digits,
    required this.labelKo,
  });
}

class MoneyFormat {
  static const Map<String, CurrencySpec> currencies = {
    'USD': CurrencySpec(
      code: 'USD',
      symbol: r'$',
      digits: 2,
      labelKo: '미국 달러 (USD)',
    ),
    'KRW': CurrencySpec(
      code: 'KRW',
      symbol: '₩',
      digits: 0,
      labelKo: '대한민국 원 (KRW)',
    ),
    'JPY': CurrencySpec(
      code: 'JPY',
      symbol: '¥',
      digits: 0,
      labelKo: '일본 엔 (JPY)',
    ),
    'CNY': CurrencySpec(
      code: 'CNY',
      symbol: '¥',
      digits: 2,
      labelKo: '중국 위안 (CNY)',
    ),
    'EUR': CurrencySpec(
      code: 'EUR',
      symbol: '€',
      digits: 2,
      labelKo: '유로 (EUR)',
    ),
    'GBP': CurrencySpec(
      code: 'GBP',
      symbol: '£',
      digits: 2,
      labelKo: '영국 파운드 (GBP)',
    ),
    'CAD': CurrencySpec(
      code: 'CAD',
      symbol: r'CA$',
      digits: 2,
      labelKo: '캐나다 달러 (CAD)',
    ),
    'AUD': CurrencySpec(
      code: 'AUD',
      symbol: r'A$',
      digits: 2,
      labelKo: '호주 달러 (AUD)',
    ),
  };

  static int digitsOf(String currency) =>
      currencies[currency]?.digits ??
      ((currency == 'KRW' || currency == 'JPY') ? 0 : 2);

  static String symbolOf(String currency) =>
      currencies[currency]?.symbol ?? '$currency ';

  static double minorToMajor(int minor, String currency) {
    final digits = digitsOf(currency);
    return minor / math.pow(10, digits);
  }

  static int decimalStringToMinor(String input, String currency) {
    final cleaned = input.replaceAll(',', '').trim();
    final parsed = double.tryParse(cleaned) ?? 0.0;
    final digits = digitsOf(currency);
    return (parsed * math.pow(10, digits)).round();
  }

  static String minorToDecimalString(int? minor, String currency) {
    if (minor == null) return '';
    final digits = digitsOf(currency);
    final major = minorToMajor(minor, currency);
    return major.toStringAsFixed(digits);
  }

  static String _addCommas(String intPart) {
    final negative = intPart.startsWith('-');
    final digits = negative ? intPart.substring(1) : intPart;
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[i]);
    }
    return negative ? '-$buffer' : buffer.toString();
  }

  /// 정수부와 소수부를 분리하여 토스 스타일 Tabular 타이포그래피로 렌더링하기 위한 파츠
  static ({String symbol, String whole, String fraction}) splitParts(
    int minor,
    String currency,
  ) {
    final digits = digitsOf(currency);
    final symbol = symbolOf(currency);
    final majorStr = minorToMajor(minor, currency).toStringAsFixed(digits);
    if (digits == 0) {
      return (symbol: symbol, whole: _addCommas(majorStr), fraction: '');
    }
    final parts = majorStr.split('.');
    return (
      symbol: symbol,
      whole: _addCommas(parts[0]),
      fraction: parts.length > 1 ? '.${parts[1]}' : '',
    );
  }

  static String formatMinor(int minor, String currency) {
    final parts = splitParts(minor, currency);
    return '${parts.symbol}${parts.whole}${parts.fraction}';
  }

  /// ISO 날짜(YYYY-MM-DD 또는 ISO8601)를 읽기 쉬운 한국어 날짜로 변환
  static String formatKoreanDate(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    final short = iso.length >= 10 ? iso.substring(0, 10) : iso;
    final parts = short.split('-');
    if (parts.length == 3) {
      final y = parts[0];
      final m = int.tryParse(parts[1]) ?? 1;
      final d = int.tryParse(parts[2]) ?? 1;
      return '$y년 $m월 $d일';
    }
    return short;
  }

  static String formatDateKo(String? iso) => formatKoreanDate(iso);
}
