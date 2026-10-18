import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kazzi_credit/core/router/routes.dart';
import 'package:kazzi_credit/core/theme/app_tokens.dart';
import 'package:kazzi_credit/core/theme/theme_extensions.dart';
import 'package:kazzi_credit/core/widgets/amount_text.dart';
import 'package:kazzi_credit/core/widgets/empty_state.dart';
import 'package:kazzi_credit/core/widgets/skeleton.dart';
import 'package:kazzi_credit/features/cards/application/cards_controller.dart';
import 'package:kazzi_credit/features/transactions/application/transactions_controller.dart';
import 'package:kazzi_credit/features/transactions/domain/card_transaction.dart';
import 'package:kazzi_credit/features/transactions/domain/tx_query.dart';
import 'package:kazzi_credit/features/transactions/presentation/widgets/filter_bar.dart';
import 'package:kazzi_credit/features/transactions/presentation/widgets/swipe_actions.dart';
import 'package:kazzi_credit/features/transactions/presentation/widgets/transaction_tile.dart';
import 'package:kazzi_credit/features/transactions/presentation/widgets/tx_sheets.dart';
import 'package:material_ui/material_ui.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _search = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _search.text = ref.read(txFeedProvider).query.text;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String text) {
    setState(() {}); // toggles the clear button
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      final query = ref.read(txFeedProvider).query;
      ref.read(txFeedProvider.notifier).setQuery(query.copyWith(text: text));
    });
  }

  void _clearSearch() {
    _search.clear();
    _onSearch('');
  }

  void _open(CardTransaction tx) =>
      context.push(AppRoutes.transactionDetail(tx.id, from: 'activity'));

  bool _onScroll(ScrollNotification n, FeedResults results) {
    if (n.metrics.axis == Axis.vertical &&
        n.metrics.extentAfter < 600 &&
        results.hasMore) {
      ref.read(txFeedProvider.notifier).loadMore(results.total);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(txFeedProvider);
    final results = ref.watch(feedResultsProvider);
    final now = ref.watch(clockProvider)();
    final scale = (MediaQuery.textScalerOf(context).scale(14) / 14).clamp(
      1.0,
      2.0,
    );
    final headerExtent =
        AppSpacing.sm + 48 * scale + AppSpacing.md + 40 * scale + AppSpacing.md;
    final days = groupByDay(results.items);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) => _onScroll(n, results),
          child: RefreshIndicator(
            edgeOffset: headerExtent,
            onRefresh: ref.read(txFeedProvider.notifier).refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    AppSpacing.lg,
                    AppSpacing.page,
                    AppSpacing.sm,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Semantics(
                      header: true,
                      child: Text(
                        'Activity',
                        style: context.text.headlineMedium,
                      ),
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SearchHeader(
                    extent: headerExtent,
                    search: _SearchField(
                      controller: _search,
                      onChanged: _onSearch,
                      onClear: _clearSearch,
                    ),
                  ),
                ),
                if (!feed.loading && !feed.query.isFiltered)
                  const SliverToBoxAdapter(child: _MonthSummary()),
                if (feed.loading)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.page,
                    ),
                    sliver: SliverList.list(
                      children: [
                        const SizedBox(height: AppSpacing.lg),
                        const Skeleton(width: 90, height: 12),
                        for (var i = 0; i < 8; i++) const SkeletonListTile(),
                      ],
                    ),
                  )
                else if (days.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No matching transactions',
                        message:
                            'Try a different search or clear your filters.',
                        actionLabel: feed.query.isFiltered ? 'Clear all' : null,
                        onAction: () {
                          _search.clear();
                          ref
                              .read(txFeedProvider.notifier)
                              .setQuery(TxQuery.empty);
                        },
                      ),
                    ),
                  )
                else ...[
                  for (final day in days)
                    SliverMainAxisGroup(
                      slivers: [
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: _DayHeader(
                            label: dayLabel(day.date, now),
                            total: day.total,
                            extent: 40 * scale,
                          ),
                        ),
                        SliverList.builder(
                          itemCount: day.items.length,
                          itemBuilder: (context, i) => _SwipeableRow(
                            key: ValueKey(day.items[i].id),
                            tx: day.items[i],
                            now: now,
                            onTap: () => _open(day.items[i]),
                          ),
                        ),
                      ],
                    ),
                  SliverToBoxAdapter(
                    child: _Footer(
                      loadingMore: feed.loadingMore,
                      hasMore: results.hasMore,
                      total: results.total,
                    ),
                  ),
                ],
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xxl),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SwipeableRow extends ConsumerWidget {
  const _SwipeableRow({
    required this.tx,
    required this.now,
    required this.onTap,
    super.key,
  });

  final CardTransaction tx;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return SwipeActions(
      actions: [
        SwipeAction(
          icon: Icons.category_rounded,
          label: 'Categorize',
          color: const Color(0xFF6D5BD0),
          onTap: () => changeCategory(context, ref, tx),
        ),
        SwipeAction(
          icon: Icons.sticky_note_2_rounded,
          label: tx.note == null ? 'Note' : 'Edit note',
          color: c.warning,
          onTap: () => editNote(context, ref, tx),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
        child: TransactionTile(
          tx: tx,
          now: now,
          showTime: true,
          heroSource: 'activity',
          onTap: onTap,
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: context.text.bodyLarge,
      decoration: InputDecoration(
        hintText: 'Search merchant, category or amount',
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        fillColor: c.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.lgAll,
          borderSide: BorderSide(color: c.border),
        ),
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                onPressed: onClear,
                icon: const Icon(Icons.cancel_rounded),
              ),
      ),
    );
  }
}

class _SearchHeader extends SliverPersistentHeaderDelegate {
  const _SearchHeader({required this.extent, required this.search});

  final double extent;
  final Widget search;

  @override
  double get minExtent => extent;
  @override
  double get maxExtent => extent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.background,
        border: Border(
          bottom: BorderSide(color: overlaps ? c.border : Colors.transparent),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
            child: search,
          ),
          const SizedBox(height: AppSpacing.md),
          const FilterBar(),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_SearchHeader old) =>
      old.extent != extent || old.search != search;
}

class _DayHeader extends SliverPersistentHeaderDelegate {
  const _DayHeader({
    required this.label,
    required this.total,
    required this.extent,
  });

  final String label;
  final double total;
  final double extent;

  @override
  double get minExtent => extent;
  @override
  double get maxExtent => extent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    final c = context.colors;
    return Container(
      color: c.background,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
      alignment: Alignment.centerLeft,
      child: Semantics(
        header: true,
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: context.text.labelMedium?.copyWith(
                  color: c.textSecondary,
                ),
              ),
            ),
            AmountText(
              total,
              signed: total > 0,
              style: context.text.labelMedium?.copyWith(color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_DayHeader old) =>
      old.label != label || old.total != total || old.extent != extent;
}

class _MonthSummary extends ConsumerWidget {
  const _MonthSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final spend = ref.watch(monthSpendProvider);
    final now = ref.watch(clockProvider)();
    final change = spend.previous == 0
        ? null
        : (spend.current - spend.previous) / spend.previous;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.md,
        AppSpacing.page,
        AppSpacing.sm,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: AppRadii.lgAll,
          border: context.isDark ? Border.all(color: c.border) : null,
          boxShadow: context.isDark ? null : AppShadows.soft,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spent in ${DateFormat.MMMM().format(now)}',
                    style: context.text.labelMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AmountText(
                    spend.current,
                    style: context.text.displaySmall,
                    smallCents: true,
                  ),
                ],
              ),
            ),
            if (change != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: (change > 0 ? c.warning : c.success).withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: AppRadii.pillAll,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      change > 0
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 18,
                      color: change > 0 ? c.warning : c.success,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${(change.abs() * 100).round()}% vs last month',
                      style: context.text.labelMedium?.copyWith(
                        color: change > 0 ? c.warning : c.success,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.loadingMore,
    required this.hasMore,
    required this.total,
  });

  final bool loadingMore;
  final bool hasMore;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: loadingMore
            ? const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : hasMore
            ? const SizedBox(height: 24)
            : Text(
                total == 1 ? '1 transaction' : "That's all $total transactions",
                style: context.text.bodySmall,
              ),
      ),
    );
  }
}
