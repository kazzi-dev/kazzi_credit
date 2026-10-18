import 'dart:math' as math;

import 'package:kazzi_credit/core/theme/card_styles.dart';
import 'package:material_ui/material_ui.dart';

/// Paints a card style's graphic. Everything is sized relative to the card
/// so it looks the same on a thumbnail and on a full-width card.
class CardPatternPainter extends CustomPainter {
  const CardPatternPainter(this.style);

  final CardStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final fill = Paint()..color = style.tone;
    final stroke = Paint()
      ..color = style.tone
      ..style = PaintingStyle.stroke;

    switch (style.pattern) {
      case CardPattern.ring:
        // Two rings tucked into the right edge, clear of the wordmark and
        // the network logo — the brand-lime mark.
        stroke.strokeWidth = w * 0.028;
        canvas
          ..drawCircle(Offset(w * 1.02, h * 0.47), h * 0.3, stroke)
          ..drawCircle(
            Offset(w * 1.02, h * 0.47),
            h * 0.17,
            stroke..color = style.tone.withValues(alpha: 0.45),
          );
      case CardPattern.bands:
        // Three wide diagonal bands on the right third.
        for (var i = 0; i < 3; i++) {
          final x = w * (0.62 + i * 0.13);
          canvas.drawPath(
            Path()
              ..moveTo(x, h)
              ..lineTo(x + w * 0.07, h)
              ..lineTo(x + w * 0.07 + h * 0.6, 0)
              ..lineTo(x + h * 0.6, 0)
              ..close(),
            fill,
          );
        }
      case CardPattern.wave:
        canvas.drawPath(
          Path()
            ..moveTo(0, h * 0.72)
            ..cubicTo(w * 0.3, h * 0.48, w * 0.55, h * 0.98, w, h * 0.6)
            ..lineTo(w, h)
            ..lineTo(0, h)
            ..close(),
          fill,
        );
      case CardPattern.arcs:
        // Thick quarter-arcs radiating from the top-right corner.
        stroke.strokeWidth = w * 0.05;
        for (var i = 1; i <= 3; i++) {
          canvas.drawArc(
            Rect.fromCircle(center: Offset(w, 0), radius: h * 0.3 * i),
            math.pi / 2,
            math.pi / 2,
            false,
            stroke,
          );
        }
      case CardPattern.dots:
        // A tidy dot grid in the top-right corner.
        final r = w * 0.012;
        final gap = w * 0.045;
        for (var row = 0; row < 5; row++) {
          for (var col = 0; col < 7; col++) {
            canvas.drawCircle(
              Offset(w * 0.6 + col * gap, h * 0.3 + row * gap),
              r,
              fill,
            );
          }
        }
      case CardPattern.slab:
        // One angled slab across the right side.
        canvas.drawPath(
          Path()
            ..moveTo(w * 0.62, 0)
            ..lineTo(w, 0)
            ..lineTo(w, h)
            ..lineTo(w * 0.48, h)
            ..close(),
          fill,
        );
    }
  }

  @override
  bool shouldRepaint(CardPatternPainter old) => old.style != style;
}

/// Flat gold EMV chip.
class CardChip extends StatelessWidget {
  const CardChip({required this.width, super.key});

  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width * 0.76,
      child: const CustomPaint(painter: _ChipPainter()),
    );
  }
}

class _ChipPainter extends CustomPainter {
  const _ChipPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final body = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(w * 0.18),
    );
    final line = Paint()
      ..color = const Color(0xFF9C7A2E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w / 36;
    canvas
      ..drawRRect(body, Paint()..color = const Color(0xFFE2C275))
      ..drawLine(Offset(0, h / 2), Offset(w, h / 2), line)
      ..drawLine(Offset(w * 0.36, 0), Offset(w * 0.36, h), line)
      ..drawLine(Offset(w * 0.64, 0), Offset(w * 0.64, h), line);
  }

  @override
  bool shouldRepaint(_ChipPainter oldDelegate) => false;
}
