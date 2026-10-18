import 'package:intl/intl.dart';
import 'package:kazzi_credit/core/theme/app_colors.dart';
import 'package:kazzi_credit/core/theme/app_tokens.dart';
import 'package:kazzi_credit/core/theme/theme_extensions.dart';
import 'package:kazzi_credit/core/utils/money_format.dart';
import 'package:kazzi_credit/core/widgets/amount_text.dart';
import 'package:kazzi_credit/features/cards/domain/payment_card.dart';
import 'package:material_ui/material_ui.dart';

/// Totals across every card, on the brand navy with a lime accent — the
/// one bold block on the wallet screen.
class WalletOverview extends StatelessWidget {
  const WalletOverview({required this.cards, required this.now, super.key});

  final List<PaymentCard> cards;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const fg = Colors.white;
    final muted = fg.withValues(alpha: 0.64);
    final owed = cards.fold<double>(0, (s, x) => s + x.balance);
    final available = cards
        .where((x) => x.tracksCredit)
        .fold<double>(0, (s, x) => s + x.available);
    final due = cards.where((x) => x.minimumDue > 0).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final next = due.firstOrNull;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.isDark ? c.surfaceHigh : AppPalette.navy900,
        borderRadius: AppRadii.xlAll,
        border: context.isDark ? Border.all(color: c.border) : null,
      ),
      child: Stack(
        children: [
          // Brand echo: the same lime ring printed on the Midnight card.
          Positioned(
            right: -46,
            top: -46,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: c.accent, width: 10),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Total balance',
                      style: context.text.bodySmall?.copyWith(color: muted),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: fg.withValues(alpha: 0.12),
                        borderRadius: AppRadii.pillAll,
                      ),
                      child: Text(
                        '${cards.length} ${cards.length == 1 ? 'card' : 'cards'}',
                        style: context.text.labelSmall?.copyWith(
                          color: fg,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                AmountText(
                  owed,
                  style: context.text.displayMedium?.copyWith(color: fg),
                  smallCents: true,
                  tabular: false,
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: _Stat(
                        label: 'Available credit',
                        value: MoneyFormat.format(available),
                        muted: muted,
                      ),
                    ),
                    if (next != null)
                      Expanded(
                        child: _Stat(
                          label: 'Next due · ${next.nickname}',
                          value:
                              '${DateFormat.MMMd().format(next.dueDate)} · '
                              '${MoneyFormat.format(next.minimumDue)}',
                          muted: muted,
                          dot: c.accent,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.muted,
    this.dot,
  });

  final String label;
  final String value;
  final Color muted;
  final Color? dot;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (dot != null) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall?.copyWith(color: muted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.titleSmall?.copyWith(color: Colors.white),
        ),
      ],
    );
  }
}
