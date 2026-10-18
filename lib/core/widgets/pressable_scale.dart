import 'package:kazzi_credit/core/theme/app_tokens.dart';
import 'package:material_ui/material_ui.dart';

/// Shrinks its child slightly while pressed — the tactile "give" used on
/// buttons, cards and keypad keys.
class PressableScale extends StatefulWidget {
  const PressableScale({
    required this.child,
    super.key,
    this.enabled = true,
    this.scale = 0.97,
  });

  final Widget child;
  final bool enabled;
  final double scale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _set(bool value) {
    if (!widget.enabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1,
        duration: AppMotion.of(context, AppMotion.fast),
        curve: AppMotion.standard,
        child: widget.child,
      ),
    );
  }
}
