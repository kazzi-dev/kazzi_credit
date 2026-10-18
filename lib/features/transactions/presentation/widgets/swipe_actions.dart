import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:kazzi_credit/core/theme/app_tokens.dart';
import 'package:kazzi_credit/core/theme/theme_extensions.dart';
import 'package:material_ui/material_ui.dart';

class SwipeAction {
  const SwipeAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}

/// Only one row is open at a time; opening another closes the rest.
final _openRow = ValueNotifier<Object?>(null);

/// Swipe left to reveal actions behind a row. The same actions are exposed
/// to screen readers as custom semantics actions, since swiping isn't
/// discoverable there.
class SwipeActions extends StatefulWidget {
  const SwipeActions({required this.child, required this.actions, super.key});

  final Widget child;
  final List<SwipeAction> actions;

  @override
  State<SwipeActions> createState() => _SwipeActionsState();
}

class _SwipeActionsState extends State<SwipeActions>
    with SingleTickerProviderStateMixin {
  static const _actionWidth = 76.0;

  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  final _id = Object();
  bool _hapticFired = false;

  double get _maxSlide => _actionWidth * widget.actions.length;

  @override
  void initState() {
    super.initState();
    _openRow.addListener(_onOtherOpened);
  }

  @override
  void dispose() {
    _openRow.removeListener(_onOtherOpened);
    if (_openRow.value == _id) _openRow.value = null;
    _controller.dispose();
    super.dispose();
  }

  void _onOtherOpened() {
    if (_openRow.value != _id && _controller.value > 0) _close();
  }

  void _open() {
    _openRow.value = _id;
    _controller.animateTo(1, curve: AppMotion.standard);
  }

  void _close() {
    if (_openRow.value == _id) _openRow.value = null;
    _controller.animateTo(0, curve: AppMotion.standard);
  }

  void _onDragUpdate(DragUpdateDetails d) {
    _controller.value -= d.primaryDelta! / _maxSlide;
    final pastHalf = _controller.value > 0.5;
    if (pastHalf && !_hapticFired) {
      HapticFeedback.selectionClick().ignore();
      _hapticFired = true;
    } else if (!pastHalf) {
      _hapticFired = false;
    }
  }

  void _onDragEnd(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    if (v < -300 || (v <= 300 && _controller.value > 0.5)) {
      _open();
    } else {
      _close();
    }
  }

  void _run(SwipeAction a) {
    _close();
    a.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      customSemanticsActions: {
        for (final a in widget.actions)
          CustomSemanticsAction(label: a.label): a.onTap,
      },
      child: ClipRect(
        child: Stack(
          children: [
            // Built only while open, so the buttons can't peek through at
            // the row's edges when it's closed.
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) =>
                    _controller.value == 0 ? const SizedBox.shrink() : child!,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (final a in widget.actions)
                      ExcludeSemantics(
                        child: SizedBox(
                          width: _actionWidth,
                          child: Material(
                            color: a.color,
                            child: InkWell(
                              onTap: () => _run(a),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(a.icon, color: Colors.white, size: 22),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    a.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.text.labelSmall?.copyWith(
                                      color: Colors.white,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // The gesture area moves with the row, so once it slides open the
            // revealed buttons receive their own taps.
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => Transform.translate(
                offset: Offset(-_controller.value * _maxSlide, 0),
                child: GestureDetector(
                  onHorizontalDragUpdate: _onDragUpdate,
                  onHorizontalDragEnd: _onDragEnd,
                  // While open, a tap on the row just closes it.
                  onTap: _controller.value > 0 ? _close : null,
                  behavior: HitTestBehavior.opaque,
                  child: AbsorbPointer(
                    absorbing: _controller.value > 0,
                    child: child,
                  ),
                ),
              ),
              child: ColoredBox(color: c.background, child: widget.child),
            ),
          ],
        ),
      ),
    );
  }
}
