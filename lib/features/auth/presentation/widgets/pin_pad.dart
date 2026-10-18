import 'dart:async';

import 'package:flutter/services.dart';
import 'package:kazzi_credit/core/theme/app_tokens.dart';
import 'package:kazzi_credit/core/theme/theme_extensions.dart';
import 'package:kazzi_credit/core/widgets/pressable_scale.dart';
import 'package:material_ui/material_ui.dart';

/// Custom numeric keypad. Avoids the system keyboard so the layout is
/// stable and third-party keyboards never see the PIN.
class PinPad extends StatelessWidget {
  const PinPad({
    required this.onDigit,
    required this.onBackspace,
    super.key,
    this.onClear,
    this.leading,
    this.enabled = true,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  /// Long-press on backspace.
  final VoidCallback? onClear;

  /// Bottom-left slot, e.g. the biometric button.
  final Widget? leading;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    Widget digit(String d) => _PinKey(
      semanticLabel: d,
      enabled: enabled,
      onTap: () => onDigit(d),
      child: Text(d, style: context.text.headlineMedium),
    );

    final rows = [
      for (final r in const [
        ['1', '2', '3'],
        ['4', '5', '6'],
        ['7', '8', '9'],
      ])
        [for (final d in r) digit(d)],
      [
        leading ?? const SizedBox(width: _PinKey.size, height: _PinKey.size),
        digit('0'),
        _PinKey(
          semanticLabel: 'Delete',
          enabled: enabled,
          filled: false,
          onTap: onBackspace,
          onLongPress: onClear,
          child: Icon(
            Icons.backspace_outlined,
            color: context.colors.textPrimary,
          ),
        ),
      ],
    ];

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: row,
              ),
            ),
        ],
      ),
    );
  }
}

/// A round key. Public so screens can build matching extra keys (the
/// biometric button).
class PinPadKey extends StatelessWidget {
  const PinPadKey({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
    super.key,
    this.enabled = true,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return _PinKey(
      semanticLabel: semanticLabel,
      enabled: enabled,
      filled: false,
      onTap: onTap,
      child: Icon(icon, size: 30, color: context.colors.primary),
    );
  }
}

class _PinKey extends StatelessWidget {
  const _PinKey({
    required this.child,
    required this.semanticLabel,
    required this.onTap,
    required this.enabled,
    this.onLongPress,
    this.filled = true,
  });

  static const double size = 76;

  final Widget child;
  final String semanticLabel;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool enabled;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: semanticLabel,
      enabled: enabled,
      excludeSemantics: true,
      child: PressableScale(
        enabled: enabled,
        scale: 0.9,
        child: SizedBox.square(
          dimension: size,
          child: Material(
            color: filled ? c.surfaceHigh : Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: enabled
                  ? () {
                      unawaited(HapticFeedback.selectionClick());
                      onTap();
                    }
                  : null,
              onLongPress: enabled ? onLongPress : null,
              child: Center(
                child: AnimatedOpacity(
                  opacity: enabled ? 1 : 0.35,
                  duration: AppMotion.of(context, AppMotion.fast),
                  // Digits must stay one size inside a fixed circle, even at
                  // large text scales.
                  child: MediaQuery.withNoTextScaling(child: child),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
