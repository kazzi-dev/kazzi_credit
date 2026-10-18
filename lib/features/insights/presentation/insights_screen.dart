import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kazzi_credit/core/theme/app_tokens.dart';
import 'package:kazzi_credit/core/theme/theme_extensions.dart';
import 'package:kazzi_credit/core/utils/money_format.dart';
import 'package:kazzi_credit/core/widgets/amount_text.dart';
import 'package:kazzi_credit/core/widgets/empty_state.dart';
import 'package:kazzi_credit/features/cards/application/cards_controller.dart';
import 'package:kazzi_credit/features/insights/application/insights_controller.dart';
import 'package:kazzi_credit/features/insights/domain/month_insights.dart';
import 'package:kazzi_credit/features/insights/presentation/widgets/budget_sheet.dart';
import 'package:kazzi_credit/features/insights/presentation/widgets/spending_donut.dart';
import 'package:kazzi_credit/features/insights/presentation/widgets/weekly_bars.dart';
import 'package:kazzi_credit/features/transactions/domain/card_transaction.dart';
import 'package:material_ui/material_ui.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  TxCategory? _category;
  int? _week;
  bool _weeksAsTable = false;

  @override
  Widget build(BuildContext context) {
    // A new month starts with fresh selections.
    ref.listen(selectedMonthProvider, (_, _) {
      setState(() {
        _category = null;
        _week = null;
      });
    });
    final i = ref.watch(monthInsightsProvider);

    final sections = <Widget>[
      if (i.isEmpty)
        const Padding(
          padding: EdgeInsets.only(top: AppSpacing.xxl),
          child: EmptyState(
            icon: Icons.donut_large_rounded,
            title: 'No spending this month',
            message: 'Purchases will show up here as they happen.',
          ),
        )
      else ...[
        _Summary(insights: i),
        _CategoryCard(
          insights: i,
          selected: i.byCategory.any((s) => s.category == _category)
              ? _category!
              : i.byCategory.first.category,
          onSelect: (c) => setState(() => _category = c),
        ),
        _WeeklyCard(
          weeks: i.weeks,
          selected: (_week ?? i.weeks.length - 1).clamp(0, i.weeks.length - 1),
          asTable: _weeksAsTable,
          onSelect: (w) => setState(() => _week = w),
          onToggleTable: () => setState(() => _weeksAsTable = !_weeksAsTable),
        ),
        _MerchantsCard(merchants: i.topMerchants),
      ],
      _BudgetsCard(insights: i),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.lg,
            AppSpacing.page,
            AppSpacing.xxxl,
          ),
          children: [
            Semantics(
              header: true,
              child: Text('Insights', style: context.text.headlineMedium),
            ),
            const SizedBox(height: AppSpacing.md),
            const _MonthSwitcher(),
            for (final s in sections)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                child: s,
              ),
          ],
        ),
      ),
    );
  }
}

/// The one filter that scopes every chart below it.
class _MonthSwitcher extends ConsumerWidget {
  const _MonthSwitcher();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final months = ref.watch(availableMonthsProvider);
    final now = ref.watch(clockProvider)();
    final ctrl = ref.read(selectedMonthProvider.notifier);
    final canBack = months.isNotEmpty && month.isAfter(months.first);
    final canForward = month.isBefore(DateTime(now.year, now.month));

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: AppRadii.pillAll,
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Previous month',
            onPressed: canBack ? () => ctrl.shift(-1) : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Text(
                DateFormat.yMMMM().format(month),
                textAlign: TextAlign.center,
                style: context.text.titleMedium,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Next month',
            onPressed: canForward ? () => ctrl.shift(1) : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: AppRadii.xlAll,
        border: context.isDark ? Border.all(color: c.border) : null,
        boxShadow: context.isDark ? null : AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: AppSpacing.minTouch,
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(title, style: context.text.titleMedium),
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

/// Spending vs last month: up is shown as a caution, down as good, always
/// with an arrow and words — never color alone.
class _Delta extends StatelessWidget {
  const _Delta({required this.change, this.suffix = ''});

  final double? change;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ch = change;
    if (ch == null) {
      return Text('New', style: context.text.labelMedium);
    }
    final up = ch > 0;
    final color = up ? c.warning : c.success;
    final pct = (ch.abs() * 100).round();
    // Rich text (not a Row) so a long suffix wraps instead of overflowing.
    return Text.rich(
      TextSpan(
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Icon(
              up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              size: 14,
              color: color,
            ),
          ),
          TextSpan(text: '$pct%$suffix'),
        ],
      ),
      style: context.text.labelMedium?.copyWith(color: color),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.insights});

  final MonthInsights insights;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final i = insights;
    final vs = i.comparesToSamePoint
        ? ' vs this point last month'
        : ' vs ${DateFormat.MMMM().format(DateTime(i.month.year, i.month.month - 1))}';
    return _Card(
      title: 'Spent in ${DateFormat.MMMM().format(i.month)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AmountText(
            i.total,
            style: context.text.displayMedium,
            smallCents: true,
            tabular: false,
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            children: [
              _Delta(change: i.change, suffix: i.change == null ? '' : vs),
              if (i.refunds > 0)
                Text(
                  '· ${MoneyFormat.format(i.refunds)} refunded',
                  style: context.text.labelMedium,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Divider(color: c.border),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _Stat(
                label: 'Daily average',
                value: MoneyFormat.format(i.dailyAverage),
              ),
              _Stat(
                label: 'Biggest day',
                value: i.biggestDay == null
                    ? '—'
                    : MoneyFormat.format(i.biggestDay!.amount),
                caption: i.biggestDay == null
                    ? null
                    : DateFormat.MMMd().format(i.biggestDay!.day),
              ),
              _Stat(label: 'Purchases', value: '${i.purchaseCount}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.caption});

  final String label;
  final String value;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.text.bodySmall),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: context.text.titleMedium),
          ),
          if (caption != null) Text(caption!, style: context.text.bodySmall),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.insights,
    required this.selected,
    required this.onSelect,
  });

  final MonthInsights insights;
  final TxCategory selected;
  final ValueChanged<TxCategory> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final i = insights;
    return _Card(
      title: 'Where it went',
      child: Column(
        children: [
          SpendingDonut(
            segments: i.byCategory,
            total: i.total,
            selected: selected,
            onSelect: onSelect,
          ),
          const SizedBox(height: AppSpacing.lg),
          // Ranked legend: identity by icon + name, and the table view.
          for (final s in i.byCategory)
            Semantics(
              button: true,
              selected: s.category == selected,
              child: Material(
                color: s.category == selected
                    ? c.primarySoft.withValues(alpha: 0.6)
                    : Colors.transparent,
                borderRadius: AppRadii.mdAll,
                child: InkWell(
                  borderRadius: AppRadii.mdAll,
                  onTap: () => onSelect(s.category),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: s.category.color.withValues(alpha: 0.14),
                            borderRadius: AppRadii.mdAll,
                          ),
                          child: Icon(
                            s.category.icon,
                            size: 18,
                            color: s.category.color,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.category.label,
                                style: context.text.titleSmall,
                              ),
                              Text(
                                '${sharePercent(s.amount, i.total)} · '
                                '${s.count} '
                                '${s.count == 1 ? 'purchase' : 'purchases'}',
                                style: context.text.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            AmountText(
                              s.amount,
                              style: context.text.titleSmall,
                            ),
                            _Delta(change: s.change),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WeeklyCard extends StatelessWidget {
  const _WeeklyCard({
    required this.weeks,
    required this.selected,
    required this.asTable,
    required this.onSelect,
    required this.onToggleTable,
  });

  final List<WeekSpend> weeks;
  final int selected;
  final bool asTable;
  final ValueChanged<int> onSelect;
  final VoidCallback onToggleTable;

  @override
  Widget build(BuildContext context) {
    final w = weeks[selected];
    return _Card(
      title: 'Weekly spending',
      trailing: IconButton(
        tooltip: asTable ? 'Show as chart' : 'Show as table',
        onPressed: onToggleTable,
        icon: Icon(
          asTable ? Icons.bar_chart_rounded : Icons.table_rows_outlined,
        ),
      ),
      child: AnimatedSwitcher(
        duration: AppMotion.of(context, AppMotion.medium),
        child: asTable
            ? Column(
                key: const ValueKey('table'),
                children: [
                  for (final x in weeks)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              weekLabel(x) + (x.partial ? ' (so far)' : ''),
                              style: context.text.bodyMedium,
                            ),
                          ),
                          AmountText(x.amount, style: context.text.titleSmall),
                        ],
                      ),
                    ),
                ],
              )
            : Column(
                key: const ValueKey('chart'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Readout for the selected bar: the tooltip, always visible.
                  Semantics(
                    liveRegion: true,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        AmountText(
                          w.amount,
                          style: context.text.headlineSmall,
                          tabular: false,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            weekLabel(w) + (w.partial ? ' · so far' : ''),
                            style: context.text.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  WeeklyBars(
                    weeks: weeks,
                    selected: selected,
                    onSelect: onSelect,
                  ),
                ],
              ),
      ),
    );
  }
}

class _MerchantsCard extends StatelessWidget {
  const _MerchantsCard({required this.merchants});

  final List<MerchantSpend> merchants;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final top = merchants.isEmpty ? 1.0 : merchants.first.amount;
    return _Card(
      title: 'Top merchants',
      child: Column(
        children: [
          for (final (n, m) in merchants.indexed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 20,
                    child: Text(
                      '${n + 1}',
                      style: context.text.labelMedium?.copyWith(
                        color: c.textTertiary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                m.merchant,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.text.titleSmall,
                              ),
                            ),
                            AmountText(
                              m.amount,
                              style: context.text.titleSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        // One hue for magnitude; relative to the top merchant.
                        ClipRRect(
                          borderRadius: AppRadii.pillAll,
                          child: LinearProgressIndicator(
                            value: m.amount / top,
                            minHeight: 4,
                            color: c.primary,
                            backgroundColor: c.surfaceHigh,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${m.count} ${m.count == 1 ? 'visit' : 'visits'} · '
                          '${m.category.label}',
                          style: context.text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BudgetsCard extends ConsumerWidget {
  const _BudgetsCard({required this.insights});

  final MonthInsights insights;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = ref.watch(budgetsProvider);
    final rows = budgets.entries.toList()
      ..sort(
        (a, b) => (insights.spentIn(b.key) / b.value).compareTo(
          insights.spentIn(a.key) / a.value,
        ),
      );
    final canAdd = TxCategory.values.any(
      (x) => x != TxCategory.refund && !budgets.containsKey(x),
    );

    return _Card(
      title: 'Budgets',
      trailing: canAdd
          ? TextButton.icon(
              onPressed: () => showBudgetSheet(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add'),
            )
          : null,
      child: rows.isEmpty
          ? Text(
              'Set a monthly limit for a category to see how you’re tracking.',
              style: context.text.bodySmall,
            )
          : Column(
              children: [
                for (final MapEntry(key: cat, value: limit) in rows)
                  _BudgetRow(
                    category: cat,
                    limit: limit,
                    spent: insights.spentIn(cat),
                    onTap: () => showBudgetSheet(
                      context,
                      category: cat,
                      lastMonthSpend: insights.byCategory
                          .where((s) => s.category == cat)
                          .firstOrNull
                          ?.previous,
                    ),
                  ),
              ],
            ),
    );
  }
}

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({
    required this.category,
    required this.limit,
    required this.spent,
    required this.onTap,
  });

  final TxCategory category;
  final double limit;
  final double spent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pct = spent / limit;
    final left = limit - spent;
    // Status: always an icon and words, not color alone.
    final (Color color, IconData? icon, String status) = pct > 1
        ? (c.error, Icons.error_rounded, 'Over by ${MoneyFormat.format(-left)}')
        : pct >= 0.8
        ? (
            c.warning,
            Icons.warning_amber_rounded,
            '${MoneyFormat.format(left)} left · almost there',
          )
        : (c.primary, null, '${MoneyFormat.format(left)} left');

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.mdAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(category.icon, size: 18, color: category.color),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(category.label, style: context.text.titleSmall),
                ),
                Text(
                  '${MoneyFormat.format(spent)} of '
                  '${MoneyFormat.format(limit).replaceAll('.00', '')}',
                  style: context.text.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: pct.clamp(0, 1)),
              duration: AppMotion.of(
                context,
                const Duration(milliseconds: 700),
              ),
              curve: AppMotion.emphasized,
              builder: (context, v, _) => ClipRRect(
                borderRadius: AppRadii.pillAll,
                child: LinearProgressIndicator(
                  value: v,
                  minHeight: 8,
                  color: color,
                  backgroundColor: c.surfaceHigh,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: color),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Flexible(
                  child: Text(
                    status,
                    style: context.text.bodySmall?.copyWith(
                      color: icon == null ? null : color,
                      fontWeight: icon == null ? null : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
