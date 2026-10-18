import 'package:kazzi_credit/core/theme/app_tokens.dart';
import 'package:kazzi_credit/core/theme/theme_extensions.dart';
import 'package:material_ui/material_ui.dart';

/// Rounded surface grouping rows, with inset dividers between them.
class SurfacePanel extends StatelessWidget {
  const SurfacePanel({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: AppRadii.lgAll,
        border: context.isDark ? Border.all(color: c.border) : null,
        boxShadow: context.isDark ? null : AppShadows.soft,
      ),
      child: Material(
        type: MaterialType.transparency,
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
      ),
    );
  }
}
