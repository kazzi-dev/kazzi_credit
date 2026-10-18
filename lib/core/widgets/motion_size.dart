import 'package:kazzi_credit/core/theme/app_tokens.dart';
import 'package:material_ui/material_ui.dart';

/// [AnimatedSize] that respects reduced motion. A zero-duration
/// AnimatedSize asserts during layout, so it's skipped entirely instead.
class MotionSize extends StatelessWidget {
  const MotionSize({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final duration = AppMotion.of(context, AppMotion.medium);
    if (duration == Duration.zero) return child;
    return AnimatedSize(
      duration: duration,
      curve: AppMotion.standard,
      alignment: Alignment.topCenter,
      child: child,
    );
  }
}
