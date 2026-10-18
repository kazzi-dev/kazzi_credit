import 'package:kazzi_credit/core/theme/app_tokens.dart';
import 'package:kazzi_credit/core/theme/theme_extensions.dart';
import 'package:material_ui/material_ui.dart';

class PinDots extends StatelessWidget {
  const PinDots({
    required this.filled,
    super.key,
    this.length = 6,
    this.error = false,
  });

  final int filled;
  final int length;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final duration = AppMotion.of(context, AppMotion.fast);
    return Semantics(
      liveRegion: true,
      label: '$filled of $length digits entered',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: SizedBox.square(
                dimension: 18,
                child: Center(
                  child: AnimatedContainer(
                    duration: duration,
                    curve: AppMotion.bounce,
                    width: i < filled ? 18 : 14,
                    height: i < filled ? 18 : 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < filled
                          ? (error ? c.error : c.primary)
                          : Colors.transparent,
                      border: Border.all(
                        color: error ? c.error : c.textTertiary,
                        width: i < filled ? 0 : 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
