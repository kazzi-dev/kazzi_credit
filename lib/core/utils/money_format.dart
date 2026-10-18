import 'package:intl/intl.dart';

abstract final class MoneyFormat {
  /// Real minus sign; reads better than a hyphen next to digits.
  static const minus = '−';

  static final Map<String, NumberFormat> _cache = {};

  static NumberFormat _formatter(String currency, String? locale) =>
      _cache.putIfAbsent(
        '$currency|$locale',
        () => NumberFormat.simpleCurrency(name: currency, locale: locale),
      );

  /// `1234.5` → `₱1,234.50`. With [signed], adds `+` / `−`.
  static String format(
    num amount, {
    String currency = 'PHP',
    String? locale,
    bool signed = false,
  }) {
    final body = _formatter(currency, locale).format(amount.abs());
    if (amount < 0) return '$minus$body';
    if (signed && amount > 0) return '+$body';
    return body;
  }

  /// Splits a formatted amount into whole part and cents, e.g.
  /// `₱12,480` and `.50`, so cents can be styled smaller.
  static (String whole, String cents) split(
    num amount, {
    String currency = 'PHP',
    String? locale,
    bool signed = false,
  }) {
    final text = format(
      amount,
      currency: currency,
      locale: locale,
      signed: signed,
    );
    final sep = _formatter(currency, locale).symbols.DECIMAL_SEP;
    final i = text.lastIndexOf(sep);
    if (i == -1) return (text, '');
    return (text.substring(0, i), text.substring(i));
  }
}
