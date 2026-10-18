import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

enum BiometricKind { face, fingerprint, generic }

/// What the device can do. `kind == null` means biometrics can't be used,
/// either for lack of hardware or because nothing is enrolled.
class BiometricAvailability {
  const BiometricAvailability({this.kind, this.hasHardware = false});

  static const none = BiometricAvailability();

  final BiometricKind? kind;
  final bool hasHardware;

  bool get isAvailable => kind != null;

  /// "Face ID", "fingerprint"… for button labels and copy.
  String get label => switch (kind) {
    BiometricKind.face => 'Face ID',
    BiometricKind.fingerprint => 'fingerprint',
    _ => 'biometrics',
  };
}

abstract interface class BiometricService {
  Future<BiometricAvailability> availability();

  /// Resolves to `true` only on a successful scan. Cancels and errors
  /// resolve to `false` — the PIN is always the fallback.
  Future<bool> authenticate(String reason);
}

class LocalAuthBiometricService implements BiometricService {
  LocalAuthBiometricService([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<BiometricAvailability> availability() async {
    try {
      final hasHardware = await _auth.canCheckBiometrics;
      if (!hasHardware) return BiometricAvailability.none;
      final enrolled = await _auth.getAvailableBiometrics();
      if (enrolled.isEmpty) {
        return const BiometricAvailability(hasHardware: true);
      }
      final kind = enrolled.contains(BiometricType.face)
          ? BiometricKind.face
          : enrolled.contains(BiometricType.fingerprint)
          ? BiometricKind.fingerprint
          : BiometricKind.generic;
      return BiometricAvailability(kind: kind, hasHardware: true);
    } on PlatformException {
      return BiometricAvailability.none;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
