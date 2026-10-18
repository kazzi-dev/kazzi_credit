import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kazzi_credit/core/storage/key_value_store.dart';
import 'package:kazzi_credit/features/auth/application/auth_controller.dart';
import 'package:kazzi_credit/features/cards/application/cards_controller.dart';
import 'package:kazzi_credit/features/insights/domain/month_insights.dart';
import 'package:kazzi_credit/features/transactions/application/transactions_controller.dart';
import 'package:kazzi_credit/features/transactions/domain/card_transaction.dart';

/// The month every Insights chart is scoped to.
class SelectedMonthController extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = ref.watch(clockProvider)();
    return DateTime(now.year, now.month);
  }

  void shift(int months) => state = DateTime(state.year, state.month + months);
}

final selectedMonthProvider =
    NotifierProvider<SelectedMonthController, DateTime>(
      SelectedMonthController.new,
    );

/// Months that have any purchases, oldest first — bounds the month picker.
final availableMonthsProvider = Provider<List<DateTime>>((ref) {
  final months = {
    for (final t in ref.watch(transactionsProvider))
      DateTime(t.date.year, t.date.month),
  }.toList()..sort();
  return months;
});

final monthInsightsProvider = Provider<MonthInsights>(
  (ref) => computeInsights(
    ref.watch(transactionsProvider),
    ref.watch(selectedMonthProvider),
    ref.watch(clockProvider)(),
  ),
);

// ── Budgets ────────────────────────────────────────────────────────────

/// Demo defaults, chosen to show a realistic mix against the demo data:
/// some on track, some close, one over.
const defaultBudgets = <TxCategory, double>{
  TxCategory.food: 800,
  TxCategory.shopping: 2500,
  TxCategory.transport: 750,
  TxCategory.entertainment: 250,
};

/// Loaded in `main()`; null on first run (uses [defaultBudgets]).
final initialBudgetsProvider = Provider<Map<TxCategory, double>?>(
  (ref) => null,
);

/// Monthly budget per category.
class BudgetsController extends Notifier<Map<TxCategory, double>> {
  static const _key = 'budgets.v1';

  @override
  Map<TxCategory, double> build() {
    ref.listen(authControllerProvider.select((a) => a.onboarded), (
      wasOnboarded,
      onboarded,
    ) {
      if ((wasOnboarded ?? false) && !onboarded) state = defaultBudgets;
    });
    return ref.watch(initialBudgetsProvider) ?? defaultBudgets;
  }

  void set(TxCategory category, double? amount) {
    final next = {...state};
    if (amount == null || amount <= 0) {
      next.remove(category);
    } else {
      next[category] = amount;
    }
    state = next;
    unawaited(
      ref
          .read(keyValueStoreProvider)
          .write(
            _key,
            jsonEncode({
              for (final MapEntry(:key, :value) in state.entries)
                key.name: value,
            }),
          ),
    );
  }

  static Future<Map<TxCategory, double>?> load(KeyValueStore store) async {
    final raw = await store.read(_key);
    if (raw == null) return null;
    return {
      for (final MapEntry(:key, :value)
          in (jsonDecode(raw) as Map<String, dynamic>).entries)
        TxCategory.values.byName(key): (value as num).toDouble(),
    };
  }
}

final budgetsProvider =
    NotifierProvider<BudgetsController, Map<TxCategory, double>>(
      BudgetsController.new,
    );
