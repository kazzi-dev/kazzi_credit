import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:kazzi_credit/core/theme/app_tokens.dart';
import 'package:kazzi_credit/core/theme/theme_extensions.dart';
import 'package:kazzi_credit/core/utils/money_format.dart';
import 'package:kazzi_credit/features/insights/domain/month_insights.dart';
import 'package:kazzi_credit/features/transactions/domain/card_transaction.dart';
import 'package:material_ui/material_ui.dart';

/// Part-to-whole ring using emphasis rather than one hue per category:
/// every segment is a neutral tone except the selected one, drawn thicker in
/// its category color. Only one hue is ever on screen, so adjacent segments
/// never depend on telling two colors apart (validated: arbitrary category
/// pairs fail colorblind separation). The ranked legend beside it carries
/// identity and doubles as the table view.
class SpendingDonut extends StatelessWidget {
  const SpendingDonut({
    required this.segments,
    required this.total,
    required this.selected,
    required this.onSelect,
    super.key,
    this.size = 200,
  });

  final List<CategorySpend> segments;
  final double total;
  final TxCategory? selected;
  final ValueChanged<TxCategory> onSelect;
  final double size;

  static const _stroke = 20.0;
  static const _selectedStroke = 30.0;

  /// Segment index under [local], or null if outside the ring.
  int? _hit(Offset local) {
    final center = Offset(size / 2, size / 2);
    final v = local - center;
    final r = (size - _selectedStroke) / 2;
    if ((v.distance - r).abs() > _selectedStroke / 2 + 6) return null;
    // Angle from 12 o'clock, clockwise, 0..1.
    final turn = ((math.atan2(v.dy, v.dx) + math.pi / 2) / (2 * math.pi)) % 1;
    var acc = 0.0;
    for (final (i, s) in segments.indexed) {
      acc += s.amount / total;
      if (turn <= acc) return i;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final sel = segments.where((s) => s.category == selected).firstOrNull;
    final summary = segments
        .map(
          (s) =>
              '${s.category.label} ${(s.amount / total * 100).round()} percent',
        )
        .join(', ');

    return Semantics(
      label: 'Spending by category: $summary',
      excludeSemantics: true,
      child: GestureDetector(
        onTapUp: (d) {
          final i = _hit(d.localPosition);
          if (i == null) return;
          HapticFeedback.selectionClick().ignore();
          onSelect(segments[i].category);
        },
        child: SizedBox.square(
          dimension: size,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: AppMotion.of(context, const Duration(milliseconds: 900)),
            curve: AppMotion.emphasized,
            builder: (context, progress, _) => CustomPaint(
              painter: _DonutPainter(
                fractions: [for (final s in segments) s.amount / total],
                selectedIndex: sel == null ? null : segments.indexOf(sel),
                selectedColor: sel?.category.color ?? c.primary,
                neutral: c.textTertiary.withValues(
                  alpha: context.isDark ? 0.35 : 0.22,
                ),
                stroke: _stroke,
                selectedStroke: _selectedStroke,
                progress: progress,
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: AppMotion.of(context, AppMotion.fast),
                  child: sel == null
                      ? const SizedBox.shrink()
                      : Column(
                          key: ValueKey(sel.category),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              sel.category.icon,
                              color: sel.category.color,
                              size: 22,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              MoneyFormat.format(sel.amount),
                              style: context.text.titleLarge,
                            ),
                            Text(
                              '${sharePercent(sel.amount, total)} · '
                              '${sel.category.label}',
                              style: context.text.bodySmall,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.fractions,
    required this.selectedIndex,
    required this.selectedColor,
    required this.neutral,
    required this.stroke,
    required this.selectedStroke,
    required this.progress,
  });

  final List<double> fractions;
  final int? selectedIndex;
  final Color selectedColor;
  final Color neutral;
  final double stroke;
  final double selectedStroke;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final r = (size.width - selectedStroke) / 2;
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: r);
    // 2px surface gap between segments, as an angle at this radius.
    final gap = 2 / r;
    var start = -math.pi / 2;
    for (final (i, f) in fractions.indexed) {
      final sweep = f * 2 * math.pi * progress;
      final isSel = i == selectedIndex;
      if (sweep > gap) {
        canvas.drawArc(
          rect,
          start + gap / 2,
          sweep - gap,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = isSel ? selectedStroke : stroke
            ..color = isSel ? selectedColor : neutral,
        );
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.progress != progress ||
      old.selectedIndex != selectedIndex ||
      old.selectedColor != selectedColor ||
      old.neutral != neutral ||
      old.fractions.length != fractions.length;
}
