import 'dart:math';

import 'package:kazzi_credit/core/theme/app_tokens.dart';
import 'package:kazzi_credit/core/theme/theme_extensions.dart';
import 'package:material_ui/material_ui.dart';

const _cities = [
  'Makati City',
  'BGC, Taguig',
  'Quezon City',
  'Pasig City',
  'Cebu City',
];

/// Stylized map placeholder until a maps SDK is wired in. The street
/// layout is seeded by the merchant name so each merchant looks distinct
/// but stable.
class MapPreview extends StatelessWidget {
  const MapPreview({required this.merchant, super.key});

  final String merchant;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final seed = merchant.codeUnits.fold(7, (h, u) => (h * 31 + u) & 0xFFFFFF);
    final city = _cities[seed % _cities.length];
    return Semantics(
      label: 'Map showing the approximate location of $merchant in $city',
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: AppRadii.lgAll,
        child: SizedBox(
          height: 150,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _MapPainter(
                  seed: seed,
                  land: c.surfaceHigh,
                  road: c.surface,
                  park: const Color(0xFF3DD68C).withValues(alpha: 0.18),
                  water: const Color(0xFF3F8CFF).withValues(alpha: 0.18),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: c.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: c.primary.withValues(alpha: 0.35),
                            blurRadius: 16,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.storefront_rounded,
                        size: 18,
                        color: c.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
              Positioned(
                left: AppSpacing.md,
                bottom: AppSpacing.md,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: c.surface.withValues(alpha: 0.92),
                    borderRadius: AppRadii.pillAll,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.place_rounded,
                        size: 14,
                        color: c.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(city, style: context.text.labelMedium),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  const _MapPainter({
    required this.seed,
    required this.land,
    required this.road,
    required this.park,
    required this.water,
  });

  final int seed;
  final Color land;
  final Color road;
  final Color park;
  final Color water;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(seed);
    // Land, water along one edge, a park block somewhere inland.
    canvas
      ..drawRect(Offset.zero & size, Paint()..color = land)
      ..drawPath(
        Path()
          ..moveTo(size.width * 0.7, size.height)
          ..quadraticBezierTo(
            size.width * 0.85,
            size.height * 0.55,
            size.width,
            size.height * 0.4,
          )
          ..lineTo(size.width, size.height)
          ..close(),
        Paint()..color = water,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * (0.05 + rnd.nextDouble() * 0.3),
            size.height * (0.1 + rnd.nextDouble() * 0.3),
            size.width * 0.18,
            size.height * 0.28,
          ),
          const Radius.circular(6),
        ),
        Paint()..color = park,
      );

    final minor = Paint()
      ..color = road
      ..strokeWidth = 5;
    for (
      var x = rnd.nextDouble() * 40;
      x < size.width;
      x += 38 + rnd.nextDouble() * 30
    ) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), minor);
    }
    for (
      var y = rnd.nextDouble() * 30;
      y < size.height;
      y += 30 + rnd.nextDouble() * 24
    ) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), minor);
    }
    // One wide avenue crossing diagonally.
    canvas.drawLine(
      Offset(0, size.height * (0.6 + rnd.nextDouble() * 0.3)),
      Offset(size.width, size.height * rnd.nextDouble() * 0.3),
      Paint()
        ..color = road
        ..strokeWidth = 10,
    );
  }

  @override
  bool shouldRepaint(_MapPainter old) =>
      old.seed != seed || old.land != land || old.road != road;
}
