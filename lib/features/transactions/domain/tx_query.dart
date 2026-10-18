import 'package:intl/intl.dart';
import 'package:kazzi_credit/features/transactions/domain/card_transaction.dart';
import 'package:material_ui/material_ui.dart';

enum TxStatusFilter { all, pending, completed }

/// Search text plus filters for the activity list. Immutable; every filter
/// is optional and they combine with AND.
@immutable
class TxQuery {
  const TxQuery({
    this.text = '',
    this.cardIds = const {},
    this.categories = const {},
    this.from,
    this.to,
    this.rangeLabel,
    this.minAmount,
    this.maxAmount,
    this.status = TxStatusFilter.all,
  });

  static const empty = TxQuery();

  final String text;
  final Set<String> cardIds;
  final Set<TxCategory> categories;

  /// Inclusive start of day.
  final DateTime? from;

  /// Exclusive end.
  final DateTime? to;

  /// Shown on the date chip, e.g. "Last 30 days".
  final String? rangeLabel;

  /// Applied to the absolute amount.
  final double? minAmount;
  final double? maxAmount;
  final TxStatusFilter status;

  bool get hasDate => from != null || to != null;
  bool get hasAmount => minAmount != null || maxAmount != null;

  int get filterCount => [
    cardIds.isNotEmpty,
    categories.isNotEmpty,
    hasDate,
    hasAmount,
    status != TxStatusFilter.all,
  ].where((x) => x).length;

  bool get isFiltered => filterCount > 0 || text.trim().isNotEmpty;

  bool matches(CardTransaction t) {
    if (cardIds.isNotEmpty && !cardIds.contains(t.cardId)) return false;
    if (categories.isNotEmpty && !categories.contains(t.category)) return false;
    if (from != null && t.date.isBefore(from!)) return false;
    if (to != null && !t.date.isBefore(to!)) return false;
    final abs = t.amount.abs();
    if (minAmount != null && abs < minAmount!) return false;
    if (maxAmount != null && abs > maxAmount!) return false;
    if (status == TxStatusFilter.pending && !t.isPending) return false;
    if (status == TxStatusFilter.completed && t.isPending) return false;

    final q = text.trim().toLowerCase();
    if (q.isEmpty) return true;
    // "12.5" should find ₱12.50; "₱12" should find ₱12.xx.
    final numeric = q.replaceAll(RegExp(r'[^\d.]'), '');
    return t.merchant.toLowerCase().contains(q) ||
        t.category.label.toLowerCase().contains(q) ||
        (t.note?.toLowerCase().contains(q) ?? false) ||
        (numeric.isNotEmpty && abs.toStringAsFixed(2).startsWith(numeric));
  }

  TxQuery copyWith({
    String? text,
    Set<String>? cardIds,
    Set<TxCategory>? categories,
    TxStatusFilter? status,
  }) => TxQuery(
    text: text ?? this.text,
    cardIds: cardIds ?? this.cardIds,
    categories: categories ?? this.categories,
    from: from,
    to: to,
    rangeLabel: rangeLabel,
    minAmount: minAmount,
    maxAmount: maxAmount,
    status: status ?? this.status,
  );

  TxQuery withDates(DateTime? from, DateTime? to, String? label) => TxQuery(
    text: text,
    cardIds: cardIds,
    categories: categories,
    from: from,
    to: to,
    rangeLabel: label,
    minAmount: minAmount,
    maxAmount: maxAmount,
    status: status,
  );

  TxQuery withAmounts(double? min, double? max) => TxQuery(
    text: text,
    cardIds: cardIds,
    categories: categories,
    from: from,
    to: to,
    rangeLabel: rangeLabel,
    minAmount: min,
    maxAmount: max,
    status: status,
  );

  /// Keeps the search text, drops every filter.
  TxQuery cleared() => TxQuery(text: text);
}

/// One day's transactions for a sticky-header section.
@immutable
class TxDay {
  const TxDay(this.date, this.items);

  final DateTime date;
  final List<CardTransaction> items;

  /// Net amount: purchases negative, refunds positive.
  double get total => items.fold(0, (sum, t) => sum + t.amount);
}

/// Groups newest-first transactions by calendar day, keeping order.
List<TxDay> groupByDay(List<CardTransaction> txs) {
  final days = <TxDay>[];
  for (final t in txs) {
    final day = DateTime(t.date.year, t.date.month, t.date.day);
    if (days.isEmpty || days.last.date != day) {
      days.add(TxDay(day, [t]));
    } else {
      days.last.items.add(t);
    }
  }
  return days;
}

String dayLabel(DateTime date, DateTime now) {
  final day = DateTime(date.year, date.month, date.day);
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (day.year == now.year) return DateFormat('EEE, MMM d').format(day);
  return DateFormat('EEE, MMM d, y').format(day);
}
