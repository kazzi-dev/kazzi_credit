import 'package:flutter_test/flutter_test.dart';
import 'package:kazzi_credit/core/router/app_router.dart';
import 'package:kazzi_credit/features/auth/application/auth_controller.dart';
import 'package:kazzi_credit/features/onboarding/presentation/pin_setup_screen.dart';

AuthState _state({
  bool onboarded = true,
  bool hasPin = true,
  bool unlocked = false,
}) => AuthState(
  onboarded: onboarded,
  hasPin: hasPin,
  biometricsEnabled: false,
  unlocked: unlocked,
);

void main() {
  group('authRedirect', () {
    test('sends new users to onboarding', () {
      final s = _state(onboarded: false, hasPin: false);
      expect(authRedirect(s, Uri.parse('/home')), AppRoutes.onboarding);
      expect(authRedirect(s, Uri.parse(AppRoutes.onboarding)), isNull);
    });

    test('cannot skip PIN creation', () {
      final s = _state(onboarded: false, hasPin: false);
      expect(
        authRedirect(s, Uri.parse(AppRoutes.finishSetup)),
        AppRoutes.pinSetup,
      );
    });

    test('locks and remembers where the user was', () {
      final s = _state();
      expect(authRedirect(s, Uri.parse('/home')), AppRoutes.lock);
      expect(authRedirect(s, Uri.parse('/cards/1')), '/lock?from=%2Fcards%2F1');
    });

    test('returns to the remembered page after unlocking', () {
      final s = _state(unlocked: true);
      expect(authRedirect(s, Uri.parse('/lock?from=%2Fcards%2F1')), '/cards/1');
      expect(authRedirect(s, Uri.parse('/lock')), AppRoutes.home);
    });

    test('ignores non-local return paths', () {
      final s = _state(unlocked: true);
      expect(
        authRedirect(s, Uri.parse('/lock?from=%2F%2Fevil.com')),
        AppRoutes.home,
      );
    });
  });

  group('isWeakPin', () {
    test('rejects repeats, runs and common PINs', () {
      for (final pin in ['111111', '123456', '654321', '345678', '121212']) {
        expect(isWeakPin(pin), isTrue, reason: pin);
      }
    });

    test('accepts a random-looking PIN', () {
      expect(isWeakPin('482915'), isFalse);
    });
  });
}
