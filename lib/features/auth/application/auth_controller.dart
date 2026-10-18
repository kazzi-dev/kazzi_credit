import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kazzi_credit/core/notifications/notification_permission_service.dart';
import 'package:kazzi_credit/core/storage/key_value_store.dart';
import 'package:kazzi_credit/features/auth/data/auth_repository.dart';
import 'package:kazzi_credit/features/auth/data/biometric_service.dart';
import 'package:kazzi_credit/features/notifications/data/local_notifications.dart';

final keyValueStoreProvider = Provider<KeyValueStore>(
  (ref) => SecureKeyValueStore(),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(keyValueStoreProvider)),
);

final biometricServiceProvider = Provider<BiometricService>(
  (ref) => LocalAuthBiometricService(),
);

final biometricAvailabilityProvider = FutureProvider<BiometricAvailability>(
  (ref) => ref.watch(biometricServiceProvider).availability(),
);

final notificationPermissionServiceProvider =
    Provider<NotificationPermissionService>(
      (ref) => ref.watch(localNotificationsProvider),
    );

/// Read from secure storage in `main()` before the first frame, so routing
/// can decide onboarding vs. lock screen synchronously.
final initialAuthStatusProvider = Provider<AuthStatus>(
  (ref) => throw UnimplementedError('Override in main()'),
);

/// How long the app may sit in the background before it relocks.
// TODO(kazzi): make configurable from Settings.
final autoLockAfterProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 30),
);

@immutable
class AuthState {
  const AuthState({
    required this.onboarded,
    required this.hasPin,
    required this.biometricsEnabled,
    required this.unlocked,
  });

  final bool onboarded;
  final bool hasPin;
  final bool biometricsEnabled;

  /// In-memory only: every cold start begins locked.
  final bool unlocked;

  AuthState copyWith({
    bool? onboarded,
    bool? hasPin,
    bool? biometricsEnabled,
    bool? unlocked,
  }) => AuthState(
    onboarded: onboarded ?? this.onboarded,
    hasPin: hasPin ?? this.hasPin,
    biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
    unlocked: unlocked ?? this.unlocked,
  );
}

class AuthController extends Notifier<AuthState> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    final status = ref.watch(initialAuthStatusProvider);
    return AuthState(
      onboarded: status.onboarded,
      hasPin: status.hasPin,
      biometricsEnabled: status.biometricsEnabled,
      unlocked: false,
    );
  }

  Future<void> createPin(String pin) async {
    await _repo.setPin(pin);
    state = state.copyWith(hasPin: true, unlocked: true);
  }

  Future<PinCheck> unlockWithPin(String pin) async {
    final result = await _repo.verifyPin(pin);
    if (result is PinCorrect) state = state.copyWith(unlocked: true);
    return result;
  }

  Future<bool> unlockWithBiometrics() async {
    if (!state.biometricsEnabled) return false;
    // A biometric unlock must not bypass an active PIN lockout.
    if (await _repo.lockedUntilTime() != null) return false;
    final ok = await ref
        .read(biometricServiceProvider)
        .authenticate('Unlock Kazzi Credit');
    if (ok) state = state.copyWith(unlocked: true);
    return ok;
  }

  Future<DateTime?> lockedUntil() => _repo.lockedUntilTime();

  Future<void> setBiometricsEnabled({required bool enabled}) async {
    await _repo.setBiometricsEnabled(enabled: enabled);
    state = state.copyWith(biometricsEnabled: enabled);
  }

  Future<void> completeOnboarding() async {
    await _repo.completeOnboarding();
    state = state.copyWith(onboarded: true);
  }

  void lock() {
    if (state.onboarded && state.unlocked) {
      state = state.copyWith(unlocked: false);
    }
  }

  /// "Forgot PIN": wipe the device and start onboarding again.
  Future<void> resetApp() async {
    await _repo.reset();
    state = const AuthState(
      onboarded: false,
      hasPin: false,
      biometricsEnabled: false,
      unlocked: false,
    );
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
