import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kazzi_credit/core/storage/key_value_store.dart';
import 'package:kazzi_credit/features/auth/application/auth_controller.dart';
import 'package:kazzi_credit/features/cards/application/cards_controller.dart';
import 'package:kazzi_credit/features/cards/data/mock_cards.dart';
import 'package:kazzi_credit/features/transactions/data/mock_transactions.dart';
import 'package:kazzi_credit/features/transactions/data/tx_edits_repository.dart';
import 'package:kazzi_credit/features/transactions/domain/card_transaction.dart';
import 'package:kazzi_credit/features/transactions/domain/tx_query.dart';

// ── Edits ──────────────────────────────────────────────────────────────

final txEditsRepositoryProvider = Provider<TxEditsRepository>(
  (ref) => TxEditsRepository(ref.watch(keyValueStoreProvider)),
);

/// Loaded in `main()` before the first frame.
final initialTxEditsProvider = Provider<Map<String, TxEdit>>((ref) => {});

class TxEditsController extends Notifier<Map<String, TxEdit>> {
  @override
  Map<String, TxEdit> build() {
    // "Forgot PIN" wipes storage; drop in-memory edits with it.
    ref.listen(authControllerProvider.select((a) => a.onboarded), (
      wasOnboarded,
      onboarded,
    ) {
      if ((wasOnboarded ?? false) && !onboarded) state = {};
    });
    return ref.watch(initialTxEditsProvider);
  }

  void edit(String txId, TxEdit change) {
    final current = state[txId];
    state = {...state, txId: current == null ? change : current.merge(change)};
    unawaited(ref.read(txEditsRepositoryProvider).save(state));
  }

  /// Restores a previous edit (for undo).
  void restore(String txId, TxEdit? previous) {
    state = {...state}..remove(txId);
    if (previous != null) state = {...state, txId: previous};
    unawaited(ref.read(txEditsRepositoryProvider).save(state));
  }
}

final txEditsProvider =
    NotifierProvider<TxEditsController, Map<String, TxEdit>>(
      TxEditsController.new,
    );

// ── Transactions ───────────────────────────────────────────────────────

final _mockTransactionsProvider = Provider<List<CardTransaction>>(
  (ref) => generateMockTransactions(
    cardIds: mockCardSecrets.keys.toList(),
    now: ref.watch(clockProvider)(),
  ),
);

/// Loaded in `main()`: transactions that arrived while the app ran.
final initialLiveTransactionsProvider = Provider<List<CardTransaction>>(
  (ref) => const [],
);

/// Transactions that arrive in real time (from the simulator for now; a
/// push channel later). Persisted so notifications can link to them.
class LiveTransactionsController extends Notifier<List<CardTransaction>> {
  static const _key = 'tx.live.v1';

  @override
  List<CardTransaction> build() {
    ref.listen(authControllerProvider.select((a) => a.onboarded), (
      wasOnboarded,
      onboarded,
    ) {
      if ((wasOnboarded ?? false) && !onboarded) state = const [];
    });
    return ref.watch(initialLiveTransactionsProvider);
  }

  void add(CardTransaction tx) {
    state = [tx, ...state];
    unawaited(
      ref
          .read(keyValueStoreProvider)
          .write(_key, jsonEncode([for (final t in state) t.toJson()])),
    );
  }

  static Future<List<CardTransaction>> load(KeyValueStore store) async {
    final raw = await store.read(_key);
    if (raw == null) return const [];
    return [
      for (final j in jsonDecode(raw) as List<dynamic>)
        CardTransaction.fromJson(j as Map<String, dynamic>),
    ];
  }
}

final liveTransactionsProvider =
    NotifierProvider<LiveTransactionsController, List<CardTransaction>>(
      LiveTransactionsController.new,
    );

/// Every transaction, newest first, with the user's edits applied.
final transactionsProvider = Provider<List<CardTransaction>>((ref) {
  final edits = ref.watch(txEditsProvider);
  return [
    for (final t in [
      ...ref.watch(liveTransactionsProvider),
      ...ref.watch(_mockTransactionsProvider),
    ])
      t.applying(edits[t.id]),
  ]..sort((a, b) => b.date.compareTo(a.date));
});

// ignore: specify_nonobvious_property_types, ProviderFamily isn't exported.
final cardTransactionsProvider = Provider.family<List<CardTransaction>, String>(
  (ref, cardId) => [
    for (final t in ref.watch(transactionsProvider))
      if (t.cardId == cardId) t,
  ],
);

// ignore: specify_nonobvious_property_types, ProviderFamily isn't exported.
final transactionByIdProvider = Provider.family<CardTransaction?, String>(
  (ref, id) =>
      ref.watch(transactionsProvider).where((t) => t.id == id).firstOrNull,
);

// ── Activity feed ──────────────────────────────────────────────────────

const txPageSize = 30;

/// Simulated network latency for loading pages.
final feedLatencyProvider = Provider<Duration>(
  (ref) => const Duration(milliseconds: 600),
);

@immutable
class FeedState {
  const FeedState({
    this.query = TxQuery.empty,
    this.visible = txPageSize,
    this.loading = true,
    this.loadingMore = false,
  });

  final TxQuery query;

  /// How many matching transactions are "downloaded" so far.
  final int visible;

  /// First load — shows skeletons.
  final bool loading;
  final bool loadingMore;

  FeedState copyWith({
    TxQuery? query,
    int? visible,
    bool? loading,
    bool? loadingMore,
  }) => FeedState(
    query: query ?? this.query,
    visible: visible ?? this.visible,
    loading: loading ?? this.loading,
    loadingMore: loadingMore ?? this.loadingMore,
  );
}

/// Pages through transactions as if from a server: a first load, more
/// pages near the end of the list, and pull to refresh.
class TxFeedController extends Notifier<FeedState> {
  Timer? _timer;

  @override
  FeedState build() {
    ref.onDispose(() => _timer?.cancel());
    _after(() => state = state.copyWith(loading: false));
    return const FeedState();
  }

  void _after(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(ref.read(feedLatencyProvider), action);
  }

  /// Filtering is local and instant — no skeleton while typing.
  void setQuery(TxQuery query) =>
      state = state.copyWith(query: query, visible: txPageSize);

  void loadMore(int total) {
    if (state.loading || state.loadingMore || state.visible >= total) return;
    state = state.copyWith(loadingMore: true);
    _after(
      () => state = state.copyWith(
        visible: state.visible + txPageSize,
        loadingMore: false,
      ),
    );
  }

  Future<void> refresh() async {
    await Future<void>.delayed(ref.read(feedLatencyProvider));
    state = state.copyWith(visible: txPageSize);
  }
}

final txFeedProvider = NotifierProvider<TxFeedController, FeedState>(
  TxFeedController.new,
);

@immutable
class FeedResults {
  const FeedResults(this.items, this.total);

  final List<CardTransaction> items;

  /// All matches, including ones not paged in yet.
  final int total;

  bool get hasMore => items.length < total;
}

final feedResultsProvider = Provider<FeedResults>((ref) {
  final feed = ref.watch(txFeedProvider);
  final matches = ref
      .watch(transactionsProvider)
      .where(feed.query.matches)
      .toList();
  return FeedResults(matches.take(feed.visible).toList(), matches.length);
});

/// Spending this calendar month vs. the same point last month.
final monthSpendProvider = Provider<({double current, double previous})>((ref) {
  final now = ref.watch(clockProvider)();
  final monthStart = DateTime(now.year, now.month);
  final prevStart = DateTime(now.year, now.month - 1);
  final prevSamePoint = DateTime(now.year, now.month - 1, now.day, now.hour);
  var current = 0.0;
  var previous = 0.0;
  for (final t in ref.watch(transactionsProvider)) {
    if (t.amount >= 0) continue;
    if (!t.date.isBefore(monthStart)) {
      current -= t.amount;
    } else if (!t.date.isBefore(prevStart) && t.date.isBefore(prevSamePoint)) {
      previous -= t.amount;
    }
  }
  return (current: current, previous: previous);
});
