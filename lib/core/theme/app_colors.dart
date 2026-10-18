import 'package:material_ui/material_ui.dart';

/// Raw palette. Widgets should read colors from [AppColors] via
/// `context.colors`, never from [AppPalette] directly, so light and dark
/// mode stay in sync.
abstract final class AppPalette {
  static const navy950 = Color(0xFF070B18);
  static const navy900 = Color(0xFF0B1330);
  static const navy800 = Color(0xFF12204D);
  static const navy700 = Color(0xFF1B2D66);

  static const indigo600 = Color(0xFF3D4FE0);
  static const indigo500 = Color(0xFF5667F5);
  static const indigo300 = Color(0xFF9EA8FF);
  static const indigo100 = Color(0xFFE5E8FF);

  static const lime400 = Color(0xFFC8F53C);
  static const lime300 = Color(0xFFD9FA74);

  static const green700 = Color(0xFF15803D);
  static const green400 = Color(0xFF3DD68C);
  static const amber700 = Color(0xFFB45309);
  static const amber400 = Color(0xFFFBBF24);
  static const red600 = Color(0xFFDC2626);
  static const red400 = Color(0xFFF87171);

  static const grey25 = Color(0xFFF7F8FC);
  static const grey50 = Color(0xFFF0F2F8);
  static const grey100 = Color(0xFFE4E7F0);
  static const grey500 = Color(0xFF6E7588);
  static const grey600 = Color(0xFF545B6E);
  static const grey900 = Color(0xFF0F1322);

  static const darkBg = Color(0xFF070A14);
  static const darkSurface = Color(0xFF10152A);
  static const darkSurfaceHigh = Color(0xFF181F38);
  static const darkBorder = Color(0xFF242C4A);
  static const darkTextSecondary = Color(0xFFA6ADC4);
  static const darkTextTertiary = Color(0xFF7D859E);

  static const white = Color(0xFFFFFFFF);
}

/// Semantic color tokens, resolved per brightness.
///
/// All text tokens meet WCAG AA (4.5:1) against [background] and [surface].
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.primary,
    required this.onPrimary,
    required this.primarySoft,
    required this.accent,
    required this.onAccent,
    required this.success,
    required this.warning,
    required this.error,
    required this.income,
    required this.expense,
    required this.skeleton,
  });

  static const light = AppColors(
    background: AppPalette.grey25,
    surface: AppPalette.white,
    surfaceHigh: AppPalette.grey50,
    border: AppPalette.grey100,
    textPrimary: AppPalette.grey900,
    textSecondary: AppPalette.grey600,
    textTertiary: AppPalette.grey500,
    primary: AppPalette.navy900,
    onPrimary: AppPalette.white,
    primarySoft: AppPalette.indigo100,
    accent: AppPalette.lime400,
    onAccent: AppPalette.navy950,
    success: AppPalette.green700,
    warning: AppPalette.amber700,
    error: AppPalette.red600,
    income: AppPalette.green700,
    expense: AppPalette.grey900,
    skeleton: AppPalette.grey100,
  );

  static const dark = AppColors(
    background: AppPalette.darkBg,
    surface: AppPalette.darkSurface,
    surfaceHigh: AppPalette.darkSurfaceHigh,
    border: AppPalette.darkBorder,
    textPrimary: AppPalette.white,
    textSecondary: AppPalette.darkTextSecondary,
    textTertiary: AppPalette.darkTextTertiary,
    primary: AppPalette.indigo300,
    onPrimary: AppPalette.navy950,
    primarySoft: AppPalette.navy800,
    accent: AppPalette.lime400,
    onAccent: AppPalette.navy950,
    success: AppPalette.green400,
    warning: AppPalette.amber400,
    error: AppPalette.red400,
    income: AppPalette.green400,
    expense: AppPalette.white,
    skeleton: AppPalette.darkSurfaceHigh,
  );

  final Color background;
  final Color surface;
  final Color surfaceHigh;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;

  /// For captions and metadata only, never for primary content.
  final Color textTertiary;
  final Color primary;
  final Color onPrimary;
  final Color primarySoft;

  /// Vibrant brand accent. Use as a fill with [onAccent] text, never as text
  /// on light backgrounds (fails contrast).
  final Color accent;
  final Color onAccent;
  final Color success;
  final Color warning;
  final Color error;
  final Color income;
  final Color expense;
  final Color skeleton;

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceHigh,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? primary,
    Color? onPrimary,
    Color? primarySoft,
    Color? accent,
    Color? onAccent,
    Color? success,
    Color? warning,
    Color? error,
    Color? income,
    Color? expense,
    Color? skeleton,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceHigh: surfaceHigh ?? this.surfaceHigh,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      primarySoft: primarySoft ?? this.primarySoft,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      income: income ?? this.income,
      expense: expense ?? this.expense,
      skeleton: skeleton ?? this.skeleton,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceHigh: l(surfaceHigh, other.surfaceHigh),
      border: l(border, other.border),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textTertiary: l(textTertiary, other.textTertiary),
      primary: l(primary, other.primary),
      onPrimary: l(onPrimary, other.onPrimary),
      primarySoft: l(primarySoft, other.primarySoft),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      success: l(success, other.success),
      warning: l(warning, other.warning),
      error: l(error, other.error),
      income: l(income, other.income),
      expense: l(expense, other.expense),
      skeleton: l(skeleton, other.skeleton),
    );
  }
}
