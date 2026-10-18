import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:kazzi_credit/features/cards/domain/card_network.dart';

/// Groups digits as the user types (4-4-4-4, or 4-6-5 for Amex) and caps
/// the length for the detected network. Keeps the caret next to the same
/// digit, so editing in the middle doesn't jump to the end.
class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final network = CardNetwork.detect(digits);
    final max = network == CardNetwork.unknown ? 16 : network.numberLength;
    if (digits.length > max) digits = digits.substring(0, max);

    final caretDigits = _digitsBefore(newValue.text, newValue.selection.end);
    final text = network.format(digits);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(
        offset: _offsetForDigits(text, caretDigits.clamp(0, digits.length)),
      ),
    );
  }

  static int _digitsBefore(String text, int offset) {
    final end = offset.clamp(0, text.length);
    return text.substring(0, end).replaceAll(RegExp(r'\D'), '').length;
  }

  static int _offsetForDigits(String text, int digits) {
    if (digits == 0) return 0;
    var seen = 0;
    for (var i = 0; i < text.length; i++) {
      if (RegExp(r'\d').hasMatch(text[i])) seen++;
      if (seen == digits) return i + 1;
    }
    return text.length;
  }
}

/// `MM/YY` with the slash added automatically. Typing "4" becomes "04/".
class ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final deleting = newValue.text.length < oldValue.text.length;
    if (digits.length == 1 && int.parse(digits) > 1 && !deleting) {
      digits = '0$digits';
    }
    if (digits.length > 4) digits = digits.substring(0, 4);

    final String text;
    if (digits.length > 2) {
      text = '${digits.substring(0, 2)}/${digits.substring(2)}';
    } else if (digits.length == 2 && !deleting) {
      text = '$digits/';
    } else {
      text = digits;
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Whole-dollar amounts with thousands separators: 12000 → 12,000.
class ThousandsFormatter extends TextInputFormatter {
  static final _format = NumberFormat.decimalPattern('en_US');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 7) digits = digits.substring(0, 7);
    final text = digits.isEmpty ? '' : _format.format(int.parse(digits));
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
