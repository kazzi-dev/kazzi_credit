import 'package:kazzi_credit/core/theme/app_tokens.dart';
import 'package:kazzi_credit/core/theme/theme_extensions.dart';
import 'package:material_ui/material_ui.dart';

class KazziLogo extends StatelessWidget {
  const KazziLogo({super.key, this.size = 40, this.showWordmark = false});

  final double size;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final mark = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.accent,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Text(
        'K',
        style: TextStyle(
          fontSize: size * 0.55,
          fontWeight: FontWeight.w800,
          color: c.onAccent,
          height: 1,
        ),
      ),
    );
    if (!showWordmark) return ExcludeSemantics(child: mark);
    return Semantics(
      label: 'Kazzi Credit',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          mark,
          const SizedBox(width: AppSpacing.sm),
          Text('Kazzi', style: context.text.titleLarge),
        ],
      ),
    );
  }
}
