import 'package:intl/intl.dart';
import 'package:kazzi_credit/core/theme/app_tokens.dart';
import 'package:kazzi_credit/core/theme/theme_extensions.dart';
import 'package:kazzi_credit/core/widgets/amount_text.dart';
import 'package:kazzi_credit/features/transactions/domain/card_transaction.dart';
import 'package:material_ui/material_ui.dart';

/// Hero tag for a transaction's avatar. [source] keeps tags unique when
/// the same transaction is listed on two tabs.
String txHeroTag(String source, String txId) => 'tx-$source-$txId';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    required this.tx,
    required this.now,
    super.key,
    this.onTap,
    this.heroSource,
    this.showTime = false,
  });

  final CardTransaction tx;
  final DateTime now;
  final VoidCallback? onTap;

  /// Enables the avatar hero into the detail screen.
  final String? heroSource;

  /// Under a day header, the time is more useful than "Yesterday".
  final bool showTime;

  String _when() {
    if (showTime) return DateFormat.jm().format(tx.date);
    final day = DateTime(tx.date.year, tx.date.month, tx.date.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return DateFormat.jm().format(tx.date);
    if (diff == 1) return 'Yesterday';
    return DateFormat.MMMd().format(tx.date);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final avatar = MerchantAvatar(tx: tx);
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.mdAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            if (heroSource != null)
              Hero(tag: txHeroTag(heroSource!, tx.id), child: avatar)
            else
              avatar,
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          tx.merchant,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.titleSmall,
                        ),
                      ),
                      if (tx.dispute != null) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Icon(Icons.flag_rounded, size: 14, color: c.error),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          tx.note ?? '${tx.category.label} · ${_when()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.bodySmall?.copyWith(
                            fontStyle: tx.note != null
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                        ),
                      ),
                      if (tx.isPending) ...[
                        const SizedBox(width: AppSpacing.sm),
                        const PendingBadge(),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            AmountText(
              tx.amount,
              signed: tx.isRefund,
              colorize: true,
              style: context.text.titleSmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Merchant initial on a tinted square, with the category icon as a badge.
class MerchantAvatar extends StatelessWidget {
  const MerchantAvatar({required this.tx, super.key, this.size = 44});

  final CardTransaction tx;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cat = tx.category;
    final badge = size * 0.42;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size + badge * 0.25,
        child: Stack(
          children: [
            Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: cat.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(size * 0.3),
              ),
              child: Text(
                tx.merchant.characters.first.toUpperCase(),
                style: TextStyle(
                  fontSize: size * 0.42,
                  fontWeight: FontWeight.w800,
                  color: cat.color,
                  height: 1,
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: badge,
                height: badge,
                decoration: BoxDecoration(
                  color: cat.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.background, width: 2),
                ),
                child: Icon(cat.icon, size: badge * 0.55, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PendingBadge extends StatelessWidget {
  const PendingBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: c.warning.withValues(alpha: 0.14),
        borderRadius: AppRadii.pillAll,
      ),
      child: Text(
        'Pending',
        style: context.text.labelSmall?.copyWith(
          color: c.warning,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
