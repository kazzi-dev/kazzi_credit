import 'package:kazzi_credit/core/theme/app_colors.dart';
import 'package:kazzi_credit/core/theme/app_tokens.dart';
import 'package:material_ui/material_ui.dart';

enum ToastTone { neutral, success, error }

/// Floating snackbar with an icon. Pass [onUndo] for reversible actions —
/// preferred over a confirmation dialog.
void showAppToast(
  BuildContext context,
  String message, {
  ToastTone tone = ToastTone.neutral,
  IconData? icon,
  VoidCallback? onUndo,
}) {
  final iconData =
      icon ??
      switch (tone) {
        ToastTone.success => Icons.check_circle_rounded,
        ToastTone.error => Icons.error_rounded,
        ToastTone.neutral => Icons.info_rounded,
      };
  final iconColor = switch (tone) {
    ToastTone.success => AppPalette.green400,
    ToastTone.error => AppPalette.red400,
    ToastTone.neutral => AppPalette.indigo300,
  };

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: Duration(seconds: onUndo == null ? 3 : 5),
        content: Row(
          children: [
            Icon(iconData, color: iconColor, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(message)),
          ],
        ),
        action: onUndo == null
            ? null
            : SnackBarAction(label: 'Undo', onPressed: onUndo),
      ),
    );
}
