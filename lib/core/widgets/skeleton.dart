import 'package:flutter_animate/flutter_animate.dart';
import 'package:kazzi_credit/core/theme/app_tokens.dart';
import 'package:kazzi_credit/core/theme/theme_extensions.dart';
import 'package:material_ui/material_ui.dart';

/// Placeholder block with a shimmer sweep. The shimmer is dropped when the
/// user has reduced motion on.
class Skeleton extends StatelessWidget {
  const Skeleton({
    super.key,
    this.width,
    this.height = 14,
    this.radius = AppRadii.sm,
    this.circle = false,
  });

  final double? width;
  final double height;
  final double radius;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final box = Container(
      width: circle ? height : width,
      height: height,
      decoration: BoxDecoration(
        color: c.skeleton,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(radius),
      ),
    );
    if (MediaQuery.disableAnimationsOf(context)) return box;
    return box
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 1200.ms, color: c.surface.withValues(alpha: 0.6));
  }
}

/// Skeleton shaped like a transaction row: avatar, two lines, amount.
class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return const ExcludeSemantics(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            Skeleton(height: 44, circle: true),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Skeleton(width: 140),
                  SizedBox(height: AppSpacing.sm),
                  Skeleton(width: 90, height: 10),
                ],
              ),
            ),
            Skeleton(width: 64),
          ],
        ),
      ),
    );
  }
}
