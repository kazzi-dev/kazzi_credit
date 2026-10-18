import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kazzi_credit/core/theme/app_tokens.dart';
import 'package:kazzi_credit/core/theme/theme_extensions.dart';
import 'package:kazzi_credit/core/utils/money_format.dart';
import 'package:kazzi_credit/core/widgets/app_button.dart';
import 'package:kazzi_credit/features/cards/application/cards_controller.dart';
import 'package:kazzi_credit/features/cards/domain/payment_card.dart';
import 'package:kazzi_credit/features/cards/presentation/widgets/card_thumb.dart';
import 'package:kazzi_credit/features/transactions/application/transactions_controller.dart';
import 'package:kazzi_credit/features/transactions/domain/card_transaction.dart';
import 'package:kazzi_credit/features/transactions/domain/tx_query.dart';
import 'package:material_ui/material_ui.dart';

/// Horizontally scrolling filter pills. Each opens a sheet that edits a
/// draft and shows a live result count before applying.
class FilterBar extends ConsumerWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = ref.watch(txFeedProvider).query;
    final cards = ref.watch(cardsProvider);
    final feed = ref.read(txFeedProvider.notifier);

    String cardLabel() {
      if (q.cardIds.isEmpty) return 'Card';
      if (q.cardIds.length > 1) return '${q.cardIds.length} cards';
      return cards
              .where((c) => c.id == q.cardIds.first)
              .firstOrNull
              ?.nickname ??
          'Card';
    }

    String categoryLabel() {
      if (q.categories.isEmpty) return 'Category';
      final first = q.categories.first.label;
      return q.categories.length == 1
          ? first
          : '$first +${q.categories.length - 1}';
    }

    return SizedBox(
      height: 40 * _textScale(context),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
        children: [
          if (q.filterCount > 0)
            _Pill(
              label: 'Clear',
              icon: Icons.close_rounded,
              active: false,
              semanticLabel: 'Clear all filters',
              onTap: () => feed.setQuery(q.cleared()),
            ),
          _Pill(
            label: switch (q.status) {
              TxStatusFilter.all => 'Status',
              TxStatusFilter.pending => 'Pending',
              TxStatusFilter.completed => 'Completed',
            },
            active: q.status != TxStatusFilter.all,
            onTap: () => _openFilter(
              context,
              title: 'Status',
              reset: (d) => d.copyWith(status: TxStatusFilter.all),
              editor: (d, update) => _StatusEditor(draft: d, onChanged: update),
            ),
          ),
          _Pill(
            label: cardLabel(),
            active: q.cardIds.isNotEmpty,
            onTap: () => _openFilter(
              context,
              title: 'Cards',
              reset: (d) => d.copyWith(cardIds: {}),
              editor: (d, update) =>
                  _CardEditor(draft: d, cards: cards, onChanged: update),
            ),
          ),
          _Pill(
            label: categoryLabel(),
            active: q.categories.isNotEmpty,
            onTap: () => _openFilter(
              context,
              title: 'Categories',
              reset: (d) => d.copyWith(categories: {}),
              editor: (d, update) =>
                  _CategoryEditor(draft: d, onChanged: update),
            ),
          ),
          _Pill(
            label: q.hasDate ? (q.rangeLabel ?? 'Custom dates') : 'Date',
            active: q.hasDate,
            onTap: () => _openFilter(
              context,
              title: 'Date',
              reset: (d) => d.withDates(null, null, null),
              editor: (d, update) => _DateEditor(draft: d, onChanged: update),
            ),
          ),
          _Pill(
            label: q.hasAmount
                ? amountLabel(q.minAmount, q.maxAmount)
                : 'Amount',
            active: q.hasAmount,
            onTap: () => _openFilter(
              context,
              title: 'Amount',
              reset: (d) => d.withAmounts(null, null),
              editor: (d, update) => _AmountEditor(draft: d, onChanged: update),
            ),
          ),
        ],
      ),
    );
  }
}

double _textScale(BuildContext context) =>
    (MediaQuery.textScalerOf(context).scale(14) / 14).clamp(1.0, 2.0);

String amountLabel(double? min, double? max) {
  String f(double v) => MoneyFormat.format(v).replaceAll('.00', '');
  if (min != null && max != null) return '${f(min)}–${f(max)}';
  if (min != null) return 'Over ${f(min)}';
  return 'Under ${f(max!)}';
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.active,
    required this.onTap,
    this.icon,
    this.semanticLabel,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final IconData? icon;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = active ? c.onPrimary : c.textPrimary;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Semantics(
        button: true,
        selected: active,
        label: semanticLabel ?? '$label filter',
        excludeSemantics: true,
        child: Material(
          color: active ? c.primary : c.surface,
          shape: StadiumBorder(
            side: active ? BorderSide.none : BorderSide(color: c.border),
          ),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: () {
              HapticFeedback.selectionClick().ignore();
              onTap();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: fg),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Text(
                    label,
                    style: context.text.labelMedium?.copyWith(color: fg),
                  ),
                  if (icon == null) ...[
                    const SizedBox(width: 2),
                    Icon(Icons.expand_more_rounded, size: 18, color: fg),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

typedef _Editor = Widget Function(TxQuery draft, ValueChanged<TxQuery> update);

Future<void> _openFilter(
  BuildContext context, {
  required String title,
  required TxQuery Function(TxQuery) reset,
  required _Editor editor,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _FilterSheet(title: title, reset: reset, editor: editor),
);

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet({
    required this.title,
    required this.reset,
    required this.editor,
  });

  final String title;
  final TxQuery Function(TxQuery) reset;
  final _Editor editor;

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late TxQuery _draft = ref.read(txFeedProvider).query;

  @override
  Widget build(BuildContext context) {
    final count = ref.watch(transactionsProvider).where(_draft.matches).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        0,
        AppSpacing.page,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(widget.title, style: context.text.headlineSmall),
              ),
              TextButton(
                onPressed: () => setState(() => _draft = widget.reset(_draft)),
                child: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Flexible(
            child: SingleChildScrollView(
              child: widget.editor(_draft, (q) => setState(() => _draft = q)),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: count == 0
                ? 'No matching transactions'
                : 'Show $count ${count == 1 ? 'transaction' : 'transactions'}',
            onPressed: count == 0
                ? null
                : () {
                    ref.read(txFeedProvider.notifier).setQuery(_draft);
                    Navigator.of(context).pop();
                  },
          ),
        ],
      ),
    );
  }
}

/// Row with a trailing check, used by the single- and multi-select lists.
class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.title,
    required this.selected,
    required this.onTap,
    this.leading,
    this.subtitle,
    this.multi = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final bool selected;
  final bool multi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: !multi,
      button: true,
      label: title,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: AppRadii.mdAll,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.text.titleSmall),
                    if (subtitle != null)
                      Text(subtitle!, style: context.text.bodySmall),
                  ],
                ),
              ),
              Icon(
                multi
                    ? (selected
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded)
                    : (selected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded),
                color: selected ? c.primary : c.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusEditor extends StatelessWidget {
  const _StatusEditor({required this.draft, required this.onChanged});

  final TxQuery draft;
  final ValueChanged<TxQuery> onChanged;

  @override
  Widget build(BuildContext context) {
    const options = [
      (TxStatusFilter.all, 'All', null),
      (TxStatusFilter.pending, 'Pending', 'Authorized, not posted yet'),
      (TxStatusFilter.completed, 'Completed', 'Posted to your statement'),
    ];
    return Column(
      children: [
        for (final (value, title, subtitle) in options)
          _OptionRow(
            title: title,
            subtitle: subtitle,
            selected: draft.status == value,
            onTap: () => onChanged(draft.copyWith(status: value)),
          ),
      ],
    );
  }
}

class _CardEditor extends StatelessWidget {
  const _CardEditor({
    required this.draft,
    required this.cards,
    required this.onChanged,
  });

  final TxQuery draft;
  final List<PaymentCard> cards;
  final ValueChanged<TxQuery> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final card in cards)
          _OptionRow(
            multi: true,
            title: card.nickname,
            subtitle: '${card.network.label} •• ${card.last4}',
            leading: CardThumb(style: card.style, width: 56),
            selected: draft.cardIds.contains(card.id),
            onTap: () {
              final ids = {...draft.cardIds};
              if (!ids.remove(card.id)) ids.add(card.id);
              onChanged(draft.copyWith(cardIds: ids));
            },
          ),
      ],
    );
  }
}

class _CategoryEditor extends StatelessWidget {
  const _CategoryEditor({required this.draft, required this.onChanged});

  final TxQuery draft;
  final ValueChanged<TxQuery> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final cat in TxCategory.values)
          FilterChip(
            avatar: Icon(
              cat.icon,
              size: 18,
              color: draft.categories.contains(cat) ? c.onPrimary : cat.color,
            ),
            label: Text(cat.label),
            selected: draft.categories.contains(cat),
            showCheckmark: false,
            onSelected: (_) {
              final set = {...draft.categories};
              if (!set.remove(cat)) set.add(cat);
              onChanged(draft.copyWith(categories: set));
            },
          ),
      ],
    );
  }
}

class _DateEditor extends ConsumerWidget {
  const _DateEditor({required this.draft, required this.onChanged});

  final TxQuery draft;
  final ValueChanged<TxQuery> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final today = DateTime(now.year, now.month, now.day);
    final presets = <(String, DateTime, DateTime?)>[
      ('Last 7 days', today.subtract(const Duration(days: 6)), null),
      ('Last 30 days', today.subtract(const Duration(days: 29)), null),
      ('This month', DateTime(now.year, now.month), null),
      (
        'Last month',
        DateTime(now.year, now.month - 1),
        DateTime(now.year, now.month),
      ),
      ('Last 90 days', today.subtract(const Duration(days: 89)), null),
    ];
    final isPreset = presets.any((p) => p.$1 == draft.rangeLabel);

    return Column(
      children: [
        for (final (label, from, to) in presets)
          _OptionRow(
            title: label,
            selected: draft.rangeLabel == label,
            onTap: () => onChanged(draft.withDates(from, to, label)),
          ),
        _OptionRow(
          title: 'Custom range…',
          subtitle: draft.hasDate && !isPreset ? draft.rangeLabel : null,
          selected: draft.hasDate && !isPreset,
          onTap: () async {
            final picked = await showDateRangePicker(
              context: context,
              firstDate: today.subtract(const Duration(days: 365)),
              lastDate: today,
            );
            if (picked == null) return;
            final f = DateFormat.MMMd();
            onChanged(
              draft.withDates(
                picked.start,
                picked.end.add(const Duration(days: 1)),
                '${f.format(picked.start)} – ${f.format(picked.end)}',
              ),
            );
          },
        ),
      ],
    );
  }
}

class _AmountEditor extends StatelessWidget {
  const _AmountEditor({required this.draft, required this.onChanged});

  final TxQuery draft;
  final ValueChanged<TxQuery> onChanged;

  static const double _cap = 20000;

  @override
  Widget build(BuildContext context) {
    final values = RangeValues(
      draft.minAmount ?? 0,
      (draft.maxAmount ?? _cap).clamp(0, _cap),
    );
    const presets = <(String, double?, double?)>[
      ('Under ₱500', null, 500),
      ('₱500–₱2,000', 500, 2000),
      ('Over ₱2,000', 2000, null),
    ];
    String f(double v) => MoneyFormat.format(v).replaceAll('.00', '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          values.end >= _cap
              ? '${f(values.start)} – ${f(_cap)}+'
              : '${f(values.start)} – ${f(values.end)}',
          textAlign: TextAlign.center,
          style: context.text.titleLarge,
        ),
        RangeSlider(
          values: values,
          max: _cap,
          divisions: 100,
          labels: RangeLabels(f(values.start), f(values.end)),
          onChanged: (v) => onChanged(
            draft.withAmounts(
              v.start <= 0 ? null : v.start,
              v.end >= _cap ? null : v.end,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final (label, min, max) in presets)
              ChoiceChip(
                label: Text(label),
                showCheckmark: false,
                selected: draft.minAmount == min && draft.maxAmount == max,
                onSelected: (_) => onChanged(draft.withAmounts(min, max)),
              ),
          ],
        ),
      ],
    );
  }
}
