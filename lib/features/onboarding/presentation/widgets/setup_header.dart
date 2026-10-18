import 'package:kazzi_credit/core/theme/app_tokens.dart';
import 'package:kazzi_credit/core/theme/theme_extensions.dart';
import 'package:material_ui/material_ui.dart';

/// Back button + segmented progress for the post-intro setup steps.
class SetupHeader extends StatelessWidget {
  const SetupHeader({
    required this.step,
    super.key,
    this.total = 3,
    this.onBack,
  });

  /// 1-based.
  final int step;
  final int total;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: AppSpacing.minTouch,
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              tooltip: 'Back',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            )
          else
            const SizedBox(width: AppSpacing.minTouch),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Semantics(
              label: 'Step $step of $total',
              excludeSemantics: true,
              child: Row(
                children: [
                  for (var i = 1; i <= total; i++) ...[
                    if (i > 1) const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: AnimatedContainer(
                        duration: AppMotion.of(context, AppMotion.slow),
                        curve: AppMotion.standard,
                        height: 4,
                        decoration: BoxDecoration(
                          color: i <= step ? c.primary : c.border,
                          borderRadius: AppRadii.pillAll,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Text('$step/$total', style: context.text.labelMedium),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
    );
  }
}
