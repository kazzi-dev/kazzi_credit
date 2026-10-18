import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kazzi_credit/core/theme/app_tokens.dart';
import 'package:kazzi_credit/core/theme/theme_extensions.dart';
import 'package:kazzi_credit/core/utils/money_format.dart';
import 'package:kazzi_credit/core/widgets/app_button.dart';
import 'package:kazzi_credit/core/widgets/app_toast.dart';
import 'package:kazzi_credit/features/insights/application/insights_controller.dart';
import 'package:kazzi_credit/features/transactions/domain/card_transaction.dart';
import 'package:material_ui/material_ui.dart';

/// Create or edit a monthly budget. With no [category], the user picks one
/// of the categories that doesn't have a budget yet.
Future<void> showBudgetSheet(
  BuildContext context, {
  TxCategory? category,
  double? lastMonthSpend,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _BudgetSheet(category: category, lastMonth: lastMonthSpend),
);

class _BudgetSheet extends ConsumerStatefulWidget {
  const _BudgetSheet({this.category, this.lastMonth});

  final TxCategory? category;
  final double? lastMonth;

  @override
  ConsumerState<_BudgetSheet> createState() => _BudgetSheetState();
}

class _BudgetSheetState extends ConsumerState<_BudgetSheet> {
  static const _presets = <double>[2000, 5000, 10000, 15000, 25000];
  late TxCategory? _category = widget.category;
  late double _amount =
      ref.read(budgetsProvider)[widget.category] ??
      ((widget.lastMonth ?? 5000) / 500).ceil() * 500.0;

  bool get _editing =>
      widget.category != null &&
      ref.read(budgetsProvider).containsKey(widget.category);

  void _save() {
    final cat = _category;
    if (cat == null) return;
    ref.read(budgetsProvider.notifier).set(cat, _amount);
    HapticFeedback.mediumImpact().ignore();
    Navigator.of(context).pop();
    showAppToast(
      context,
      '${cat.label} budget set to ${MoneyFormat.format(_amount)}',
      tone: ToastTone.success,
    );
  }

  void _remove() {
    final cat = _category!;
    final previous = ref.read(budgetsProvider)[cat];
    final budgets = ref.read(budgetsProvider.notifier)..set(cat, null);
    Navigator.of(context).pop();
    showAppToast(
      context,
      '${cat.label} budget removed',
      onUndo: () => budgets.set(cat, previous),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final existing = ref.watch(budgetsProvider);
    final cat = _category;
    final choices = TxCategory.values
        .where((x) => x != TxCategory.refund && !existing.containsKey(x))
        .toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.page,
        0,
        AppSpacing.page,
        AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            cat == null ? 'New budget' : '${cat.label} budget',
            style: context.text.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'A monthly limit. We warn you at 80% and when you go over.',
            style: context.text.bodyMedium?.copyWith(color: c.textSecondary),
          ),
          if (widget.category == null) ...[
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final x in choices)
                  ChoiceChip(
                    avatar: Icon(
                      x.icon,
                      size: 18,
                      color: x == cat ? c.onPrimary : x.color,
                    ),
                    label: Text(x.label),
                    showCheckmark: false,
                    selected: x == cat,
                    onSelected: (_) => setState(() => _category = x),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Text(
              MoneyFormat.format(_amount).replaceAll('.00', ''),
              style: context.text.displayMedium,
            ),
          ),
          Center(child: Text('per month', style: context.text.bodySmall)),
          Slider(
            value: _amount,
            min: 500,
            max: 50000,
            divisions: 99,
            label: MoneyFormat.format(_amount).replaceAll('.00', ''),
            onChanged: (v) => setState(() => _amount = v),
          ),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final p in _presets)
                ChoiceChip(
                  label: Text(MoneyFormat.format(p).replaceAll('.00', '')),
                  showCheckmark: false,
                  selected: _amount == p,
                  onSelected: (_) => setState(() => _amount = p),
                ),
            ],
          ),
          if (widget.lastMonth != null && widget.lastMonth! > 0) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'You spent ${MoneyFormat.format(widget.lastMonth!)} on this '
              'last month.',
              style: context.text.bodySmall,
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: _editing ? 'Save budget' : 'Set budget',
            onPressed: cat == null ? null : _save,
          ),
          if (_editing) ...[
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Remove budget',
              variant: AppButtonVariant.ghost,
              onPressed: _remove,
            ),
          ],
        ],
      ),
    );
  }
}
