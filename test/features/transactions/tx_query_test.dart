import 'package:flutter_test/flutter_test.dart';
import 'package:kazzi_credit/features/transactions/data/tx_edits_repository.dart';
import 'package:kazzi_credit/features/transactions/domain/card_transaction.dart';
import 'package:kazzi_credit/features/transactions/domain/tx_query.dart';

import '../../helpers/fakes.dart';

final _now = DateTime(2026, 10, 18, 15);

CardTransaction _tx(
  String merchant, {
  double amount = -12.5,
  TxCategory category = TxCategory.food,
  int daysAgo = 0,
  TxStatus status = TxStatus.completed,
  String cardId = 'everyday',
}) => CardTransaction(
  id: merchant,
  cardId: cardId,
  merchant: merchant,
  category: category,
  amount: amount,
  date: _now.subtract(Duration(days: daysAgo)),
  status: status,
);

void main() {
  group('search', () {
    test('matches merchant, category and amount', () {
      final t = _tx('Blue Bottle Coffee');
      expect(const TxQuery(text: 'bottle').matches(t), isTrue);
      expect(const TxQuery(text: 'food').matches(t), isTrue);
      expect(const TxQuery(text: '₱12.5').matches(t), isTrue);
      expect(const TxQuery(text: 'uber').matches(t), isFalse);
    });
  });

  group('filters', () {
    test('combine with AND', () {
      const q = TxQuery(cardIds: {'travel'}, categories: {TxCategory.travel});
      expect(
        q.matches(_tx('Delta', cardId: 'travel', category: TxCategory.travel)),
        isTrue,
      );
      expect(q.matches(_tx('Delta', category: TxCategory.travel)), isFalse);
      expect(q.filterCount, 2);
    });

    test('amount range uses the absolute value', () {
      final q = TxQuery.empty.withAmounts(20, 100);
      expect(q.matches(_tx('A', amount: -50)), isTrue);
      expect(q.matches(_tx('B', amount: 50)), isTrue); // refund
      expect(q.matches(_tx('C', amount: -5)), isFalse);
    });

    test('date range end is exclusive', () {
      final start = DateTime(2026, 10, 17);
      final q = TxQuery.empty.withDates(start, DateTime(2026, 10, 18), 'x');
      expect(q.matches(_tx('Yesterday', daysAgo: 1)), isTrue);
      expect(q.matches(_tx('Today')), isFalse);
    });

    test('status', () {
      const q = TxQuery(status: TxStatusFilter.pending);
      expect(q.matches(_tx('P', status: TxStatus.pending)), isTrue);
      expect(q.matches(_tx('C')), isFalse);
    });

    test('clearing keeps the search text', () {
      final q = const TxQuery(
        text: 'uber',
        status: TxStatusFilter.pending,
      ).cleared();
      expect(q.text, 'uber');
      expect(q.filterCount, 0);
    });
  });

  test('groups by day with net totals', () {
    final days = groupByDay([
      _tx('A', amount: -10),
      _tx('B', amount: 4),
      _tx('C', amount: -1, daysAgo: 1),
    ]);
    expect(days.length, 2);
    expect(days.first.total, -6);
    expect(dayLabel(days.first.date, _now), 'Today');
    expect(dayLabel(days.last.date, _now), 'Yesterday');
    expect(dayLabel(DateTime(2026, 10, 12), _now), 'Mon, Oct 12');
  });

  test('edits merge, empty note removes it, and persist', () async {
    final t = _tx('A');
    final edit = const TxEdit(category: TxCategory.health)
        .merge(const TxEdit(note: 'Split'));
    expect(t.applying(edit).category, TxCategory.health);
    expect(t.applying(edit).note, 'Split');
    expect(t.applying(edit.merge(const TxEdit(note: ''))).note, isNull);

    final repo = TxEditsRepository(InMemoryKeyValueStore());
    await repo.save({'A': edit});
    final loaded = await repo.load();
    expect(loaded['A']!.category, TxCategory.health);
    expect(loaded['A']!.note, 'Split');
  });
}
