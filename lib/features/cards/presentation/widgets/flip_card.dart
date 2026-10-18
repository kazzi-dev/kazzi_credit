import 'dart:math' as math;

import 'package:kazzi_credit/core/theme/app_tokens.dart';
import 'package:material_ui/material_ui.dart';

/// 3D flip between [front] and [back] around the vertical axis.
class FlipCard extends StatelessWidget {
  const FlipCard({
    required this.front,
    required this.back,
    required this.flipped,
    super.key,
  });

  final Widget front;
  final Widget back;
  final bool flipped;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: flipped ? 1 : 0),
      duration: AppMotion.of(context, AppMotion.cardFlip),
      curve: Curves.easeInOutCubic,
      builder: (context, t, _) {
        final angle = t * math.pi;
        final showBack = angle > math.pi / 2;
        // Lift slightly mid-flip so it feels like a physical card.
        final lift = 1 + math.sin(angle) * 0.04;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateY(angle)
            ..scaleByDouble(lift, lift, 1, 1),
          child: showBack
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(math.pi),
                  child: back,
                )
              : front,
        );
      },
    );
  }
}
