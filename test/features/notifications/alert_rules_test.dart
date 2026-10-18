import 'package:flutter_test/flutter_test.dart';
import 'package:kazzi_credit/features/cards/data/mock_cards.dart';
import 'package:kazzi_credit/features/cards/domain/payment_card.dart';
import 'package:kazzi_credit/features/notifications/domain/alert_rules.dart';
import 'package:kazzi_credit/features/notifications/domain/app_notification.dart';
import 'package:kazzi_credit/features/transactions/domain/card_transaction.dart';

final _now = DateTime(2026, 10, 18, 12);
final PaymentCard _card = mockCards(_now).first; // Everyday: ₱80,000 limit

CardTransaction _tx(double amount) => CardTransaction(
  id: 't1',
  cardId: _card.id,
  merchant: 'Uniqlo',
  category: TxCategory.shopping,
  amount: amount,
  date: _now,
);

void main() {
  const defaults = NotificationSettings();

  group('purchase alerts', () {
    test('small purchase → purchase alert linking to the transaction', () {
      final n = alertForTransaction(_tx(-59.9), _card, defaults)!;
      expect(n.type, NotificationType.transaction);
      expect(n.title, contains('Uniqlo'));
      expect(n.body, contains('Everyday •• 4821'));
      expect(n.route, '/transaction/t1');
    });

    test('above the threshold → large purchase', () {
      final n = alertForTransaction(_tx(-6000), _card, defaults)!;
      expect(n.type, NotificationType.largePurchase);
    });

    test('disabled large-purchase alerts fall back to a normal alert', () {
      final s = defaults.copyWith(disabled: {NotificationType.largePurchase});
      expect(
        alertForTransaction(_tx(-6000), _card, s)!.type,
        NotificationType.transaction,
      );
    });

    test('purchases off → no alert; refunds never alert', () {
      final s = defaults.copyWith(disabled: {NotificationType.transaction});
      expect(alertForTransaction(_tx(-20), _card, s), isNull);
      expect(alertForTransaction(_tx(20), _card, defaults), isNull);
    });

    test("suspicious alerts can't be turned off", () {
      final s = defaults.copyWith(disabled: {NotificationType.suspicious});
      expect(s.isEnabled(NotificationType.suspicious), isTrue);
      expect(
        alertForTransaction(_tx(-400), _card, s, suspicious: true)!.type,
        NotificationType.suspicious,
      );
    });
  });

  test('limit alerts fire when crossing 80% and 100%, once each', () {
    final at79 = _card.copyWith(balance: 63200);
    final at85 = _card.copyWith(balance: 68000);
    final at90 = _card.copyWith(balance: 72000);
    final at100 = _card.copyWith(balance: 80000);
    expect(alertForLimit(at79, at85, _now)!.title, contains('80%'));
    expect(alertForLimit(at85, at90, _now), isNull);
    expect(alertForLimit(at90, at100, _now)!.title, contains('reached'));
  });

  test('freeze alert only when a card becomes frozen', () {
    final frozen = _card.copyWith(frozen: true);
    expect(alertForFreeze(_card, frozen, _now)!.route, '/home?card=everyday');
    expect(alertForFreeze(frozen, _card, _now), isNull);
  });

  test('due reminders at 3 days and 1 day, deduplicated by key', () {
    PaymentCard dueIn(int days) => PaymentCard(
      id: 'c',
      nickname: 'Travel',
      holder: 'A',
      last4: '9012',
      network: _card.network,
      expiryMonth: 1,
      expiryYear: 2030,
      themeId: 'aurora',
      creditLimit: 1000,
      balance: 100,
      statementBalance: 100,
      minimumDue: 25,
      dueDate: _now.add(Duration(days: days)),
    );
    expect(alertForDueDate(dueIn(3), _now)!.title, contains('3 days'));
    expect(alertForDueDate(dueIn(1), _now)!.title, contains('tomorrow'));
    expect(alertForDueDate(dueIn(2), _now), isNull);
    expect(
      alertForDueDate(dueIn(3), _now)!.dedupeKey,
      alertForDueDate(dueIn(3), _now.add(const Duration(hours: 2)))!.dedupeKey,
    );
  });

  group('settings', () {
    test('quiet hours wrap past midnight', () {
      final s = defaults.copyWith(quietHoursEnabled: true); // 22:00–07:00
      expect(s.isQuiet(DateTime(2026, 1, 1, 23)), isTrue);
      expect(s.isQuiet(DateTime(2026, 1, 1, 3)), isTrue);
      expect(s.isQuiet(DateTime(2026, 1, 1, 7)), isFalse);
      expect(s.isQuiet(DateTime(2026, 1, 1, 12)), isFalse);
      expect(defaults.isQuiet(DateTime(2026, 1, 1, 23)), isFalse);
    });

    test('round-trips through JSON', () {
      final s = defaults.copyWith(
        disabled: {NotificationType.cardFrozen},
        largePurchaseThreshold: 500,
        quietHoursEnabled: true,
      );
      final back = NotificationSettings.fromJson(s.toJson());
      expect(back.disabled, {NotificationType.cardFrozen});
      expect(back.largePurchaseThreshold, 500);
      expect(back.quietHoursEnabled, isTrue);
    });
  });
}
