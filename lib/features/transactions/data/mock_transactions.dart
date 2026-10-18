import 'dart:math';

import 'package:kazzi_credit/features/transactions/domain/card_transaction.dart';

typedef _Merchant = (String name, TxCategory category, double min, double max);

// Philippine merchants with typical peso amounts.
const List<_Merchant> _merchants = [
  ('Jollibee', TxCategory.food, 89, 450),
  ('Starbucks', TxCategory.food, 150, 420),
  ('Mang Inasal', TxCategory.food, 120, 380),
  ('SM Supermarket', TxCategory.food, 800, 4500),
  ('GrabFood', TxCategory.food, 180, 950),
  ('Shopee', TxCategory.shopping, 150, 3500),
  ('Lazada', TxCategory.shopping, 200, 6000),
  ('Uniqlo', TxCategory.shopping, 590, 2990),
  ('Power Mac Center', TxCategory.shopping, 1990, 74990),
  ('Grab', TxCategory.transport, 120, 650),
  ('Angkas', TxCategory.transport, 60, 250),
  ('Petron', TxCategory.transport, 1000, 3500),
  ('Netflix', TxCategory.bills, 549, 549),
  ('Spotify', TxCategory.bills, 194, 194),
  ('Globe Telecom', TxCategory.bills, 999, 1999),
  ('Meralco', TxCategory.bills, 2500, 7500),
  ('SM Cinema', TxCategory.entertainment, 300, 900),
  ('Steam', TxCategory.entertainment, 200, 2500),
  ('Ticketnet', TxCategory.entertainment, 1500, 9000),
  ('Cebu Pacific', TxCategory.travel, 1800, 12000),
  ('Philippine Airlines', TxCategory.travel, 3500, 25000),
  ('Agoda', TxCategory.travel, 2500, 15000),
  ('Mercury Drug', TxCategory.health, 150, 2500),
  ('Anytime Fitness', TxCategory.health, 2000, 3500),
];

// Everyday spending is far more common than flights; weight accordingly.
const Map<TxCategory, int> _weights = {
  TxCategory.food: 9,
  TxCategory.shopping: 5,
  TxCategory.transport: 5,
  TxCategory.bills: 2,
  TxCategory.entertainment: 2,
  TxCategory.travel: 1,
  TxCategory.health: 2,
};

List<_Merchant> _weightedPool() => [
  for (final m in _merchants)
    for (var i = 0; i < _weights[m.$2]!; i++) m,
];

const List<_Merchant> _suspiciousMerchants = [
  ('INTL ONLINE PURCHASE · London', TxCategory.shopping, 8000, 35000),
  ('GLOBAL GIFT CARDS', TxCategory.shopping, 5000, 20000),
  ('ONLINE PAYMENT 7731', TxCategory.bills, 4000, 18000),
];

/// One new pending purchase, as the live simulator would receive it.
CardTransaction randomLiveTransaction(
  Random rnd, {
  required String id,
  required String cardId,
  required DateTime now,
  bool suspicious = false,
}) {
  final pool = suspicious ? _suspiciousMerchants : _weightedPool();
  final m = pool[rnd.nextInt(pool.length)];
  final raw = m.$3 + rnd.nextDouble() * (m.$4 - m.$3);
  return CardTransaction(
    id: id,
    cardId: cardId,
    merchant: m.$1,
    category: m.$2,
    amount: -(raw * 100).roundToDouble() / 100,
    date: now,
    status: TxStatus.pending,
  );
}

/// Deterministic demo history: [count] transactions over the last 90 days,
/// newest first.
List<CardTransaction> generateMockTransactions({
  required List<String> cardIds,
  required DateTime now,
  int count = 150,
  int seed = 42,
}) {
  final rnd = Random(seed);
  final pool = _weightedPool();

  final txs = <CardTransaction>[];
  for (var i = 0; i < count; i++) {
    final m = pool[rnd.nextInt(pool.length)];
    final minutesAgo = (pow(rnd.nextDouble(), 1.3) * 90 * 24 * 60).round();
    // Keep purchases in waking hours.
    var date = now.subtract(Duration(minutes: minutesAgo));
    if (date.hour < 7) date = date.add(const Duration(hours: 8));
    if (date.isAfter(now)) date = now.subtract(const Duration(minutes: 3));

    final raw = m.$3 + rnd.nextDouble() * (m.$4 - m.$3);
    final amount = -(raw * 100).roundToDouble() / 100;
    final recent = now.difference(date).inHours < 36;

    txs.add(
      CardTransaction(
        id: 'tx_$i',
        cardId: cardIds[rnd.nextInt(cardIds.length)],
        merchant: m.$1,
        category: m.$2,
        amount: amount,
        date: date,
        status: recent && rnd.nextDouble() < 0.5
            ? TxStatus.pending
            : TxStatus.completed,
      ),
    );

    // Occasionally refund a shopping purchase a few days later.
    if (m.$2 == TxCategory.shopping && rnd.nextDouble() < 0.12) {
      final refundDate = date.add(Duration(days: 2 + rnd.nextInt(5)));
      if (refundDate.isBefore(now)) {
        txs.add(
          CardTransaction(
            id: 'tx_${i}_refund',
            cardId: txs.last.cardId,
            merchant: m.$1,
            category: TxCategory.refund,
            amount: -amount,
            date: refundDate,
          ),
        );
      }
    }
  }
  txs.sort((a, b) => b.date.compareTo(a.date));
  return txs;
}
