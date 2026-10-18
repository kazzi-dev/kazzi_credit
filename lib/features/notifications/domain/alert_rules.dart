import 'package:intl/intl.dart';
import 'package:kazzi_credit/core/router/routes.dart';
import 'package:kazzi_credit/core/utils/money_format.dart';
import 'package:kazzi_credit/features/cards/domain/payment_card.dart';
import 'package:kazzi_credit/features/notifications/domain/app_notification.dart';
import 'package:kazzi_credit/features/transactions/domain/card_transaction.dart';

// Pure functions that decide which alerts an event produces. Kept free of
// Flutter and Riverpod so the rules are easy to test.

String _cardName(PaymentCard? c) =>
    c == null ? 'your card' : '${c.nickname} •• ${c.last4}';

/// One alert per new charge: "suspicious" if flagged, "large purchase"
/// above the threshold, otherwise a plain purchase alert.
AppNotification? alertForTransaction(
  CardTransaction tx,
  PaymentCard? card,
  NotificationSettings settings, {
  bool suspicious = false,
}) {
  final amount = MoneyFormat.format(tx.amount.abs());
  final route = AppRoutes.transactionDetail(tx.id);
  final base = (
    id: 'n_${tx.id}',
    createdAt: tx.date,
    txId: tx.id,
    cardId: tx.cardId,
  );

  if (suspicious) {
    return AppNotification(
      id: base.id,
      type: NotificationType.suspicious,
      title: 'Was this you?',
      body:
          '$amount at ${tx.merchant} on ${_cardName(card)}. '
          'Tap to review.',
      createdAt: base.createdAt,
      route: route,
      txId: base.txId,
      cardId: base.cardId,
    );
  }
  if (tx.isRefund) return null;

  final isLarge = tx.amount.abs() >= settings.largePurchaseThreshold;
  final type = isLarge
      ? NotificationType.largePurchase
      : NotificationType.transaction;
  // A disabled "large purchase" falls back to a normal purchase alert.
  final effective = settings.isEnabled(type)
      ? type
      : (isLarge && settings.isEnabled(NotificationType.transaction)
            ? NotificationType.transaction
            : null);
  if (effective == null) return null;

  return AppNotification(
    id: base.id,
    type: effective,
    title: effective == NotificationType.largePurchase
        ? 'Large purchase · $amount'
        : '${tx.merchant} · −$amount',
    body: effective == NotificationType.largePurchase
        ? '${tx.merchant} on ${_cardName(card)}'
        : 'Paid with ${_cardName(card)}',
    createdAt: base.createdAt,
    route: route,
    txId: base.txId,
    cardId: base.cardId,
  );
}

/// Fires once when utilization crosses 80% and again at 100%.
AppNotification? alertForLimit(
  PaymentCard before,
  PaymentCard after,
  DateTime now,
) {
  if (!after.tracksCredit) return null;
  final level = after.utilization >= 1
      ? 100
      : after.utilization >= 0.8
      ? 80
      : 0;
  final previous = before.utilization >= 1
      ? 100
      : before.utilization >= 0.8
      ? 80
      : 0;
  if (level == 0 || level <= previous) return null;
  return AppNotification(
    id: 'n_limit_${after.id}_${level}_${now.millisecondsSinceEpoch}',
    type: NotificationType.limitWarning,
    title: level == 100
        ? '${after.nickname} has reached its limit'
        : "You've used 80% of your ${after.nickname} limit",
    body:
        '${MoneyFormat.format(after.balance)} of '
        '${MoneyFormat.format(after.creditLimit)} used. '
        '${MoneyFormat.format(after.available)} left.',
    createdAt: now,
    route: AppRoutes.cardInWallet(after.id),
    cardId: after.id,
  );
}

AppNotification? alertForFreeze(
  PaymentCard before,
  PaymentCard after,
  DateTime now,
) {
  if (before.frozen || !after.frozen) return null;
  return AppNotification(
    id: 'n_frozen_${after.id}_${now.millisecondsSinceEpoch}',
    type: NotificationType.cardFrozen,
    title: '${_cardName(after)} is frozen',
    body: 'New purchases will be declined until you unfreeze it.',
    createdAt: now,
    route: AppRoutes.cardInWallet(after.id),
    cardId: after.id,
  );
}

/// Reminders at 3 days and 1 day before the due date, once each.
AppNotification? alertForDueDate(PaymentCard card, DateTime now) {
  if (card.kind != CardKind.credit || card.minimumDue <= 0) return null;
  final days = card.daysUntilDue(now);
  if (days != 3 && days != 1) return null;
  final due = DateFormat.MMMd().format(card.dueDate);
  return AppNotification(
    id: 'n_due_${card.id}_${days}_${card.dueDate.toIso8601String()}',
    type: NotificationType.paymentDue,
    title: days == 1
        ? '${card.nickname} payment due tomorrow'
        : '${card.nickname} payment due in 3 days',
    body:
        'Minimum ${MoneyFormat.format(card.minimumDue)} · '
        'statement ${MoneyFormat.format(card.statementBalance)} · due $due',
    createdAt: now,
    route: AppRoutes.cardInWallet(card.id),
    dedupeKey: 'due_${card.id}_${days}_${card.dueDate.toIso8601String()}',
    cardId: card.id,
  );
}
