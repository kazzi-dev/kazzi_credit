import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kazzi_credit/features/auth/application/auth_controller.dart';
import 'package:kazzi_credit/features/cards/application/cards_controller.dart';
import 'package:kazzi_credit/features/cards/domain/payment_card.dart';
import 'package:kazzi_credit/features/notifications/data/local_notifications.dart';
import 'package:kazzi_credit/features/notifications/data/notification_repository.dart';
import 'package:kazzi_credit/features/notifications/domain/alert_rules.dart';
import 'package:kazzi_credit/features/notifications/domain/app_notification.dart';
import 'package:kazzi_credit/features/transactions/application/transactions_controller.dart';
import 'package:kazzi_credit/features/transactions/data/mock_transactions.dart';
import 'package:kazzi_credit/features/transactions/domain/card_transaction.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(ref.watch(keyValueStoreProvider)),
);

final alertNotifierProvider = Provider<AlertNotifier>(
  (ref) => ref.watch(localNotificationsProvider),
);

// ── Settings ───────────────────────────────────────────────────────────

final initialNotificationSettingsProvider = Provider<NotificationSettings>(
  (ref) => const NotificationSettings(),
);

class NotificationSettingsController extends Notifier<NotificationSettings> {
  @override
  NotificationSettings build() =>
      ref.watch(initialNotificationSettingsProvider);

  void update(NotificationSettings Function(NotificationSettings) change) {
    state = change(state);
    unawaited(ref.read(notificationRepositoryProvider).saveSettings(state));
  }

  void toggle(NotificationType type, {required bool enabled}) => update(
    (s) => s.copyWith(
      disabled: enabled
          ? ({...s.disabled}..remove(type))
          : {...s.disabled, type},
    ),
  );
}

final notificationSettingsProvider =
    NotifierProvider<NotificationSettingsController, NotificationSettings>(
      NotificationSettingsController.new,
    );

// ── Notification list ──────────────────────────────────────────────────

/// Loaded in `main()`; null on first run, which seeds a few demo alerts.
final initialNotificationsProvider = Provider<List<AppNotification>?>(
  (ref) => null,
);

/// Turns events (new purchases, card changes, upcoming due dates) into
/// notifications, keeps the in-app list, and raises OS alerts outside
/// quiet hours.
class NotificationCenter extends Notifier<List<AppNotification>> {
  @override
  List<AppNotification> build() {
    ref
      ..listen(cardsProvider, _onCardsChanged)
      ..listen(authControllerProvider.select((a) => a.onboarded), (
        wasOnboarded,
        onboarded,
      ) {
        if ((wasOnboarded ?? false) && !onboarded) state = const [];
      });
    unawaited(Future.microtask(checkDueDates));

    final loaded = ref.watch(initialNotificationsProvider);
    if (loaded != null) return loaded;
    final seeded = _seed();
    unawaited(ref.read(notificationRepositoryProvider).save(seeded));
    return seeded;
  }

  List<AppNotification> _seed() {
    final settings = ref.read(notificationSettingsProvider);
    final cards = {for (final c in ref.read(cardsProvider)) c.id: c};
    final recent = ref
        .read(transactionsProvider)
        .where((t) => !t.isRefund)
        .take(6)
        .toList();
    return [
      for (final (i, tx) in recent.indexed)
        ?alertForTransaction(
          tx,
          cards[tx.cardId],
          settings,
        )?.copyWith(read: i >= 2),
    ];
  }

  DateTime get _now => ref.read(clockProvider)();

  /// Adds [n] unless it's a duplicate. OS alert unless [silent] or quiet.
  void deliver(AppNotification n, {bool silent = false}) {
    final dup = state.any(
      (e) =>
          e.id == n.id || (n.dedupeKey != null && e.dedupeKey == n.dedupeKey),
    );
    if (dup) return;
    if (!ref.read(notificationSettingsProvider).isEnabled(n.type)) return;
    state = [n, ...state].take(NotificationRepository.maxStored).toList();
    _persist();
    if (!silent && !ref.read(notificationSettingsProvider).isQuiet(_now)) {
      unawaited(ref.read(alertNotifierProvider).show(n));
    }
  }

  void onNewTransaction(CardTransaction tx, {bool suspicious = false}) {
    final card = ref
        .read(cardsProvider)
        .where((c) => c.id == tx.cardId)
        .firstOrNull;
    final alert = alertForTransaction(
      tx,
      card,
      ref.read(notificationSettingsProvider),
      suspicious: suspicious,
    );
    if (alert != null) deliver(alert);
  }

  void checkDueDates() {
    for (final card in ref.read(cardsProvider)) {
      final alert = alertForDueDate(card, _now);
      if (alert != null) deliver(alert);
    }
  }

  void _onCardsChanged(List<PaymentCard>? before, List<PaymentCard> after) {
    if (before == null) return;
    final old = {for (final c in before) c.id: c};
    for (final card in after) {
      final prev = old[card.id];
      if (prev == null) continue;
      final limit = alertForLimit(prev, card, _now);
      if (limit != null) deliver(limit);
      // The user froze it themselves in the app, so no banner.
      final frozen = alertForFreeze(prev, card, _now);
      if (frozen != null) deliver(frozen, silent: true);
    }
  }

  void markRead(String id) {
    if (!state.any((n) => n.id == id && !n.read)) return;
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(read: true) else n,
    ];
    _persist();
  }

  void markAllRead() {
    state = [for (final n in state) n.copyWith(read: true)];
    _persist();
  }

  /// Returns the removed notification and its position, for undo.
  (int, AppNotification)? dismiss(String id) {
    final i = state.indexWhere((n) => n.id == id);
    if (i < 0) return null;
    final removed = state[i];
    state = [...state]..removeAt(i);
    _persist();
    return (i, removed);
  }

  void restore((int, AppNotification) entry) {
    final (i, n) = entry;
    state = [...state]..insert(min(i, state.length), n);
    _persist();
  }

  void _persist() =>
      unawaited(ref.read(notificationRepositoryProvider).save(state));
}

final notificationCenterProvider =
    NotifierProvider<NotificationCenter, List<AppNotification>>(
      NotificationCenter.new,
    );

final unreadCountProvider = Provider<int>(
  (ref) => ref.watch(notificationCenterProvider).where((n) => !n.read).length,
);

// ── Live purchase simulator ────────────────────────────────────────────

/// On in debug builds so the real-time flow can be demoed. Tests turn it
/// off and drive [LiveSimulator.simulateOnce] directly.
final simulatorEnabledProvider = Provider<bool>((ref) => kDebugMode);

/// Fakes incoming card activity every 30–60 seconds while the app is
/// unlocked: adds a pending transaction, charges the card and raises the
/// matching alert.
class LiveSimulator {
  LiveSimulator(this._ref);

  final Ref _ref;
  final _rnd = Random();
  Timer? _timer;

  void start() {
    _timer?.cancel();
    _timer = Timer(Duration(seconds: 30 + _rnd.nextInt(31)), () {
      simulateOnce();
      start();
    });
  }

  void stop() => _timer?.cancel();

  /// Returns the new transaction, or null if every card is frozen.
  CardTransaction? simulateOnce({bool? suspicious}) {
    final cards = _ref.read(cardsProvider).where((c) => !c.frozen).toList();
    if (cards.isEmpty) return null;
    final card = cards[_rnd.nextInt(cards.length)];
    final flagged = suspicious ?? _rnd.nextDouble() < 0.08;
    final tx = randomLiveTransaction(
      _rnd,
      id: 'live_${DateTime.now().microsecondsSinceEpoch}',
      cardId: card.id,
      now: _ref.read(clockProvider)(),
      suspicious: flagged,
    );
    _ref.read(liveTransactionsProvider.notifier).add(tx);
    _ref.read(cardsProvider.notifier).charge(card.id, tx.amount.abs());
    _ref
        .read(notificationCenterProvider.notifier)
        .onNewTransaction(tx, suspicious: flagged);
    return tx;
  }
}

final liveSimulatorProvider = Provider<LiveSimulator>((ref) {
  final sim = LiveSimulator(ref);
  ref.onDispose(sim.stop);
  return sim;
});

/// Watched by the signed-in shell: runs the simulator only while the app is
/// unlocked, stops when the shell goes away (lock screen).
final Provider<void> simulatorRunnerProvider = Provider.autoDispose<void>((
  ref,
) {
  if (!ref.watch(simulatorEnabledProvider)) return;
  final sim = ref.watch(liveSimulatorProvider)..start();
  ref.onDispose(sim.stop);
});
