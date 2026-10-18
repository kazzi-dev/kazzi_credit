import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazzi_credit/app.dart';
import 'package:kazzi_credit/core/router/routes.dart';
import 'package:kazzi_credit/features/auth/data/auth_repository.dart';
import 'package:kazzi_credit/features/cards/application/cards_controller.dart';
import 'package:kazzi_credit/features/notifications/application/notification_center.dart';
import 'package:kazzi_credit/features/notifications/domain/app_notification.dart';
import 'package:kazzi_credit/features/transactions/application/transactions_controller.dart';

import '../../helpers/fakes.dart';

Future<(ProviderContainer, FakeAlertNotifier)> _open(
  WidgetTester tester,
) async {
  final store = InMemoryKeyValueStore();
  final alerts = FakeAlertNotifier();
  await testRepository(store).setPin('482915');
  await pumpKazziApp(
    tester,
    store: store,
    alerts: alerts,
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
  return (container, alerts);
}

void main() {
  testWidgets('bell shows unread count; mark all read clears it', (
    tester,
  ) async {
    final (container, _) = await _open(tester);
    // First run seeds recent purchase alerts, two of them unread.
    expect(container.read(unreadCountProvider), 2);

    await tester.tap(find.byTooltip('Notifications, 2 unread'));
    await settle(tester);
    expect(find.text('Notifications'), findsOneWidget);

    await tester.tap(find.text('Mark all read'));
    await settle(tester);
    expect(container.read(unreadCountProvider), 0);
  });

  testWidgets('a live purchase adds the transaction and raises an alert', (
    tester,
  ) async {
    final (container, alerts) = await _open(tester);
    final before = container.read(unreadCountProvider);

    final tx = container
        .read(liveSimulatorProvider)
        .simulateOnce(suspicious: false)!;
    await settle(tester);

    expect(container.read(transactionByIdProvider(tx.id)), isNotNull);
    expect(container.read(unreadCountProvider), before + 1);
    expect(alerts.shown.single.txId, tx.id);
    expect(
      find.byTooltip('Notifications, ${before + 1} unread'),
      findsOneWidget,
    );
  });

  testWidgets('quiet hours keep the alert in the list but skip the banner', (
    tester,
  ) async {
    final (container, alerts) = await _open(tester);
    final now = container.read(clockProvider)();
    final minute = now.hour * 60 + now.minute;
    container
        .read(notificationSettingsProvider.notifier)
        .update(
          (s) => s.copyWith(
            quietHoursEnabled: true,
            quietStartMinutes: (minute - 60) % 1440,
            quietEndMinutes: (minute + 60) % 1440,
          ),
        );

    final tx = container.read(liveSimulatorProvider).simulateOnce()!;
    await settle(tester);

    expect(alerts.shown, isEmpty);
    expect(
      container.read(notificationCenterProvider).any((n) => n.txId == tx.id),
      isTrue,
    );
  });

  testWidgets('"Freeze card" on a suspicious alert freezes the card', (
    tester,
  ) async {
    final (container, _) = await _open(tester);
    final tx = container
        .read(liveSimulatorProvider)
        .simulateOnce(suspicious: true)!;
    await settle(tester);

    await tester.tap(find.byTooltip(RegExp('Notifications')));
    await settle(tester);
    expect(find.text('Was this you?'), findsOneWidget);

    await tester.tap(find.text('Freeze card'));
    await settle(tester);

    final card = container
        .read(cardsProvider)
        .firstWhere((c) => c.id == tx.cardId);
    expect(card.frozen, isTrue);
    expect(find.text('Was this you?'), findsOneWidget); // still listed, read
    expect(find.text('Freeze card'), findsNothing);
  });

  testWidgets('tapping a notification opens its transaction', (tester) async {
    final (container, _) = await _open(tester);
    await tester.tap(find.byTooltip(RegExp('Notifications')));
    await settle(tester);

    final first = container.read(notificationCenterProvider).first;
    await tester.tap(find.text(first.title));
    await settle(tester);

    expect(find.text('Paid with'), findsOneWidget);
    expect(
      container
          .read(notificationCenterProvider)
          .firstWhere((n) => n.id == first.id)
          .read,
      isTrue,
    );
  });

  testWidgets('swipe to dismiss, with undo', (tester) async {
    final (container, _) = await _open(tester);
    await tester.tap(find.byTooltip(RegExp('Notifications')));
    await settle(tester);
    final count = container.read(notificationCenterProvider).length;
    final first = container.read(notificationCenterProvider).first;

    await tester.drag(find.text(first.title), const Offset(-500, 0));
    await settle(tester);
    expect(container.read(notificationCenterProvider).length, count - 1);

    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect(container.read(notificationCenterProvider).first.id, first.id);
  });

  testWidgets('an OS notification tap deep-links into the app', (tester) async {
    final (container, alerts) = await _open(tester);
    final tx = container.read(transactionsProvider).first;

    alerts.tapController.add(AppRoutes.transactionDetail(tx.id));
    await settle(tester);

    expect(find.text('Paid with'), findsOneWidget);
    expect(find.text(tx.merchant), findsWidgets);
  });

  testWidgets('settings: security alerts are locked on', (tester) async {
    final (container, _) = await _open(tester);
    await tester.tap(find.text('Profile'));
    await settle(tester);
    await tester.tap(find.text('Notifications'));
    await settle(tester);

    expect(find.text('Always on to keep your account safe'), findsOneWidget);
    await tester.tap(find.text(NotificationType.cardFrozen.label));
    await settle(tester);
    expect(
      container
          .read(notificationSettingsProvider)
          .isEnabled(NotificationType.cardFrozen),
      isFalse,
    );
  });
}
