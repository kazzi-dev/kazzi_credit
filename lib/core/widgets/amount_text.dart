import 'package:kazzi_credit/core/theme/app_tokens.dart';
import 'package:kazzi_credit/core/theme/app_typography.dart';
import 'package:kazzi_credit/core/theme/theme_extensions.dart';
import 'package:kazzi_credit/core/utils/money_format.dart';
import 'package:material_ui/material_ui.dart';

/// Locale-aware money with tabular digits.
///
/// Negative amounts are expenses; positive amounts are income/refunds and
/// turn green when [colorize] is on.
class AmountText extends StatelessWidget {
  const AmountText(
    this.amount, {
    super.key,
    this.currency = 'PHP',
    this.style,
    this.signed = false,
    this.colorize = false,
    this.smallCents = false,
    this.countUp = false,
    this.tabular = true,
  });

  final double amount;
  final String currency;
  final TextStyle? style;
  final bool signed;
  final bool colorize;

  /// Renders the cents at 60% size — used for big balances.
  final bool smallCents;

  /// Animates from 0 on first build, then from the previous value on change.
  final bool countUp;

  /// Fixed-width digits. Keep on for columns and animated values; turn off
  /// for a static hero number, where equal-width digits look loose.
  final bool tabular;

  @override
  Widget build(BuildContext context) {
    if (!countUp) return _render(context, amount);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: amount),
      duration: AppMotion.of(context, const Duration(milliseconds: 900)),
      curve: AppMotion.emphasized,
      builder: (context, value, _) => _render(context, value),
    );
  }

  Widget _render(BuildContext context, double value) {
    final c = context.colors;
    final raw = style ?? context.text.bodyLarge!;
    final base = tabular
        ? raw.tabular
        : raw.copyWith(fontFeatures: const [FontFeature.proportionalFigures()]);
    final color = colorize && amount > 0 ? c.income : base.color;
    final effective = base.copyWith(color: color);
    final locale = Localizations.maybeLocaleOf(context)?.toLanguageTag();
    final semantics = MoneyFormat.format(
      amount,
      currency: currency,
      locale: locale,
      signed: signed,
    ).replaceFirst(MoneyFormat.minus, 'minus ');

    if (!smallCents) {
      return Text(
        MoneyFormat.format(
          value,
          currency: currency,
          locale: locale,
          signed: signed,
        ),
        style: effective,
        semanticsLabel: semantics,
      );
    }

    final (whole, cents) = MoneyFormat.split(
      value,
      currency: currency,
      locale: locale,
      signed: signed,
    );
    return Text.rich(
      TextSpan(
        text: whole,
        children: [
          TextSpan(
            text: cents,
            style: TextStyle(
              fontSize: (effective.fontSize ?? 16) * 0.6,
              color: colorize && amount > 0 ? color : c.textSecondary,
            ),
          ),
        ],
      ),
      style: effective,
      semanticsLabel: semantics,
    );
  }
}
