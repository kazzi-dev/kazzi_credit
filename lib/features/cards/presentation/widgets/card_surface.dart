import 'package:kazzi_credit/core/theme/card_styles.dart';
import 'package:kazzi_credit/features/cards/presentation/widgets/card_pattern.dart';
import 'package:material_ui/material_ui.dart';

/// Reference width the card layout is designed at; everything scales from
/// it so thumbnails and full-width cards share one layout.
const double kCardDesignWidth = 340;
const double kCardAspectRatio = 1.586; // ISO/IEC 7810 ID-1

/// The card material: a flat fill with its printed graphic, a hairline edge
/// and a soft neutral shadow. Front and back both use it.
class CardSurface extends StatelessWidget {
  const CardSurface({
    required this.style,
    required this.child,
    super.key,
    this.elevated = true,
    this.frozen = false,
  });

  final CardStyle style;
  final Widget child;
  final bool elevated;
  final bool frozen;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: kCardAspectRatio,
      child: LayoutBuilder(
        builder: (context, box) {
          final s = box.maxWidth / kCardDesignWidth;
          final radius = BorderRadius.circular(20 * s.clamp(0.5, 1.2));
          return DecoratedBox(
            decoration: BoxDecoration(
              color: style.color,
              borderRadius: radius,
              border: Border.all(
                color: style.foreground.withValues(alpha: 0.08),
              ),
              boxShadow: elevated
                  ? [
                      BoxShadow(
                        color: const Color(0xFF0B1330).withValues(alpha: 0.12),
                        blurRadius: 24 * s,
                        offset: Offset(0, 10 * s),
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(painter: CardPatternPainter(style)),
                  child,
                  if (frozen) _FrozenOverlay(scale: s),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FrozenOverlay extends StatelessWidget {
  const _FrozenOverlay({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF4F6FA).withValues(alpha: 0.72),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.ac_unit_rounded,
              size: 18 * scale,
              color: const Color(0xFF15171E),
            ),
            SizedBox(width: 6 * scale),
            Text(
              'Frozen',
              style: TextStyle(
                fontSize: 15 * scale,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF15171E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
