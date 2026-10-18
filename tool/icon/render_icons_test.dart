// Renders the icon designs to PNG.
//   Previews: flutter test tool/icon/render_icons_test.dart --update-goldens
// Output: tool/icon/out/*.png
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'icon_designs.dart';

class _IconPainter extends CustomPainter {
  const _IconPainter(
    this.option, {
    this.background = true,
    this.masked = false,
    this.artScale = 1,
  });

  final IconOption option;
  final bool background;
  final bool masked;
  final double artScale;

  @override
  void paint(Canvas canvas, Size size) {
    if (masked) canvas.clipPath(launcherMask(Offset.zero & size));
    paintIcon(
      canvas,
      size.width,
      option,
      background: background,
      artScale: artScale,
    );
  }

  @override
  bool shouldRepaint(_IconPainter old) => false;
}

Future<void> _loadFonts() async {
  final sdk = File(Platform.resolvedExecutable)
      .parent
      .parent
      .parent
      .parent
      .parent
      .parent
      .path;
  final dir = '$sdk/bin/cache/artifacts/material_fonts';
  final roboto = FontLoader('Roboto');
  for (final n in ['roboto-regular.ttf', 'roboto-bold.ttf']) {
    roboto.addFont(File('$dir/$n').readAsBytes().then(ByteData.sublistView));
  }
  await roboto.load();
}

void main() {
  setUpAll(_loadFonts);
  _chosen();

  // Comparison sheet: each option as a home-screen icon, large and at
  // real launcher size, on light and dark wallpaper.
  testWidgets('sheet', (tester) async {
    tester.view
      ..physicalSize = const Size(1600, 1200)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    Widget tile(IconOption o, double size) => SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _IconPainter(o, masked: true)),
    );

    Widget column(IconOption o) => Column(
      children: [
        tile(o, 220),
        const SizedBox(height: 24),
        Text(
          o.label,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F1322),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 260,
          child: Text(
            o.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 17,
              color: Color(0xFF545B6E),
            ),
          ),
        ),
        const SizedBox(height: 28),
        // Actual home-screen size on the two common wallpaper extremes.
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final bg in const [Color(0xFFE9ECF2), Color(0xFF1A1D26)])
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    tile(o, 60),
                    const SizedBox(height: 6),
                    Text(
                      'Kazzi',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 13,
                        color: bg.computeLuminance() > 0.5
                            ? const Color(0xFF0F1322)
                            : const Color(0xFFFFFFFF),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ColoredBox(
          color: const Color(0xFFFFFFFF),
          child: Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 40,
              runSpacing: 60,
              children: [for (final o in IconOption.values) column(o)],
            ),
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(Directionality),
      matchesGoldenFile('out/sheet.png'),
    );
  });

  // Full-size 1024px sources for each option.
  for (final o in IconOption.values) {
    for (final fg in [false, true]) {
      testWidgets('${o.name}${fg ? ' foreground' : ''}', (tester) async {
        tester.view
          ..physicalSize = const Size(1024, 1024)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          RepaintBoundary(
            child: CustomPaint(
              size: const Size(1024, 1024),
              painter: _IconPainter(o, background: !fg),
            ),
          ),
        );
        await expectLater(
          find.byType(RepaintBoundary).first,
          matchesGoldenFile('out/${o.name}${fg ? '_foreground' : ''}.png'),
        );
      });
    }
  }
}

/// The chosen icon: written to assets/icon/ for flutter_launcher_icons.
const IconOption chosen = IconOption.tiltedCard;

void _chosen() {
  for (final (name, fg) in const [
    ('app_icon', false),
    ('app_icon_foreground', true),
  ]) {
    testWidgets('chosen $name', (tester) async {
      tester.view
        ..physicalSize = const Size(1024, 1024)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        RepaintBoundary(
          child: CustomPaint(
            size: const Size(1024, 1024),
            painter: _IconPainter(
              chosen,
              background: !fg,
              artScale: fg ? 72 / 108 : 1,
            ),
          ),
        ),
      );
      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('../../assets/icon/$name.png'),
      );
    });
  }
}
