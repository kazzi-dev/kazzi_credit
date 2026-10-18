// Renders README screenshots from the real app with demo data.
//   flutter test tool/screenshots/screenshots_test.dart --update-goldens
// Output: docs/screenshots/*.png
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazzi_credit/app.dart';
import 'package:kazzi_credit/core/theme/theme_mode_controller.dart';
import 'package:kazzi_credit/features/auth/data/auth_repository.dart';
import 'package:kazzi_credit/features/notifications/application/notification_center.dart';
import 'package:kazzi_credit/features/profile/application/profile_controller.dart';
import 'package:kazzi_credit/features/transactions/presentation/widgets/transaction_tile.dart';
import 'package:material_ui/material_ui.dart';

import '../../test/helpers/fakes.dart';

Future<void> _loadFonts() async {
  final sdk = File(Platform.resolvedExecutable)
      .parent
      .parent
      .parent
      .parent
      .parent
      .parent
      .path;
  final dir = '$sdk/bin/cache/artifacts/material_fonts';
  Future<ByteData> f(String n) async =>
      ByteData.sublistView(await File('$dir/$n').readAsBytes());
  final roboto = FontLoader('Roboto');
  for (final n in [
    'roboto-regular.ttf',
    'roboto-medium.ttf',
    'roboto-bold.ttf',
    'roboto-black.ttf',
    'roboto-italic.ttf',
    'roboto-blackitalic.ttf',
  ]) {
    roboto.addFont(f(n));
  }
  await roboto.load();
  await (FontLoader(
    'MaterialIcons',
  )..addFont(f('materialicons-regular.otf'))).load();
}

Future<void> _shot(WidgetTester tester, String name) => expectLater(
  find.byType(MaterialApp),
  matchesGoldenFile('../../docs/screenshots/$name.png'),
);

Future<ProviderContainer> _signedIn(WidgetTester tester) async {
  final store = InMemoryKeyValueStore();
  await testRepository(store).setPin('482915');
  await pumpKazziApp(
    tester,
    store: store,
    status: const AuthStatus(
      onboarded: true,
      hasPin: true,
      biometricsEnabled: false,
    ),
  );
  await enterPin(tester, '482915');
  final container = ProviderScope.containerOf(
    tester.element(find.byType(KazziApp)),
  );
  container
      .read(profileProvider.notifier)
      .save(
        container
            .read(profileProvider)
            .copyWith(
              name: 'Maria Santos',
              mobile: '9171234567',
              email: 'maria@email.com',
            ),
      );
  await settle(tester);
  return container;
}

void main() {
  setUpAll(_loadFonts);
  setUp(() => debugDisableShadows = false);

  testWidgets('welcome', (tester) async {
    await pumpKazziApp(tester, store: InMemoryKeyValueStore());
    await _shot(tester, '01_welcome');
    debugDisableShadows = true;
  });

  testWidgets('wallet', (tester) async {
    final container = await _signedIn(tester);
    await _shot(tester, '02_wallet');
    container.read(themeModeProvider.notifier).mode = ThemeMode.dark;
    await settle(tester);
    await _shot(tester, '03_wallet_dark');
    debugDisableShadows = true;
  });

  testWidgets('activity and detail', (tester) async {
    await _signedIn(tester);
    await tester.tap(find.text('Activity'));
    await settle(tester);
    await _shot(tester, '04_activity');
    await tester.tap(find.byType(TransactionTile).at(1));
    await settle(tester);
    await _shot(tester, '05_transaction');
    debugDisableShadows = true;
  });

  testWidgets('insights', (tester) async {
    await _signedIn(tester);
    await tester.tap(find.text('Insights'));
    await settle(tester);
    await _shot(tester, '06_insights');
    debugDisableShadows = true;
  });

  testWidgets('notifications', (tester) async {
    final container = await _signedIn(tester);
    container.read(liveSimulatorProvider).simulateOnce(suspicious: true);
    await settle(tester);
    await tester.tap(find.byTooltip(RegExp('Notifications')));
    await settle(tester);
    await _shot(tester, '07_notifications');
    debugDisableShadows = true;
  });

  testWidgets('add card', (tester) async {
    await _signedIn(tester);
    await tester.tap(find.text('+ Add card'));
    await settle(tester);
    await _shot(tester, '08_add_card');
    debugDisableShadows = true;
  });

  testWidgets('profile', (tester) async {
    await _signedIn(tester);
    await tester.tap(find.text('Profile'));
    await settle(tester);
    await _shot(tester, '09_profile');
    debugDisableShadows = true;
  });
}
