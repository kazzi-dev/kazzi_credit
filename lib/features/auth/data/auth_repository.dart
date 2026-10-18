import 'package:flutter/foundation.dart';
import 'package:kazzi_credit/core/storage/key_value_store.dart';
import 'package:kazzi_credit/features/auth/data/pin_hasher.dart';

@immutable
class AuthStatus {
  const AuthStatus({
    required this.onboarded,
    required this.hasPin,
    required this.biometricsEnabled,
  });

  static const fresh = AuthStatus(
    onboarded: false,
    hasPin: false,
    biometricsEnabled: false,
  );

  final bool onboarded;
  final bool hasPin;
  final bool biometricsEnabled;
}

sealed class PinCheck {
  const PinCheck();
}

class PinCorrect extends PinCheck {
  const PinCorrect();
}

class PinWrong extends PinCheck {
  const PinWrong(this.attemptsLeft);
  final int attemptsLeft;
}

class PinLockedOut extends PinCheck {
  const PinLockedOut(this.until);
  final DateTime until;
}

class AuthRepository {
  AuthRepository(
    this._store, {
    this.hasher = const PinHasher(),
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now;

  static const maxAttempts = 5;
  static const lockoutDuration = Duration(seconds: 30);

  static const _kOnboarded = 'auth.onboarded';
  static const _kPinHash = 'auth.pin_hash';
  static const _kPinSalt = 'auth.pin_salt';
  static const _kBiometrics = 'auth.biometrics';
  static const _kFailed = 'auth.failed_attempts';
  static const _kLockedUntil = 'auth.locked_until';

  final KeyValueStore _store;
  final PinHasher hasher;
  final DateTime Function() _now;

  Future<AuthStatus> loadStatus() async {
    final results = await Future.wait([
      _store.read(_kOnboarded),
      _store.read(_kPinHash),
      _store.read(_kBiometrics),
    ]);
    return AuthStatus(
      onboarded: results[0] == 'true',
      hasPin: results[1] != null,
      biometricsEnabled: results[2] == 'true',
    );
  }

  Future<void> setPin(String pin) async {
    final salt = hasher.newSalt();
    final hash = await hasher.hash(pin, salt);
    await _store.write(_kPinSalt, salt);
    await _store.write(_kPinHash, hash);
    await _clearAttempts();
  }

  /// Checks [pin], counting failures. After [maxAttempts] wrong entries the
  /// PIN is locked for [lockoutDuration]; the counter survives restarts.
  Future<PinCheck> verifyPin(String pin) async {
    final lockedUntil = await lockedUntilTime();
    if (lockedUntil != null) return PinLockedOut(lockedUntil);

    final salt = await _store.read(_kPinSalt);
    final hash = await _store.read(_kPinHash);
    if (salt == null || hash == null) return const PinWrong(0);

    if (await hasher.verify(pin, salt, hash)) {
      await _clearAttempts();
      return const PinCorrect();
    }

    final failed = int.parse(await _store.read(_kFailed) ?? '0') + 1;
    if (failed >= maxAttempts) {
      final until = _now().add(lockoutDuration);
      await _store.write(_kLockedUntil, until.toIso8601String());
      await _store.write(_kFailed, '0');
      return PinLockedOut(until);
    }
    await _store.write(_kFailed, '$failed');
    return PinWrong(maxAttempts - failed);
  }

  /// Non-null while a lockout is active.
  Future<DateTime?> lockedUntilTime() async {
    final raw = await _store.read(_kLockedUntil);
    if (raw == null) return null;
    final until = DateTime.parse(raw);
    if (_now().isBefore(until)) return until;
    await _store.delete(_kLockedUntil);
    return null;
  }

  Future<void> setBiometricsEnabled({required bool enabled}) =>
      _store.write(_kBiometrics, '$enabled');

  Future<void> completeOnboarding() => _store.write(_kOnboarded, 'true');

  /// Wipes everything — used by "Forgot PIN".
  Future<void> reset() => _store.clear();

  Future<void> _clearAttempts() async {
    await _store.delete(_kFailed);
    await _store.delete(_kLockedUntil);
  }
}
