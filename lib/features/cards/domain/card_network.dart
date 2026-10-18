enum CardNetwork {
  visa('Visa'),
  mastercard('Mastercard'),
  amex('American Express'),
  discover('Discover'),
  unknown('Card');

  CardNetwork(this.label);

  final String label;

  /// Detects the network from the leading digits (IIN ranges).
  static CardNetwork detect(String digits) {
    final d = digits.replaceAll(RegExp(r'\D'), '');
    if (d.isEmpty) return unknown;
    if (d.startsWith('4')) return visa;
    if (RegExp('^3[47]').hasMatch(d)) return amex;
    if (RegExp('^(6011|65|64[4-9])').hasMatch(d)) return discover;
    if (RegExp('^5[1-5]').hasMatch(d)) return mastercard;
    if (d.length >= 4) {
      final prefix = int.parse(d.substring(0, 4));
      if (prefix >= 2221 && prefix <= 2720) return mastercard;
    }
    return unknown;
  }

  int get cvvLength => this == amex ? 4 : 3;

  int get numberLength => this == amex ? 15 : 16;

  /// Digit groups for display: 4-6-5 for Amex, 4-4-4-4 otherwise.
  List<int> get groups => this == amex ? const [4, 6, 5] : const [4, 4, 4, 4];

  String format(String digits) {
    final d = digits.replaceAll(RegExp(r'\D'), '');
    final out = StringBuffer();
    var i = 0;
    for (final g in groups) {
      if (i >= d.length) break;
      if (out.isNotEmpty) out.write(' ');
      final end = (i + g).clamp(0, d.length);
      out.write(d.substring(i, end));
      i = end;
    }
    return out.toString();
  }
}

/// Luhn checksum — catches typos in a card number before saving.
bool passesLuhn(String digits) {
  final d = digits.replaceAll(RegExp(r'\D'), '');
  if (d.length < 12) return false;
  var sum = 0;
  var doubleIt = false;
  for (var i = d.length - 1; i >= 0; i--) {
    var n = d.codeUnitAt(i) - 48;
    if (doubleIt) {
      n *= 2;
      if (n > 9) n -= 9;
    }
    sum += n;
    doubleIt = !doubleIt;
  }
  return sum % 10 == 0;
}
