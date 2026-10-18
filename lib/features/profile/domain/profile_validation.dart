abstract final class ProfileValidation {
  static String digits(String s) => s.replaceAll(RegExp(r'\D'), '');

  static String? name(String input) {
    final n = input.trim();
    if (n.isEmpty) return 'Enter your name';
    if (n.length < 2) return 'Name is too short';
    if (n.length > 40) return 'Keep it under 40 characters';
    if (RegExp(r'\d').hasMatch(n)) return "Names can't contain numbers";
    return null;
  }

  /// Optional. PH mobile numbers are 10 digits after +63 and start with 9.
  static String? mobile(String input) {
    final d = digits(input);
    if (d.isEmpty) return null;
    if (!d.startsWith('9')) return 'Mobile numbers start with 9, e.g. 917…';
    if (d.length != 10) return 'Enter all 10 digits after +63';
    return null;
  }

  /// Optional.
  static String? email(String input) {
    final e = input.trim();
    if (e.isEmpty) return null;
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e)) {
      return 'Check the email address';
    }
    return null;
  }
}
