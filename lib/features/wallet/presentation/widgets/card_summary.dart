import 'package:intl/intl.dart';
import 'package:kazzi_credit/core/theme/app_tokens.dart';
import 'package:kazzi_credit/core/theme/theme_extensions.dart';
import 'package:kazzi_credit/core/utils/money_format.dart';
import 'package:kazzi_credit/core/widgets/amount_text.dart';
import 'package:kazzi_credit/features/cards/domain/payment_card.dart';
import 'package:material_ui/material_ui.dart';

/// The active card's numbers as plain rows — no chart, no card chrome.
class CardSummary extends StatelessWidget {
  const CardSummary({required this.card, required this.now, super.key});

  final PaymentCard card;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isCredit = card.kind == CardKind.credit;
    final days = card.daysUntilDue(now);

    String dueText() {
      if (card.statementBalance == 0) return 'No payment due';
      if (card.minimumDue == 0) return 'Minimum paid';
      final when = days <= 0
          ? 'today'
          : days == 1
          ? 'tomorrow'
          : 'in $days days';
      return 'Due $when · ${DateFormat.MMMd().format(card.dueDate)}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isCredit ? 'Current balance' : 'Spent this cycle',
          style: context.text.bodySmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        AmountText(
          card.balance,
          key: ValueKey(card.id),
          style: context.text.displayMedium,
          smallCents: true,
          tabular: false,
        ),
        if (card.tracksCredit) ...[
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: AppRadii.pillAll,
            child: LinearProgressIndicator(
              value: card.utilization,
              minHeight: 4,
              // Lime reads well on dark; on light it's too faint, so ink.
              color: context.isDark ? c.accent : c.textPrimary,
              backgroundColor: c.border,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${MoneyFormat.format(card.available)} available of '
            '${MoneyFormat.format(card.creditLimit).replaceAll('.00', '')}',
            style: context.text.bodySmall,
          ),
        ],
        if (isCredit) ...[
          const SizedBox(height: AppSpacing.lg),
          _DueRow(
            label: dueText(),
            value: card.minimumDue > 0
                ? 'Min ${MoneyFormat.format(card.minimumDue)}'
                : null,
            soon: card.minimumDue > 0 && days <= 3,
          ),
        ],
      ],
    );
  }
}

class _DueRow extends StatelessWidget {
  const _DueRow({required this.label, this.value, this.soon = false});

  final String label;
  final String? value;

  /// Due within 3 days: a caution tint, with an icon so it's not color-only.
  final bool soon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: soon ? c.warning.withValues(alpha: 0.1) : c.surfaceHigh,
        borderRadius: AppRadii.mdAll,
      ),
      child: Row(
        children: [
          Icon(
            soon ? Icons.schedule_rounded : Icons.event_outlined,
            size: 18,
            color: soon ? c.warning : c.textSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(label, style: context.text.bodyMedium)),
          if (value != null) Text(value!, style: context.text.titleSmall),
        ],
      ),
    );
  }
}
