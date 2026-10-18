import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kazzi_credit/app.dart';
import 'package:kazzi_credit/core/router/app_router.dart';
import 'package:kazzi_credit/core/storage/demo_data_version.dart';
import 'package:kazzi_credit/core/storage/key_value_store.dart';
import 'package:kazzi_credit/features/auth/application/auth_controller.dart';
import 'package:kazzi_credit/features/auth/data/auth_repository.dart';
import 'package:kazzi_credit/features/cards/application/cards_controller.dart';
import 'package:kazzi_credit/features/cards/data/card_repository.dart';
import 'package:kazzi_credit/features/cards/data/card_vault.dart';
import 'package:kazzi_credit/features/cards/data/mock_cards.dart';
import 'package:kazzi_credit/features/insights/application/insights_controller.dart';
import 'package:kazzi_credit/features/notifications/application/notification_center.dart';
import 'package:kazzi_credit/features/notifications/data/local_notifications.dart';
import 'package:kazzi_credit/features/notifications/data/notification_repository.dart';
import 'package:kazzi_credit/features/profile/application/profile_controller.dart';
import 'package:kazzi_credit/features/transactions/application/transactions_controller.dart';
import 'package:kazzi_credit/features/transactions/data/tx_edits_repository.dart';
import 'package:material_ui/material_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final store = SecureKeyValueStore();
  await migrateDemoData(store);
  final status = await AuthRepository(store).loadStatus();
  final profile = await ProfileController.load(store);

  final cardRepo = CardRepository(store);
  var cards = await cardRepo.load();
  if (cards == null) {
    // First run: start with the demo wallet.
    cards = mockCards(
      DateTime.now(),
      holder: profile == null || profile.isEmpty ? demoHolder : profile.name,
    );
    await CardVault(store).seedIfMissing(mockCardSecrets);
    await cardRepo.save(cards);
  }

  final txEdits = await TxEditsRepository(store).load();
  final liveTxs = await LiveTransactionsController.load(store);
  final budgets = await BudgetsController.load(store);
  final notificationRepo = NotificationRepository(store);
  final notifications = await notificationRepo.load();
  final notificationSettings = await notificationRepo.loadSettings();

  // Initialize early so a tap that cold-started the app isn't lost.
  final localNotifications = LocalNotifications();
  await localNotifications.initialize();
  final launchRoute = localNotifications.launchRoute;

  runApp(
    ProviderScope(
      overrides: [
        keyValueStoreProvider.overrideWithValue(store),
        initialAuthStatusProvider.overrideWithValue(status),
        initialCardsProvider.overrideWithValue(cards),
        initialProfileProvider.overrideWithValue(profile),
        initialTxEditsProvider.overrideWithValue(txEdits),
        initialLiveTransactionsProvider.overrideWithValue(liveTxs),
        initialBudgetsProvider.overrideWithValue(budgets),
        initialNotificationsProvider.overrideWithValue(notifications),
        initialNotificationSettingsProvider.overrideWithValue(
          notificationSettings,
        ),
        localNotificationsProvider.overrideWithValue(localNotifications),
        if (launchRoute != null && launchRoute.startsWith('/'))
          initialLocationProvider.overrideWithValue(launchRoute),
      ],
      child: const KazziApp(),
    ),
  );
}
