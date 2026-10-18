import 'package:kazzi_credit/features/cards/domain/card_network.dart';

/// Validation for the add-card form. Each returns a user-facing error, or
/// null when the value is fine. Messages say how to fix, not just "invalid".
abstract final class CardValidation {
  static String digitsOnly(String s) => s.replaceAll(RegExp(r'\D'), '');

  static String? number(String input) {
    final d = digitsOnly(input);
    if (d.isEmpty) return 'Enter the card number';
    final network = CardNetwork.detect(d);
    if (network == CardNetwork.unknown && d.length >= 4) {
      return 'We support Visa, Mastercard, Amex and Discover';
    }
    if (d.length < network.numberLength) return 'Card number is incomplete';
    if (!passesLuhn(d)) {
      return "That number doesn't look right. Check for typos.";
    }
    return null;
  }

  /// [input] is `MM/YY`.
  static String? expiry(String input, DateTime now) {
    final parsed = parseExpiry(input);
    if (input.trim().isEmpty) return 'Enter the expiry date';
    if (parsed == null) return 'Use the MM/YY format';
    final (month, year) = parsed;
    if (month < 1 || month > 12) return 'Month must be between 01 and 12';
    // Cards are valid through the last day of their expiry month.
    final firstDayAfter = DateTime(year, month + 1);
    if (!now.isBefore(firstDayAfter)) return 'This card has expired';
    if (year > now.year + 20) return 'Check the expiry year';
    return null;
  }

  /// `MM/YY` → (month, four-digit year), or null if incomplete.
  static (int, int)? parseExpiry(String input) {
    final d = digitsOnly(input);
    if (d.length != 4) return null;
    return (int.parse(d.substring(0, 2)), 2000 + int.parse(d.substring(2)));
  }

  static String? cvv(String input, CardNetwork network) {
    final d = digitsOnly(input);
    if (d.isEmpty) return 'Enter the security code';
    if (d.length != network.cvvLength) {
      return 'Needs ${network.cvvLength} digits';
    }
    return null;
  }

  static String? holder(String input) {
    final name = input.trim();
    if (name.isEmpty) return 'Enter the name on the card';
    if (name.length < 2) return 'Name is too short';
    if (name.length > 26) return 'Use the name as printed (26 characters max)';
    if (RegExp(r'\d').hasMatch(name)) return "Names can't contain numbers";
    return null;
  }

  static String? nickname(String input) =>
      input.trim().length > 20 ? 'Keep it under 20 characters' : null;

  static String? creditLimit(String input) {
    final d = digitsOnly(input);
    if (d.isEmpty) return null; // optional
    final value = int.parse(d);
    if (value > 1000000) return 'That limit looks too high';
    return null;
  }
}
