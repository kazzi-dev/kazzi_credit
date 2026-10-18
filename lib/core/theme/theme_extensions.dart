import 'package:kazzi_credit/core/theme/app_colors.dart';
import 'package:material_ui/material_ui.dart';

extension ThemeContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
  TextTheme get text => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
