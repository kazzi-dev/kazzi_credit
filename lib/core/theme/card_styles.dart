import 'package:material_ui/material_ui.dart';

/// The single graphic printed on a card. Flat shapes in one tonal color —
/// the kind of detail a real printed card has, never a glow or gradient.
enum CardPattern { ring, bands, wave, arcs, dots, slab }

/// Card colors a user can pick: a solid fill plus one graphic.
///
/// Ids are stable because they're persisted with each card.
@immutable
class CardStyle {
  const CardStyle({
    required this.id,
    required this.name,
    required this.color,
    required this.pattern,
    required this.tone,
    this.foreground = Colors.white,
  });

  final String id;
  final String name;
  final Color color;
  final CardPattern pattern;

  /// Color of the printed graphic.
  final Color tone;

  /// Text and logo color on the card.
  final Color foreground;

  /// Secondary text (labels, nickname) on the card.
  Color get muted => foreground.withValues(alpha: 0.64);

  static const midnight = CardStyle(
    id: 'midnight',
    name: 'Midnight',
    color: Color(0xFF15171E),
    pattern: CardPattern.ring,
    tone: Color(0xFFC8F53C), // brand lime
  );
  static const ocean = CardStyle(
    id: 'ocean',
    name: 'Blue',
    color: Color(0xFF2257F5),
    pattern: CardPattern.bands,
    tone: Color(0x24FFFFFF),
  );
  static const lime = CardStyle(
    id: 'lime',
    name: 'Mint',
    color: Color(0xFF52D6AE),
    pattern: CardPattern.wave,
    tone: Color(0x2607231A),
    foreground: Color(0xFF07231A),
  );
  static const sunset = CardStyle(
    id: 'sunset',
    name: 'Coral',
    color: Color(0xFFF2634F),
    pattern: CardPattern.arcs,
    tone: Color(0x2BFFFFFF),
  );
  static const aurora = CardStyle(
    id: 'aurora',
    name: 'Violet',
    color: Color(0xFF6B57E8),
    pattern: CardPattern.dots,
    tone: Color(0x40FFFFFF),
  );
  static const graphite = CardStyle(
    id: 'graphite',
    name: 'Sand',
    color: Color(0xFFE8E2D6),
    pattern: CardPattern.slab,
    tone: Color(0x141B1B1F),
    foreground: Color(0xFF1B1B1F),
  );

  static const List<CardStyle> all = [
    midnight,
    ocean,
    lime,
    sunset,
    aurora,
    graphite,
  ];

  static CardStyle byId(String id) =>
      all.firstWhere((s) => s.id == id, orElse: () => midnight);
}
