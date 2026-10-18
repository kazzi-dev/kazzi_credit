import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazzi_credit/app.dart';
import 'package:kazzi_credit/core/notifications/notification_permission_service.dart';
import 'package:kazzi_credit/core/storage/key_value_store.dart';
import 'package:kazzi_credit/features/auth/application/auth_controller.dart';
import 'package:kazzi_credit/features/auth/data/auth_repository.dart';
import 'package:kazzi_credit/features/auth/data/biometric_service.dart';
import 'package:kazzi_credit/features/auth/data/pin_hasher.dart';
import 'package:kazzi_credit/features/cards/data/card_vault.dart';
import 'package:kazzi_credit/features/cards/data/mock_cards.dart';
import 'package:kazzi_credit/features/notifications/application/notification_center.dart';
import 'package:kazzi_credit/features/notifications/data/local_notifications.dart';
import 'package:kazzi_credit/features/notifications/domain/app_notification.dart';
import 'package:material_ui/material_ui.dart';

class InMemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<void> clear() async => values.clear();
}

class FakeBiometricService implements BiometricService {
  FakeBiometricService({
    this.available = BiometricAvailability.none,
    this.succeeds = true,
  });

  final BiometricAvailability available;
  final bool succeeds;
  int calls = 0;

  @override
  Future<BiometricAvailability> availability() async => available;

  @override
  Future<bool> authenticate(String reason) async {
    calls++;
    return succeeds;
  }
}

class FakeNotificationPermissionService
    implements NotificationPermissionService {
  int calls = 0;

  @override
  Future<bool> request() async {
    calls++;
    return true;
  }
}

/// Cheap hash settings so tests stay fast and synchronous.
const testHasher = PinHasher(iterations: 10, runInIsolate: false);

AuthRepository testRepository(
  KeyValueStore store, {
  DateTime Function()? clock,
}) => AuthRepository(store, hasher: testHasher, clock: clock);

/// Pumps the whole app with fakes. Reduced motion is on, which also stops
/// looping animations so `pumpAndSettle` can finish.
Future<void> pumpKazziApp(
  WidgetTester tester, {
  required InMemoryKeyValueStore store,
  AuthStatus status = AuthStatus.fresh,
  FakeBiometricService? biometrics,
  FakeNotificationPermissionService? notifications,
  FakeAlertNotifier? alerts,
}) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  // iPhone 14-sized viewport, so screens lay out like on a phone.
  tester.view
    ..physicalSize = const Size(1170, 2532)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await CardVault(store).seedIfMissing(mockCardSecrets);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        keyValueStoreProvider.overrideWithValue(store),
        authRepositoryProvider.overrideWithValue(testRepository(store)),
        initialAuthStatusProvider.overrideWithValue(status),
        biometricServiceProvider.overrideWithValue(
          biometrics ?? FakeBiometricService(),
        ),
        notificationPermissionServiceProvider.overrideWithValue(
          notifications ?? FakeNotificationPermissionService(),
        ),
        alertNotifierProvider.overrideWithValue(alerts ?? FakeAlertNotifier()),
        simulatorEnabledProvider.overrideWithValue(false),
      ],
      child: const KazziApp(useGoogleFonts: false),
    ),
  );
  await settle(tester);
}

/// Taps digits on the on-screen PIN pad.
Future<void> enterPin(WidgetTester tester, String pin) async {
  for (final d in pin.split('')) {
    await tester.tap(find.bySemanticsLabel(d).last);
    await tester.pump();
  }
  // PIN screens wait briefly after the last digit before submitting.
  await tester.pump(const Duration(milliseconds: 200));
  await settle(tester);
}

/// pumpAndSettle, plus enough time for staggered entrance animations,
/// which wait on timers without scheduling frames.
Future<void> settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

/// Records shown alerts; push routes into [taps] to simulate a tap.
class FakeAlertNotifier implements AlertNotifier {
  final shown = <AppNotification>[];
  final tapController = StreamController<String>.broadcast();

  @override
  Stream<String> get taps => tapController.stream;

  @override
  Future<void> show(AppNotification notification) async =>
      shown.add(notification);
}
