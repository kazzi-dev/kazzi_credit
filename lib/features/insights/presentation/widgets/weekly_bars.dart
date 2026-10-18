import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:kazzi_credit/core/theme/app_tokens.dart';
import 'package:kazzi_credit/core/theme/app_typography.dart';
import 'package:kazzi_credit/core/theme/theme_extensions.dart';
import 'package:kazzi_credit/core/utils/money_format.dart';
import 'package:kazzi_credit/features/insights/domain/month_insights.dart';
import 'package:material_ui/material_ui.dart';

/// Rounds up to 1, 2 or 5 × 10ⁿ so gridline labels are tidy.
double niceCeiling(double v) {
  if (v <= 0) return 1;
  final exp = math.pow(10, (math.log(v) / math.ln10).floor()).toDouble();
  for (final m in const [1, 2, 5, 10]) {
    if (v <= m * exp) return m * exp;
  }
  return 10 * exp;
}

String weekLabel(WeekSpend w) {
  final f = DateFormat.MMMd();
  return w.start == w.end
      ? f.format(w.start)
      : '${f.format(w.start)} – ${DateFormat.d().format(w.end)}';
}

/// One series, one hue. The selected week is full strength; the rest are
/// a tint of the same hue. Tapping a column (the whole column height is
/// the hit area) selects it; the readout above shows its value.
class WeeklyBars extends StatelessWidget {
  const WeeklyBars({
    required this.weeks,
    required this.selected,
    required this.onSelect,
    super.key,
    this.plotHeight = 150,
  });

  final List<WeekSpend> weeks;
  final int selected;
  final ValueChanged<int> onSelect;
  final double plotHeight;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final maxValue = niceCeiling(weeks.map((w) => w.amount).fold(0, math.max));
    final muted = context.text.labelSmall?.copyWith(
      color: c.textTertiary,
      letterSpacing: 0,
    );

    return Column(
      children: [
        SizedBox(
          height: plotHeight,
          child: Stack(
            // The top gridline label sits half above the plot.
            clipBehavior: Clip.none,
            children: [
              // Recessive hairline grid: top, middle, baseline.
              for (final f in const [1.0, 0.5])
                Positioned(
                  left: 0,
                  right: 0,
                  // Center the 16px label row on the value so the hairline sits
                  // exactly at it.
                  top: plotHeight * (1 - f) - 8,
                  height: 16,
                  child: Row(
                    children: [
                      Expanded(child: Container(height: 1, color: c.border)),
                      const SizedBox(width: AppSpacing.sm),
                      SizedBox(
                        width: 44,
                        child: Text(
                          MoneyFormat.format(maxValue * f)
                              .replaceAll('.00', ''),
                          style: muted?.tabular,
                        ),
                      ),
                    ],
                  ),
                ),
              Positioned(
                left: 0,
                right: 52,
                bottom: 0,
                child: Container(
                  height: 1,
                  color: c.textTertiary.withValues(alpha: 0.5),
                ),
              ),
              Positioned.fill(
                right: 52,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final (i, w) in weeks.indexed)
                      Expanded(
                        child: _Bar(
                          week: w,
                          fraction: w.amount / maxValue,
                          selected: i == selected,
                          onTap: () {
                            HapticFeedback.selectionClick().ignore();
                            onSelect(i);
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.only(right: 52),
          child: Row(
            children: [
              for (final (i, w) in weeks.indexed)
                Expanded(
                  child: Text(
                    DateFormat.MMMd().format(w.start),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: i == selected
                        ? muted?.copyWith(
                            color: c.textPrimary,
                            fontWeight: FontWeight.w700,
                          )
                        : muted,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.week,
    required this.fraction,
    required this.selected,
    required this.onTap,
  });

  final WeekSpend week;
  final double fraction;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label:
          'Week of ${weekLabel(week)}: ${MoneyFormat.format(week.amount)}'
          '${week.partial ? ', so far' : ''}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, box) => Align(
            alignment: Alignment.bottomCenter,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: fraction),
              duration: AppMotion.of(
                context,
                const Duration(milliseconds: 700),
              ),
              curve: AppMotion.emphasized,
              builder: (context, f, _) => Container(
                // 2px+ surface gap either side of each bar.
                margin: const EdgeInsets.symmetric(horizontal: 6),
                constraints: const BoxConstraints(maxWidth: 36),
                height: math.max(2, box.maxHeight * f.clamp(0, 1)),
                decoration: BoxDecoration(
                  color: selected
                      ? c.primary
                      : c.primary.withValues(
                          alpha: context.isDark ? 0.35 : 0.22,
                        ),
                  // Rounded data end, square on the baseline.
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
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
