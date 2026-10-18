import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazzi_credit/app.dart';
import 'package:kazzi_credit/core/theme/theme_mode_controller.dart';
import 'package:kazzi_credit/features/auth/data/auth_repository.dart';
import 'package:kazzi_credit/features/auth/data/biometric_service.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';

const _onboarded = AuthStatus(
  onboarded: true,
  hasPin: true,
  biometricsEnabled: false,
);

void main() {
  Future<void> startOnboarding(
    WidgetTester tester, {
    String name = 'Maria Santos',
  }) async {
    expect(find.text('All your cards.\nOne calm place.'), findsOneWidget);
    await tester.tap(find.text('Get started'));
    await settle(tester);
    expect(find.text('What should we call you?'), findsOneWidget);
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('field-name')),
        matching: find.byType(TextField),
      ),
      name,
    );
    await tester.tap(find.text('Continue'));
    await settle(tester);
  }

  testWidgets('first launch: welcome → name → PIN → finish → wallet', (
    tester,
  ) async {
    final store = InMemoryKeyValueStore();
    final notifications = FakeNotificationPermissionService();
    await pumpKazziApp(tester, store: store, notifications: notifications);
    await startOnboarding(tester);

    expect(find.text('Create your PIN'), findsOneWidget);
    await enterPin(tester, '123456');
    expect(find.textContaining('easy to guess'), findsOneWidget);

    await enterPin(tester, '482915');
    expect(find.text('Confirm your PIN'), findsOneWidget);
    await enterPin(tester, '482915');

    expect(find.text('Almost done, Maria'), findsOneWidget);
    await tester.tap(find.text('Finish setup'));
    await settle(tester);

    expect(notifications.calls, 1);
    expect(find.text('Hi, Maria'), findsOneWidget);
    expect((await testRepository(store).loadStatus()).onboarded, isTrue);
  });

  testWidgets('name is required before continuing', (tester) async {
    await pumpKazziApp(tester, store: InMemoryKeyValueStore());
    await tester.tap(find.text('Get started'));
    await settle(tester);
    await tester.tap(find.text('Continue'));
    await settle(tester);
    expect(find.text('Enter your name'), findsOneWidget);
    expect(find.text('What should we call you?'), findsOneWidget);
  });

  testWidgets('mismatched confirmation restarts PIN creation', (tester) async {
    await pumpKazziApp(tester, store: InMemoryKeyValueStore());
    await startOnboarding(tester);

    await enterPin(tester, '482915');
    await enterPin(tester, '482916');

    expect(find.textContaining("didn't match"), findsOneWidget);
    expect(find.text('Create your PIN'), findsOneWidget);
  });

  testWidgets('lock screen rejects a wrong PIN and accepts the right one', (
    tester,
  ) async {
    final store = InMemoryKeyValueStore();
    await testRepository(store).setPin('482915');
    await pumpKazziApp(tester, store: store, status: _onboarded);

    expect(find.text('Enter your PIN to unlock'), findsOneWidget);
    await enterPin(tester, '000001');
    expect(find.text('Incorrect PIN. 4 attempts left.'), findsOneWidget);

    await enterPin(tester, '482915');
    expect(find.text('My cards'), findsOneWidget);
  });

  testWidgets('biometrics unlock automatically when enabled', (tester) async {
    final store = InMemoryKeyValueStore();
    await testRepository(store).setPin('482915');
    final bio = FakeBiometricService(
      available: const BiometricAvailability(
        kind: BiometricKind.face,
        hasHardware: true,
      ),
    );
    await pumpKazziApp(
      tester,
      store: store,
      biometrics: bio,
      status: const AuthStatus(
        onboarded: true,
        hasPin: true,
        biometricsEnabled: true,
      ),
    );

    expect(bio.calls, 1);
    expect(find.text('My cards'), findsOneWidget);
  });

  testWidgets('lock button relocks; theme toggle switches to dark', (
    tester,
  ) async {
    final store = InMemoryKeyValueStore();
    await testRepository(store).setPin('482915');
    await pumpKazziApp(tester, store: store, status: _onboarded);
    await enterPin(tester, '482915');

    await tester.tap(find.text('Profile'));
    await settle(tester);
    await tester.tap(find.text('Appearance'));
    await settle(tester);
    await tester.tap(find.text('Dark'));
    await settle(tester);
    await tester.tapAt(const Offset(20, 20)); // close the sheet
    await settle(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(KazziApp)),
    );
    expect(container.read(themeModeProvider), ThemeMode.dark);

    await tester.tap(find.text('Lock now'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your PIN to unlock'), findsOneWidget);
  });
}
