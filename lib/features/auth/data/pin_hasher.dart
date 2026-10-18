import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// PBKDF2-HMAC-SHA256 for the 6-digit PIN. The PIN itself is never stored.
///
/// A 6-digit PIN has only 10^6 values, so the hash alone can't stop an
/// offline attack; the real protection is that the hash lives in the OS
/// keystore and the app enforces an attempt lockout. The iteration count
/// just makes each guess cost something.
class PinHasher {
  const PinHasher({this.iterations = 60000, this.runInIsolate = true});

  final int iterations;

  /// Tests turn this off: isolates don't complete inside widget tests'
  /// fake-async zone.
  final bool runInIsolate;

  String newSalt() {
    final random = Random.secure();
    return base64Encode(List<int>.generate(16, (_) => random.nextInt(256)));
  }

  /// Runs off the UI isolate so the keypad animation doesn't stutter.
  Future<String> hash(String pin, String salt) {
    final rounds = iterations;
    if (!runInIsolate) return Future.value(_pbkdf2(pin, salt, rounds));
    return Isolate.run(() => _pbkdf2(pin, salt, rounds));
  }

  Future<bool> verify(String pin, String salt, String expectedHash) async {
    final actual = await hash(pin, salt);
    return _constantTimeEquals(actual, expectedHash);
  }

  static String _pbkdf2(String pin, String salt, int iterations) {
    final hmac = Hmac(sha256, utf8.encode(pin));
    // Single 32-byte block: salt || INT(1).
    var u = hmac.convert([...base64Decode(salt), 0, 0, 0, 1]).bytes;
    final out = List<int>.of(u);
    for (var i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < out.length; j++) {
        out[j] ^= u[j];
      }
    }
    return base64Encode(out);
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
