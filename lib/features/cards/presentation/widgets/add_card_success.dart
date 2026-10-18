import 'package:flutter_animate/flutter_animate.dart';
import 'package:kazzi_credit/core/theme/app_tokens.dart';
import 'package:kazzi_credit/core/theme/theme_extensions.dart';
import 'package:kazzi_credit/core/widgets/app_button.dart';
import 'package:kazzi_credit/core/widgets/fill_scroll.dart';
import 'package:kazzi_credit/features/cards/domain/payment_card.dart';
import 'package:kazzi_credit/features/cards/presentation/widgets/card_front.dart';
import 'package:material_ui/material_ui.dart';

/// Shown after a card is saved: a check pops in with a pulse, then the new
/// card rises into place.
class AddCardSuccess extends StatelessWidget {
  const AddCardSuccess({required this.card, required this.onDone, super.key});

  final PaymentCard card;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final slow = AppMotion.of(context, AppMotion.slow);
    return SafeArea(
      child: FillScroll(
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Column(
          children: [
            const Spacer(),
            Stack(
              alignment: Alignment.center,
              children: [
                // Pulse ring.
                Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c.accent.withValues(alpha: 0.35),
                      ),
                    )
                    .animate(delay: 200.ms)
                    .scale(
                      begin: const Offset(0.6, 0.6),
                      end: const Offset(1.5, 1.5),
                      duration: AppMotion.of(context, 900.ms),
                      curve: Curves.easeOut,
                    )
                    .fadeOut(duration: AppMotion.of(context, 900.ms)),
                Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c.accent,
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 48,
                        color: c.onAccent,
                      ),
                    )
                    .animate()
                    .scale(
                      begin: const Offset(0.3, 0.3),
                      duration: slow,
                      curve: AppMotion.bounce,
                    )
                    .fadeIn(duration: AppMotion.of(context, AppMotion.fast)),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Semantics(
              liveRegion: true,
              child: Text('Card added', style: context.text.headlineMedium),
            ).animate(delay: 150.ms).fadeIn(duration: slow).slideY(begin: 0.3),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${card.nickname} •• ${card.last4} is ready in your wallet.',
              textAlign: TextAlign.center,
              style: context.text.bodyLarge?.copyWith(color: c.textSecondary),
            ).animate(delay: 220.ms).fadeIn(duration: slow),
            const SizedBox(height: AppSpacing.xxl),
            ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: CardFront(
                    style: card.style,
                    last4: card.last4,
                    network: card.network,
                    holder: card.holder,
                    expiry: card.expiry,
                    kindLabel: card.kind.label,
                    nickname: card.nickname,
                  ),
                )
                .animate(delay: 300.ms)
                .fadeIn(duration: slow)
                .slideY(
                  begin: 0.4,
                  duration: slow,
                  curve: AppMotion.emphasized,
                ),
            const Spacer(),
            const SizedBox(height: AppSpacing.xl),
            AppButton(label: 'Go to wallet', onPressed: onDone),
          ],
        ),
      ),
    );
  }
}
