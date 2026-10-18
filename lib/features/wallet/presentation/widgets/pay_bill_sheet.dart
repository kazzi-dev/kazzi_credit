import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kazzi_credit/core/theme/app_tokens.dart';
import 'package:kazzi_credit/core/theme/theme_extensions.dart';
import 'package:kazzi_credit/core/utils/money_format.dart';
import 'package:kazzi_credit/core/widgets/amount_text.dart';
import 'package:kazzi_credit/core/widgets/app_button.dart';
import 'package:kazzi_credit/core/widgets/app_toast.dart';
import 'package:kazzi_credit/features/cards/application/cards_controller.dart';
import 'package:kazzi_credit/features/cards/domain/payment_card.dart';
import 'package:material_ui/material_ui.dart';

Future<void> showPayBillSheet(BuildContext context, PaymentCard card) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _PayBillSheet(card: card),
    );

class _PayBillSheet extends ConsumerStatefulWidget {
  const _PayBillSheet({required this.card});

  final PaymentCard card;

  @override
  ConsumerState<_PayBillSheet> createState() => _PayBillSheetState();
}

class _PayBillSheetState extends ConsumerState<_PayBillSheet> {
  late final List<(String, String, double)> _options = [
    (
      'Statement balance',
      'Avoids interest this cycle',
      widget.card.statementBalance,
    ),
    ('Current balance', 'Everything owed today', widget.card.balance),
    (
      'Minimum due',
      'Keeps the account in good standing',
      widget.card.minimumDue,
    ),
  ].where((o) => o.$3 > 0).toList();

  int _selected = 0;
  bool _paying = false;

  Future<void> _pay() async {
    final amount = _options[_selected].$3;
    setState(() => _paying = true);
    // Mock network call.
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    ref.read(cardsProvider.notifier).pay(widget.card.id, amount);
    HapticFeedback.mediumImpact().ignore();
    if (!mounted) return;
    // The app-level messenger outlives this sheet, so the toast stays.
    showAppToast(
      context,
      'Payment of ${MoneyFormat.format(amount)} sent',
      tone: ToastTone.success,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (_options.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          'Nothing to pay right now.',
          textAlign: TextAlign.center,
          style: context.text.titleMedium,
        ),
      );
    }
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
          Text(
            'Pay ${widget.card.nickname}',
            style: context.text.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'From Checking •• 2231',
            style: context.text.bodyMedium?.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          for (final (i, (title, subtitle, amount)) in _options.indexed) ...[
            _OptionTile(
              title: title,
              subtitle: subtitle,
              amount: amount,
              selected: i == _selected,
              onTap: _paying ? null : () => setState(() => _selected = i),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Pay ${MoneyFormat.format(_options[_selected].$3)}',
            isLoading: _paying,
            onPressed: _pay,
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final double amount;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: selected ? c.primarySoft : c.surfaceHigh,
        borderRadius: AppRadii.lgAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.lgAll,
          child: AnimatedContainer(
            duration: AppMotion.of(context, AppMotion.fast),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: AppRadii.lgAll,
              border: Border.all(
                color: selected ? c.primary : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: selected ? c.primary : c.textTertiary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: context.text.titleSmall),
                      Text(subtitle, style: context.text.bodySmall),
                    ],
                  ),
                ),
                AmountText(amount, style: context.text.titleSmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
