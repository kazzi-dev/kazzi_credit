import 'package:kazzi_credit/core/theme/app_tokens.dart';
import 'package:kazzi_credit/core/theme/theme_extensions.dart';
import 'package:material_ui/material_ui.dart';

/// Fixed-height slot under the PIN dots so the keypad doesn't jump when an
/// error appears.
class PinErrorLine extends StatelessWidget {
  const PinErrorLine({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 40),
      child: AnimatedSwitcher(
        duration: AppMotion.of(context, AppMotion.fast),
        child: message == null
            ? const SizedBox.shrink()
            : Semantics(
                liveRegion: true,
                child: Text(
                  message!,
                  key: ValueKey(message),
                  textAlign: TextAlign.center,
                  style: context.text.bodyMedium?.copyWith(
                    color: context.colors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
      ),
    );
  }
}
