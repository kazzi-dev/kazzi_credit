import 'package:go_router/go_router.dart';
import 'package:kazzi_credit/core/router/routes.dart';
import 'package:kazzi_credit/core/theme/app_tokens.dart';
import 'package:kazzi_credit/core/theme/card_styles.dart';
import 'package:kazzi_credit/core/theme/theme_extensions.dart';
import 'package:kazzi_credit/core/widgets/app_button.dart';
import 'package:kazzi_credit/core/widgets/fill_scroll.dart';
import 'package:kazzi_credit/core/widgets/kazzi_logo.dart';
import 'package:kazzi_credit/features/cards/presentation/widgets/card_front.dart';
import 'package:material_ui/material_ui.dart';

/// One calm welcome screen: what the app does in three lines, then start.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final width = MediaQuery.sizeOf(context).width;
    return Scaffold(
      body: Stack(
        children: [
          // Three cards fanned out from the right edge.
          for (final (style, last4, name, angle, dx, dy) in const [
            (CardStyle.lime, '3456', 'Rewards', 0.16, 0.30, 0.0),
            (CardStyle.ocean, '9012', 'Travel', 0.02, 0.22, 64.0),
            (CardStyle.midnight, '4821', 'Everyday', -0.14, 0.12, 136.0),
          ])
            Positioned(
              top: MediaQuery.paddingOf(context).top + 56 + dy,
              right: -width * dx,
              width: width * 0.72,
              child: Transform.rotate(
                angle: angle,
                child: ExcludeSemantics(
                  child: CardFront(style: style, last4: last4, nickname: name),
                ),
              ),
            ),
          SafeArea(
            child: FillScroll(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page + 4,
                AppSpacing.lg,
                AppSpacing.page + 4,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const KazziLogo(size: 32, showWordmark: true),
                  const Spacer(flex: 4),
                  Text(
                    'All your cards.\nOne calm place.',
                    style: context.text.displayMedium?.copyWith(
                      fontFeatures: const [],
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const _Point(
                    icon: Icons.account_balance_wallet_outlined,
                    text: 'See every balance and due date at a glance',
                  ),
                  const _Point(
                    icon: Icons.notifications_none_rounded,
                    text: 'Know the moment your card is used',
                  ),
                  const _Point(
                    icon: Icons.fingerprint_rounded,
                    text: 'Locked with your PIN and fingerprint',
                  ),
                  const Spacer(),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    label: 'Get started',
                    onPressed: () => context.go(AppRoutes.profileSetup),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Center(
                    child: Text(
                      'Your data stays on this phone.',
                      style: context.text.bodySmall?.copyWith(
                        color: c.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, size: 20, color: c.textSecondary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: context.text.bodyLarge?.copyWith(color: c.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
