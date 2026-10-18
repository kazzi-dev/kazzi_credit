import 'package:kazzi_credit/core/theme/card_styles.dart';
import 'package:kazzi_credit/features/cards/domain/card_network.dart';
import 'package:kazzi_credit/features/cards/presentation/widgets/card_marks.dart';
import 'package:kazzi_credit/features/cards/presentation/widgets/card_pattern.dart';
import 'package:kazzi_credit/features/cards/presentation/widgets/card_surface.dart';
import 'package:material_ui/material_ui.dart';

/// Front of a card, kept deliberately sparse: brand, nickname, last four
/// digits and the network. Full details live on the back, behind auth.
class CardFront extends StatelessWidget {
  const CardFront({
    required this.style,
    required this.last4,
    super.key,
    this.network = CardNetwork.visa,
    this.holder,
    this.expiry,
    this.kindLabel = 'Credit',
    this.nickname,
    this.frozen = false,
    this.elevated = true,
    this.numberText,
  });

  final CardStyle style;
  final String last4;
  final CardNetwork network;

  /// Only shown while adding a card, as live feedback.
  final String? holder;
  final String? expiry;
  final String kindLabel;
  final String? nickname;
  final bool frozen;
  final bool elevated;

  /// Overrides the masked number — the add-card preview shows digits as
  /// they're typed.
  final String? numberText;

  @override
  Widget build(BuildContext context) {
    final fg = style.foreground;
    return Semantics(
      label:
          '${nickname ?? network.label} ${kindLabel.toLowerCase()} card '
          'ending in $last4${frozen ? ', frozen' : ''}',
      excludeSemantics: true,
      child: CardSurface(
        style: style,
        elevated: elevated,
        frozen: frozen,
        child: LayoutBuilder(
          builder: (context, box) {
            final s = box.maxWidth / kCardDesignWidth;
            TextStyle text(double size, {Color? color, FontWeight? w}) =>
                TextStyle(
                  fontSize: size * s,
                  fontWeight: w ?? FontWeight.w600,
                  color: color ?? fg,
                  height: 1.15,
                );

            return Padding(
              padding: EdgeInsets.all(22 * s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The nickname leads: in the wallet stack only this top
                  // row of a card peeks out, so it's what identifies it.
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          nickname ?? kindLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text(17),
                        ),
                      ),
                      Text(
                        'kazzi',
                        style: text(
                          15,
                          color: style.muted,
                          w: FontWeight.w800,
                        ).copyWith(letterSpacing: -0.4),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      CardChip(width: 38 * s),
                      SizedBox(width: 10 * s),
                      Icon(
                        Icons.contactless_outlined,
                        size: 22 * s,
                        color: style.muted,
                      ),
                    ],
                  ),
                  SizedBox(height: 14 * s),
                  if (holder != null || expiry != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            (holder ?? '').toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text(12, color: style.muted),
                          ),
                        ),
                        if (expiry != null)
                          Text(expiry!, style: text(12, color: style.muted)),
                      ],
                    ),
                    SizedBox(height: 6 * s),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          numberText ?? '•••• $last4',
                          maxLines: 1,
                          style: text(18).copyWith(
                            letterSpacing: 1.4,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: NetworkLogo(
                          key: ValueKey(network),
                          network: network,
                          height: 24 * s,
                          color: fg,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
