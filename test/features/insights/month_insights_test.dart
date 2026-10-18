import 'package:flutter_test/flutter_test.dart';
import 'package:kazzi_credit/features/insights/application/insights_controller.dart';
import 'package:kazzi_credit/features/insights/domain/month_insights.dart';
import 'package:kazzi_credit/features/insights/presentation/widgets/weekly_bars.dart';
import 'package:kazzi_credit/features/transactions/domain/card_transaction.dart';

import '../../helpers/fakes.dart';

var _n = 0;
CardTransaction _tx(
  DateTime date,
  double amount, {
  TxCategory category = TxCategory.food,
  String merchant = 'Cafe',
}) => CardTransaction(
  id: 't${_n++}',
  cardId: 'c',
  merchant: merchant,
  category: category,
  amount: amount,
  date: date,
);

void main() {
  // Sunday, October 18 2026, mid-afternoon.
  final now = DateTime(2026, 10, 18, 15);
  final oct = DateTime(2026, 10);

  test('totals only the selected month, refunds separately', () {
    final i = computeInsights(
      [
        _tx(DateTime(2026, 10, 2), -100),
        _tx(DateTime(2026, 10, 5), -50, category: TxCategory.travel),
        _tx(DateTime(2026, 10, 6), 20, category: TxCategory.refund),
        _tx(DateTime(2026, 9, 30, 23), -999), // previous month
        _tx(DateTime(2026, 11), -999), // next month
      ],
      oct,
      now,
    );
    expect(i.total, 150);
    expect(i.refunds, 20);
    expect(i.purchaseCount, 2);
    expect(i.byCategory.map((c) => c.category), [
      TxCategory.food,
      TxCategory.travel,
    ]);
  });

  test('mid-month compares with the same days of last month', () {
    final i = computeInsights(
      [
        _tx(DateTime(2026, 10, 3), -100),
        _tx(DateTime(2026, 9, 10), -80), // before Sep 18 → counted
        _tx(DateTime(2026, 9, 25), -500), // after Sep 18 → not counted
      ],
      oct,
      now,
    );
    expect(i.comparesToSamePoint, isTrue);
    expect(i.previousTotal, 80);
    expect(i.change, closeTo(0.25, 1e-9));
    expect(i.byCategory.single.change, closeTo(0.25, 1e-9));
  });

  test('a past month compares with all of the month before', () {
    final i = computeInsights(
      [_tx(DateTime(2026, 9, 3), -100), _tx(DateTime(2026, 8, 30), -200)],
      DateTime(2026, 9),
      now,
    );
    expect(i.comparesToSamePoint, isFalse);
    expect(i.previousTotal, 200);
    expect(i.dailyAverage, closeTo(100 / 30, 1e-9));
  });

  test('weeks start on Monday, clip to the month, stop at today', () {
    final i = computeInsights(
      [
        _tx(DateTime(2026, 10), -10), // Thu → week Oct 1–4
        _tx(DateTime(2026, 10, 5), -20), // Mon → week Oct 5–11
        _tx(DateTime(2026, 10, 18, 9), -30), // Sun → week Oct 12–18
      ],
      oct,
      now,
    );
    expect(i.weeks.map((w) => w.start.day), [1, 5, 12]);
    expect(i.weeks.map((w) => w.end.day), [4, 11, 18]);
    expect(i.weeks.map((w) => w.amount), [10, 20, 30]);
    expect(i.weeks.last.partial, isTrue);
    expect(i.weeks.first.partial, isFalse);
  });

  test('top merchants and biggest day', () {
    final i = computeInsights(
      [
        _tx(DateTime(2026, 10, 2), -5),
        _tx(DateTime(2026, 10, 3), -7),
        _tx(DateTime(2026, 10, 3, 18), -40, merchant: 'Shoes'),
      ],
      oct,
      now,
    );
    expect(i.topMerchants.first.merchant, 'Shoes');
    expect(i.topMerchants.last.count, 2);
    expect(i.biggestDay!.day, DateTime(2026, 10, 3));
    expect(i.biggestDay!.amount, 47);
  });

  test('nice axis ceiling', () {
    expect(niceCeiling(0), 1);
    expect(niceCeiling(73), 100);
    expect(niceCeiling(180), 200);
    expect(niceCeiling(420), 500);
    expect(niceCeiling(1000), 1000);
  });

  test('budgets persist and default when unset', () async {
    final store = InMemoryKeyValueStore();
    expect(await BudgetsController.load(store), isNull);
    await store.write('budgets.v1', '{"food":550,"travel":900}');
    expect(await BudgetsController.load(store), {
      TxCategory.food: 550,
      TxCategory.travel: 900,
    });
  });
}
