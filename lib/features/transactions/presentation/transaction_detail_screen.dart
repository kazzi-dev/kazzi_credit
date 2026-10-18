import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kazzi_credit/core/theme/app_tokens.dart';
import 'package:kazzi_credit/core/theme/theme_extensions.dart';
import 'package:kazzi_credit/core/widgets/amount_text.dart';
import 'package:kazzi_credit/core/widgets/app_button.dart';
import 'package:kazzi_credit/core/widgets/app_sheet.dart';
import 'package:kazzi_credit/core/widgets/empty_state.dart';
import 'package:kazzi_credit/features/cards/application/cards_controller.dart';
import 'package:kazzi_credit/features/cards/presentation/widgets/card_thumb.dart';
import 'package:kazzi_credit/features/transactions/application/transactions_controller.dart';
import 'package:kazzi_credit/features/transactions/domain/card_transaction.dart';
import 'package:kazzi_credit/features/transactions/presentation/widgets/map_preview.dart';
import 'package:kazzi_credit/features/transactions/presentation/widgets/status_timeline.dart';
import 'package:kazzi_credit/features/transactions/presentation/widgets/transaction_tile.dart';
import 'package:kazzi_credit/features/transactions/presentation/widgets/tx_sheets.dart';
import 'package:material_ui/material_ui.dart';

class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({required this.id, super.key, this.from});

  final String id;

  /// Which list opened this, for the avatar hero.
  final String? from;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tx = ref.watch(transactionByIdProvider(id));
    if (tx == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: EmptyState(
            icon: Icons.receipt_long_rounded,
            title: 'Transaction not found',
            message: 'It may have been removed by your bank.',
          ),
        ),
      );
    }
    final c = context.colors;
    final now = ref.watch(clockProvider)();
    final avatar = MerchantAvatar(tx: tx, size: 72);

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          0,
          AppSpacing.page,
          AppSpacing.xxxl,
        ),
        children: [
          Center(
            child: from == null
                ? avatar
                : Hero(tag: txHeroTag(from!, tx.id), child: avatar),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            tx.merchant,
            textAlign: TextAlign.center,
            style: context.text.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            DateFormat('EEEE, MMM d · h:mm a').format(tx.date),
            textAlign: TextAlign.center,
            style: context.text.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: AmountText(
              tx.amount,
              signed: tx.isRefund,
              colorize: true,
              smallCents: true,
              style: context.text.displayMedium,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(child: _StatusPill(tx: tx)),
          if (tx.dispute != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _DisputeBanner(reason: tx.dispute!),
          ],
          const SizedBox(height: AppSpacing.xl),
          MapPreview(merchant: tx.merchant),
          const SizedBox(height: AppSpacing.lg),
          _Panel(
            children: [
              _Row(
                label: 'Category',
                onTap: () => changeCategory(context, ref, tx),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(tx.category.icon, size: 18, color: tx.category.color),
                    const SizedBox(width: AppSpacing.xs),
                    Text(tx.category.label, style: context.text.titleSmall),
                    Icon(Icons.chevron_right_rounded, color: c.textTertiary),
                  ],
                ),
              ),
              _PaidWithRow(cardId: tx.cardId),
              _Row(
                label: 'Reference',
                trailing: Text(
                  tx.id.toUpperCase().replaceAll('_', '-'),
                  style: context.text.bodyMedium?.copyWith(
                    color: c.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Status', style: context.text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          StatusTimeline(tx: tx, now: now),
          const SizedBox(height: AppSpacing.xl),
          Text('Notes & receipt', style: context.text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          if (tx.note != null)
            _Panel(
              children: [
                _Row(
                  label: tx.note!,
                  labelStyle: context.text.bodyMedium,
                  onTap: () => editNote(context, ref, tx),
                  trailing: Icon(Icons.edit_outlined, color: c.textTertiary),
                ),
              ],
            )
          else
            AppButton(
              label: 'Add a note',
              icon: Icons.sticky_note_2_outlined,
              variant: AppButtonVariant.secondary,
              onPressed: () => editNote(context, ref, tx),
            ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Attach receipt',
            icon: Icons.receipt_outlined,
            variant: AppButtonVariant.secondary,
            onPressed: () => showAppSheet<void>(
              context: context,
              title: 'Receipts',
              message:
                  'Snapping a photo of your receipt is coming soon. It will '
                  'be stored privately on this device.',
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (tx.dispute == null)
            TextButton.icon(
              onPressed: () => reportProblem(context, ref, tx),
              style: TextButton.styleFrom(foregroundColor: c.error),
              icon: const Icon(Icons.flag_outlined),
              label: const Text('Report a problem'),
            ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.tx});

  final CardTransaction tx;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (label, color, icon) = tx.isPending
        ? ('Pending', c.warning, Icons.schedule_rounded)
        : tx.isRefund
        ? ('Refunded', c.success, Icons.undo_rounded)
        : ('Completed', c.success, Icons.check_circle_rounded);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadii.pillAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: context.text.labelMedium?.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _DisputeBanner extends StatelessWidget {
  const _DisputeBanner({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: c.error.withValues(alpha: 0.08),
          borderRadius: AppRadii.lgAll,
          border: Border.all(color: c.error.withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.flag_rounded, color: c.error),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "We're reviewing this charge",
                    style: context.text.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text('You reported: $reason', style: context.text.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: AppRadii.lgAll,
        border: context.isDark ? Border.all(color: c.border) : null,
        boxShadow: context.isDark ? null : AppShadows.soft,
      ),
      child: Column(
        children: [
          for (final (i, child) in children.indexed) ...[
            if (i > 0)
              Divider(
                indent: AppSpacing.lg,
                endIndent: AppSpacing.lg,
                color: c.border,
              ),
            child,
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.trailing,
    this.onTap,
    this.labelStyle,
  });

  final String label;
  final Widget trailing;
  final VoidCallback? onTap;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.lgAll,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style:
                      labelStyle ??
                      context.text.bodyMedium?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _PaidWithRow extends ConsumerWidget {
  const _PaidWithRow({required this.cardId});

  final String cardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = ref
        .watch(cardsProvider)
        .where((c) => c.id == cardId)
        .firstOrNull;
    return _Row(
      label: 'Paid with',
      trailing: card == null
          ? Text('Removed card', style: context.text.titleSmall)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CardThumb(style: card.style, width: 40),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${card.nickname} •• ${card.last4}',
                  style: context.text.titleSmall,
                ),
              ],
            ),
    );
  }
}
