import 'package:flutter/services.dart';
import 'package:kazzi_credit/core/theme/app_tokens.dart';
import 'package:kazzi_credit/core/theme/card_styles.dart';
import 'package:kazzi_credit/core/theme/theme_extensions.dart';
import 'package:material_ui/material_ui.dart';

class CardThemePicker extends StatelessWidget {
  const CardThemePicker({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final CardStyle selected;
  final ValueChanged<CardStyle> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        for (final g in CardStyle.all)
          _Swatch(
            style: g,
            selected: g.id == selected.id,
            onTap: () {
              HapticFeedback.selectionClick().ignore();
              onChanged(g);
            },
          ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final CardStyle style;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: '${style.name} style',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.of(context, AppMotion.fast),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? c.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: AnimatedScale(
            scale: selected ? 1 : 0.9,
            duration: AppMotion.of(context, AppMotion.fast),
            curve: AppMotion.bounce,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: style.color,
                border: Border.all(color: c.border),
              ),
              child: selected
                  ? Icon(Icons.check_rounded, color: style.foreground, size: 22)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
