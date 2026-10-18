import 'package:material_ui/material_ui.dart';

/// 4/8pt spacing scale.
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Horizontal padding for full-width screen content.
  static const double page = 20;

  /// Minimum touch target (Material / WCAG).
  static const double minTouch = 48;
}

abstract final class AppRadii {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double card = 20;
  static const double xl = 28;
  static const double pill = 999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius cardAll = BorderRadius.all(Radius.circular(card));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
}

abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);
  static const Duration cardFlip = Duration(milliseconds: 550);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeOutQuart;
  static const Curve bounce = Curves.easeOutBack;

  /// Returns [Duration.zero] when the user asked the OS to reduce motion.
  static Duration of(BuildContext context, Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}

abstract final class AppShadows {
  /// Soft lift for surfaces in light mode. Dark mode uses borders instead.
  static const List<BoxShadow> soft = [
    BoxShadow(color: Color(0x0F0B1330), blurRadius: 24, offset: Offset(0, 8)),
  ];

  /// Deep, colored-feeling shadow under payment cards.
  static List<BoxShadow> card(Color tint) => [
    BoxShadow(
      color: tint.withValues(alpha: 0.35),
      blurRadius: 32,
      spreadRadius: -6,
      offset: const Offset(0, 18),
    ),
  ];
}
