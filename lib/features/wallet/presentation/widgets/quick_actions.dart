import 'package:kazzi_credit/core/theme/app_tokens.dart';
import 'package:kazzi_credit/core/theme/theme_extensions.dart';
import 'package:material_ui/material_ui.dart';

class QuickAction {
  const QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.primary = false,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Icon color, shown on a soft tint of itself.
  final Color? color;

  /// The main action: solid brand lime.
  final bool primary;

  /// Active state (e.g. frozen): solid ink.
  final bool highlighted;
}

/// Round icon buttons with a label underneath.
class QuickActions extends StatelessWidget {
  const QuickActions({required this.actions, super.key});

  final List<QuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final a in actions) Expanded(child: _ActionButton(action: a)),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action});

  final QuickAction action;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tint = action.color ?? c.textPrimary;
    final (bg, fg) = action.highlighted
        ? (c.textPrimary, c.background)
        : action.primary
        ? (c.accent, c.onAccent)
        : (tint.withValues(alpha: context.isDark ? 0.22 : 0.12), tint);
    return Semantics(
      button: true,
      label: action.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: AppRadii.lgAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Column(
            children: [
              AnimatedContainer(
                duration: AppMotion.of(context, AppMotion.fast),
                width: 54,
                height: 54,
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                child: Icon(action.icon, size: 22, color: fg),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                action.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.labelMedium?.copyWith(
                  color: c.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
