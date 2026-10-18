import 'package:material_ui/material_ui.dart';

/// Lets a full-height layout (with `Spacer`s) scroll instead of overflowing
/// on short screens or at large text sizes.
class FillScroll extends StatelessWidget {
  const FillScroll({required this.child, super.key, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final insets = padding?.resolve(TextDirection.ltr) ?? EdgeInsets.zero;
        return SingleChildScrollView(
          padding: padding,
          child: ConstrainedBox(
            // Fill the width too, or a Column with only narrow children
            // shrinks and sits off-center.
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth - insets.horizontal,
              minHeight: constraints.maxHeight - insets.vertical,
            ),
            child: IntrinsicHeight(child: child),
          ),
        );
      },
    );
  }
}
