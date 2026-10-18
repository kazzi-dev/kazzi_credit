import 'package:kazzi_credit/core/theme/card_styles.dart';
import 'package:kazzi_credit/features/cards/presentation/widgets/card_surface.dart';
import 'package:material_ui/material_ui.dart';

/// Small card swatch for lists, where the full face would be unreadable.
class CardThumb extends StatelessWidget {
  const CardThumb({required this.style, super.key, this.width = 44});

  final CardStyle style;
  final double width;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        child: CardSurface(
          style: style,
          elevated: false,
          child: const SizedBox.shrink(),
        ),
      ),
    );
  }
}
