import 'package:kazzi_credit/core/theme/app_tokens.dart';
import 'package:kazzi_credit/core/theme/theme_extensions.dart';
import 'package:kazzi_credit/core/widgets/app_button.dart';
import 'package:material_ui/material_ui.dart';

/// Shown when a list has nothing in it, or failed to load (pass
/// [isError] to switch to the error tint and a retry action).
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
    this.actionLabel,
    this.onAction,
    this.isError = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tint = isError ? c.error : c.primary;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: tint),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            title,
            textAlign: TextAlign.center,
            style: context.text.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: context.text.bodyMedium?.copyWith(color: c.textSecondary),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: actionLabel!,
              onPressed: onAction,
              expand: false,
              variant: isError
                  ? AppButtonVariant.secondary
                  : AppButtonVariant.primary,
              icon: isError ? Icons.refresh_rounded : null,
            ),
          ],
        ],
      ),
    );
  }
}
