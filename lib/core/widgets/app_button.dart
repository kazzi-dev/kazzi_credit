import 'dart:async';

import 'package:flutter/services.dart';
import 'package:kazzi_credit/core/theme/app_tokens.dart';
import 'package:kazzi_credit/core/theme/theme_extensions.dart';
import 'package:kazzi_credit/core/widgets/pressable_scale.dart';
import 'package:material_ui/material_ui.dart';

enum AppButtonVariant { primary, accent, secondary, ghost, destructive }

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.expand = true,
  });

  final String label;

  /// Null renders the button disabled.
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;

  /// Shows a spinner and ignores taps while keeping the button's size and
  /// colors, so the layout doesn't jump.
  final bool isLoading;
  final bool expand;

  void _handleTap() {
    if (isLoading) return;
    if (variant != AppButtonVariant.ghost) {
      unawaited(HapticFeedback.lightImpact());
    }
    onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onPressed != null;
    final (bg, fg) = switch (variant) {
      AppButtonVariant.primary => (c.primary, c.onPrimary),
      AppButtonVariant.accent => (c.accent, c.onAccent),
      AppButtonVariant.secondary => (c.surfaceHigh, c.textPrimary),
      AppButtonVariant.ghost => (Colors.transparent, c.textPrimary),
      AppButtonVariant.destructive => (c.error, Colors.white),
    };

    final content = AnimatedSwitcher(
      duration: AppMotion.of(context, AppMotion.fast),
      child: isLoading
          ? SizedBox.square(
              key: const ValueKey('loading'),
              dimension: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: fg),
            )
          : Row(
              key: const ValueKey('label'),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: fg),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.labelLarge?.copyWith(color: fg),
                  ),
                ),
              ],
            ),
    );

    final button = Semantics(
      button: true,
      enabled: enabled,
      label: isLoading ? '$label, loading' : null,
      excludeSemantics: isLoading,
      child: PressableScale(
        enabled: enabled && !isLoading,
        child: Material(
          color: enabled ? bg : c.border,
          borderRadius: AppRadii.lgAll,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? _handleTap : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Center(
                  widthFactor: 1,
                  child: enabled
                      ? content
                      : DefaultTextStyle.merge(
                          style: TextStyle(color: c.textTertiary),
                          child: content,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
