import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

abstract final class AppTypography {
  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  /// Type scale. Display styles use tabular figures so balances and amounts
  /// don't jitter while counting up.
  static TextTheme textTheme({
    required Color primary,
    required Color secondary,
    bool useGoogleFonts = true,
  }) {
    final base = TextTheme(
      displayLarge: TextStyle(
        fontSize: 40,
        height: 1.1,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.2,
        color: primary,
        fontFeatures: _tabular,
      ),
      displayMedium: TextStyle(
        fontSize: 32,
        height: 1.15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        color: primary,
        fontFeatures: _tabular,
      ),
      displaySmall: TextStyle(
        fontSize: 26,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: primary,
        fontFeatures: _tabular,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        height: 1.25,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: primary,
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        height: 1.3,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: primary,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        height: 1.35,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        height: 1.4,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        height: 1.4,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: primary),
      bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: primary),
      bodySmall: TextStyle(fontSize: 12, height: 1.45, color: secondary),
      labelLarge: TextStyle(
        fontSize: 15,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: primary,
      ),
      labelMedium: TextStyle(
        fontSize: 13,
        height: 1.2,
        fontWeight: FontWeight.w600,
        color: secondary,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: secondary,
      ),
    );
    // Without Google Fonts (tests, screenshot tool) name a family anyway, so
    // component styles built from these never fall back to the bare default.
    return useGoogleFonts
        ? GoogleFonts.plusJakartaSansTextTheme(base)
        : base.apply(fontFamily: 'Roboto');
  }
}

extension TabularFigures on TextStyle {
  /// Fixed-width digits for any style that shows numbers.
  TextStyle get tabular =>
      copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
}
