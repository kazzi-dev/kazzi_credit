import 'package:flutter/foundation.dart';
import 'package:kazzi_credit/features/transactions/domain/card_transaction.dart';

@immutable
class CategorySpend {
  const CategorySpend(this.category, this.amount, this.previous, this.count);

  final TxCategory category;
  final double amount;

  /// Same category over the comparison period.
  final double previous;
  final int count;

  /// Null when there's nothing to compare against.
  double? get change => previous == 0 ? null : (amount - previous) / previous;
}

@immutable
class WeekSpend {
  const WeekSpend(this.start, this.end, this.amount, {this.partial = false});

  /// First day (inclusive), clipped to the month.
  final DateTime start;

  /// Last day (inclusive), clipped to the month.
  final DateTime end;
  final double amount;

  /// The week isn't over yet.
  final bool partial;
}

@immutable
class MerchantSpend {
  const MerchantSpend(this.merchant, this.category, this.amount, this.count);

  final String merchant;
  final TxCategory category;
  final double amount;
  final int count;
}

@immutable
class MonthInsights {
  const MonthInsights({
    required this.month,
    required this.total,
    required this.previousTotal,
    required this.comparesToSamePoint,
    required this.refunds,
    required this.purchaseCount,
    required this.byCategory,
    required this.weeks,
    required this.topMerchants,
    required this.dailyAverage,
    required this.biggestDay,
  });

  /// First day of the month.
  final DateTime month;

  /// Purchases only (refunds are reported separately).
  final double total;
  final double previousTotal;

  /// True for the current month: compared with the same days of last month
  /// rather than all of it, so the comparison is fair mid-month.
  final bool comparesToSamePoint;
  final double refunds;
  final int purchaseCount;

  /// Largest first; refunds excluded.
  final List<CategorySpend> byCategory;
  final List<WeekSpend> weeks;
  final List<MerchantSpend> topMerchants;
  final double dailyAverage;
  final ({DateTime day, double amount})? biggestDay;

  bool get isEmpty => purchaseCount == 0;

  double? get change =>
      previousTotal == 0 ? null : (total - previousTotal) / previousTotal;

  double spentIn(TxCategory c) =>
      byCategory.where((s) => s.category == c).firstOrNull?.amount ?? 0;
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// Aggregates one calendar month of transactions. Pure, so it's tested
/// directly and recomputed cheaply when edits recategorize a purchase.
MonthInsights computeInsights(
  List<CardTransaction> all,
  DateTime month,
  DateTime now,
) {
  final start = DateTime(month.year, month.month);
  final next = DateTime(month.year, month.month + 1);
  final isCurrent = !now.isBefore(start) && now.isBefore(next);
  final prevStart = DateTime(month.year, month.month - 1);
  // Mid-month, compare with the same number of days last month.
  final prevEnd = isCurrent
      ? DateTime(prevStart.year, prevStart.month, now.day, now.hour, now.minute)
      : start;

  final inMonth = all.where(
    (t) => !t.date.isBefore(start) && t.date.isBefore(next),
  );
  final inPrev = all.where(
    (t) => !t.date.isBefore(prevStart) && t.date.isBefore(prevEnd),
  );

  final purchases = inMonth.where((t) => t.amount < 0).toList();
  final total = purchases.fold<double>(0, (s, t) => s - t.amount);
  final refunds = inMonth
      .where((t) => t.amount > 0)
      .fold<double>(0, (s, t) => s + t.amount);

  final cur = <TxCategory, (double, int)>{};
  for (final t in purchases) {
    final (a, n) = cur[t.category] ?? (0.0, 0);
    cur[t.category] = (a - t.amount, n + 1);
  }
  final prev = <TxCategory, double>{};
  var previousTotal = 0.0;
  for (final t in inPrev.where((t) => t.amount < 0)) {
    prev[t.category] = (prev[t.category] ?? 0) - t.amount;
    previousTotal -= t.amount;
  }
  final byCategory = [
    for (final MapEntry(key: c, value: (a, n)) in cur.entries)
      CategorySpend(c, a, prev[c] ?? 0, n),
  ]..sort((a, b) => b.amount.compareTo(a.amount));

  // Monday-start weeks, clipped to the month.
  final weeks = <WeekSpend>[];
  var weekStart = start;
  while (weekStart.isBefore(next)) {
    final toMonday = (weekStart.weekday - DateTime.monday) % 7;
    final nextWeek = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day - toMonday + 7,
    );
    final weekEnd = nextWeek.isBefore(next) ? nextWeek : next;
    final amount = purchases
        .where((t) => !t.date.isBefore(weekStart) && t.date.isBefore(weekEnd))
        .fold<double>(0, (s, t) => s - t.amount);
    weeks.add(
      WeekSpend(
        weekStart,
        weekEnd.subtract(const Duration(days: 1)),
        amount,
        partial: weekEnd.isAfter(now),
      ),
    );
    weekStart = weekEnd;
  }
  // Future weeks of the current month have no data yet; drop them.
  weeks.removeWhere((w) => w.start.isAfter(now));

  final merchants = <String, (TxCategory, double, int)>{};
  for (final t in purchases) {
    final (_, a, n) = merchants[t.merchant] ?? (t.category, 0.0, 0);
    merchants[t.merchant] = (t.category, a - t.amount, n + 1);
  }
  final topMerchants = [
    for (final MapEntry(key: m, value: (c, a, n)) in merchants.entries)
      MerchantSpend(m, c, a, n),
  ]..sort((a, b) => b.amount.compareTo(a.amount));

  final days = <DateTime, double>{};
  for (final t in purchases) {
    days[_day(t.date)] = (days[_day(t.date)] ?? 0) - t.amount;
  }
  final biggest = days.entries.fold<MapEntry<DateTime, double>?>(
    null,
    (best, e) => best == null || e.value > best.value ? e : best,
  );
  final elapsedDays = isCurrent
      ? now.day
      : next.subtract(const Duration(days: 1)).day;

  return MonthInsights(
    month: start,
    total: total,
    previousTotal: previousTotal,
    comparesToSamePoint: isCurrent,
    refunds: refunds,
    purchaseCount: purchases.length,
    byCategory: byCategory,
    weeks: weeks,
    topMerchants: topMerchants.take(5).toList(),
    dailyAverage: elapsedDays == 0 ? 0 : total / elapsedDays,
    biggestDay: biggest == null
        ? null
        : (day: biggest.key, amount: biggest.value),
  );
}

/// Share as a whole percent, with "<1%" instead of a misleading 0%.
String sharePercent(double part, double total) {
  final p = part / total * 100;
  return p > 0 && p < 1 ? '<1%' : '${p.round()}%';
}
