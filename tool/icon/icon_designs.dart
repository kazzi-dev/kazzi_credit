// App icon designs, painted in code so they stay crisp at every size and
// can be regenerated. Rendered to PNG by tool/icon/render_icons_test.dart.
import 'dart:math' as math;
import 'dart:ui';

const navy = Color(0xFF0B1330);
const ink = Color(0xFF15171E);
const lime = Color(0xFFC8F53C);
const blue = Color(0xFF2257F5);
const mint = Color(0xFF52D6AE);
const paper = Color(0xFFF4F1EA);
const gold = Color(0xFFE2C275);

enum IconOption {
  limeK('A · Lime K', 'The in-app logo: bold navy K on brand lime.'),
  ringK('B · Ring', 'White K inside the lime ring from the Midnight card.'),
  cardStack('C · Card stack', 'Three cards stacked like the wallet screen.'),
  tiltedCard('D · Tilted card', 'One Midnight card with its lime ring.'),
  paperK('E · Paper', 'Navy k with a lime dot on warm off-white.');

  IconOption(this.label, this.description);

  final String label;
  final String description;
}

Color backgroundOf(IconOption o) => switch (o) {
  IconOption.limeK => lime,
  IconOption.ringK => navy,
  IconOption.cardStack => lime,
  IconOption.tiltedCard => navy,
  IconOption.paperK => paper,
};

/// Paints [o] into a square of side [s]. With [background] false only the
/// foreground is drawn (for Android adaptive icons, which supply their own
/// background layer). Foreground art stays inside the central ~60% so it
/// survives every launcher mask.
///
/// [artScale] shrinks the art around the center: Android adaptive icons
/// show only the middle 72 of 108dp, so their foreground uses 72/108.
void paintIcon(
  Canvas canvas,
  double s,
  IconOption o, {
  bool background = true,
  double artScale = 1,
}) {
  if (background) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, s, s),
      Paint()..color = backgroundOf(o),
    );
  }
  canvas
    ..save()
    ..translate(s / 2, s / 2)
    ..scale(artScale)
    ..translate(-s / 2, -s / 2);
  _paintArt(canvas, s, o);
  canvas.restore();
}

void _paintArt(Canvas canvas, double s, IconOption o) {
  switch (o) {
    case IconOption.limeK:
      _k(canvas, s, navy, scale: 1);
    case IconOption.ringK:
      canvas.drawCircle(
        Offset(s / 2, s / 2),
        s * 0.27,
        Paint()
          ..color = lime
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.055,
      );
      _k(canvas, s, const Color(0xFFFFFFFF), scale: 0.62);
    case IconOption.cardStack:
      _card(canvas, s, blue, center: Offset(s * 0.5, s * 0.38), width: 0.6);
      _card(canvas, s, mint, center: Offset(s * 0.5, s * 0.47), width: 0.6);
      _card(
        canvas,
        s,
        ink,
        center: Offset(s * 0.5, s * 0.58),
        width: 0.6,
        ring: true,
        chip: true,
      );
    case IconOption.tiltedCard:
      canvas
        ..save()
        ..translate(s / 2, s / 2)
        ..rotate(-0.28)
        ..translate(-s / 2, -s / 2);
      _card(
        canvas,
        s,
        ink,
        center: Offset(s / 2, s / 2),
        width: 0.66,
        ring: true,
        chip: true,
        edge: const Color(0x33FFFFFF),
      );
      canvas.restore();
    case IconOption.paperK:
      _k(canvas, s, navy, scale: 0.95, dx: -0.04);
      canvas.drawCircle(
        Offset(s * 0.71, s * 0.69),
        s * 0.055,
        Paint()..color = lime,
      );
  }
}

/// Geometric K from three rounded strokes (no font needed).
void _k(
  Canvas canvas,
  double s,
  Color color, {
  required double scale,
  double dx = 0,
}) {
  final p = Paint()
    ..color = color
    ..strokeWidth = s * 0.105 * scale
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  Offset pt(double x, double y) =>
      Offset(s * (0.5 + (x - 0.5) * scale + dx), s * (0.5 + (y - 0.5) * scale));
  canvas
    ..drawLine(pt(0.37, 0.27), pt(0.37, 0.73), p)
    ..drawLine(pt(0.41, 0.53), pt(0.64, 0.28), p)
    ..drawLine(pt(0.49, 0.47), pt(0.66, 0.73), p);
}

void _card(
  Canvas canvas,
  double s,
  Color color, {
  required Offset center,
  required double width,
  bool ring = false,
  bool chip = false,
  Color? edge,
}) {
  final w = s * width;
  final h = w / 1.586;
  final rect = Rect.fromCenter(center: center, width: w, height: h);
  final rrect = RRect.fromRectAndRadius(rect, Radius.circular(w * 0.08));
  canvas
    ..save()
    ..clipRRect(rrect)
    ..drawRect(rect, Paint()..color = color);
  if (ring) {
    final ringPaint = Paint()
      ..color = lime
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.06;
    canvas.drawCircle(
      Offset(rect.right, rect.top + h * 0.5),
      h * 0.36,
      ringPaint,
    );
  }
  canvas.restore();
  if (edge != null) {
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = edge
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.004,
    );
  }
  if (chip) {
    final cw = w * 0.16;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.left + w * 0.1, rect.top + h * 0.38, cw, cw * 0.76),
        Radius.circular(cw * 0.18),
      ),
      Paint()..color = gold,
    );
  }
}

/// A squircle-ish mask like most Android/iOS launchers.
Path launcherMask(Rect r) =>
    Path()
      ..addRRect(RRect.fromRectAndRadius(r, Radius.circular(r.width * 0.225)));

double get tau => math.pi * 2;
