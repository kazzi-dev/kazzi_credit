import 'package:kazzi_credit/core/theme/card_styles.dart';
import 'package:kazzi_credit/features/cards/domain/card_network.dart';
import 'package:kazzi_credit/features/cards/presentation/widgets/card_marks.dart';
import 'package:kazzi_credit/features/cards/presentation/widgets/card_surface.dart';
import 'package:material_ui/material_ui.dart';

/// Back of the card: the details as a simple labeled list. Values stay
/// masked unless [number] and [cvv] are supplied (after re-auth).
class CardBack extends StatelessWidget {
  const CardBack({
    required this.style,
    required this.last4,
    super.key,
    this.network = CardNetwork.visa,
    this.holder,
    this.expiry,
    this.number,
    this.cvv,
    this.hidesInSeconds,
    this.frozen = false,
  });

  final CardStyle style;
  final String last4;
  final CardNetwork network;
  final String? holder;
  final String? expiry;
  final String? number;
  final String? cvv;

  /// Countdown shown while details are revealed.
  final int? hidesInSeconds;
  final bool frozen;

  bool get revealed => number != null;

  @override
  Widget build(BuildContext context) {
    final fg = style.foreground;
    final maskedNumber = network.groups
        .take(network.groups.length - 1)
        .map((g) => '•' * g)
        .followedBy([last4])
        .join(' ');

    return Semantics(
      label: revealed
          ? 'Card number ${network.format(number!)}, '
                'expires $expiry, security code $cvv'
          : 'Card details hidden',
      excludeSemantics: true,
      child: CardSurface(
        style: style,
        frozen: frozen,
        child: LayoutBuilder(
          builder: (context, box) {
            final s = box.maxWidth / kCardDesignWidth;
            Widget field(String label, String value, {double size = 15}) =>
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10.5 * s,
                        fontWeight: FontWeight.w600,
                        color: style.muted,
                      ),
                    ),
                    SizedBox(height: 3 * s),
                    Text(
                      value,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: size * s,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        color: fg,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                );

            return Padding(
              padding: EdgeInsets.all(22 * s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          (holder ?? '').toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12 * s,
                            fontWeight: FontWeight.w600,
                            color: style.muted,
                          ),
                        ),
                      ),
                      NetworkLogo(network: network, height: 20 * s, color: fg),
                    ],
                  ),
                  const Spacer(),
                  field(
                    'Card number',
                    revealed ? network.format(number!) : maskedNumber,
                    size: 18,
                  ),
                  SizedBox(height: 14 * s),
                  Row(
                    children: [
                      field('Expiry', expiry ?? '••/••'),
                      SizedBox(width: 28 * s),
                      field('CVV', cvv ?? '•' * network.cvvLength),
                      const Spacer(),
                      Text(
                        revealed
                            ? 'Hides in ${hidesInSeconds ?? 0}s'
                            : 'Hidden',
                        style: TextStyle(
                          fontSize: 11 * s,
                          fontWeight: FontWeight.w600,
                          color: style.muted,
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
