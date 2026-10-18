import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:kazzi_credit/core/theme/app_tokens.dart';
import 'package:kazzi_credit/features/cards/application/card_reveal_controller.dart';
import 'package:kazzi_credit/features/cards/domain/payment_card.dart';
import 'package:kazzi_credit/features/cards/presentation/widgets/card_back.dart';
import 'package:kazzi_credit/features/cards/presentation/widgets/card_front.dart';
import 'package:kazzi_credit/features/cards/presentation/widgets/card_surface.dart';
import 'package:kazzi_credit/features/cards/presentation/widgets/flip_card.dart';
import 'package:material_ui/material_ui.dart';

/// Cards stacked like a physical wallet: the others peek out above the
/// active one; tap a peeking card to bring it to the front, tap the front
/// card to flip it.
class CardStack extends StatelessWidget {
  const CardStack({
    required this.cards,
    required this.selectedId,
    required this.flippedId,
    required this.revealed,
    required this.onSelect,
    required this.onFlip,
    super.key,
  });

  final List<PaymentCard> cards;
  final String selectedId;
  final String? flippedId;
  final RevealedCard? revealed;
  final ValueChanged<String> onSelect;
  final ValueChanged<PaymentCard> onFlip;

  @override
  Widget build(BuildContext context) {
    final behind = [
      for (final c in cards)
        if (c.id != selectedId) c,
    ];
    final front = cards.firstWhere(
      (c) => c.id == selectedId,
      orElse: () => cards.first,
    );
    // Order back-to-front so the active card paints last (on top).
    final ordered = [...behind, front];

    return LayoutBuilder(
      builder: (context, box) {
        final cardHeight = box.maxWidth / kCardAspectRatio;
        // Each card behind shows a strip with its name; compress for many.
        final peek = behind.isEmpty
            ? 0.0
            : math.min(48, 150 / behind.length).toDouble();
        final duration = AppMotion.of(context, AppMotion.slow);

        return SizedBox(
          height: peek * behind.length + cardHeight,
          child: Stack(
            children: [
              for (final (i, card) in ordered.indexed)
                AnimatedPositioned(
                  key: ValueKey(card.id),
                  duration: duration,
                  curve: AppMotion.emphasized,
                  left: 0,
                  right: 0,
                  top: i * peek,
                  child: _StackedCard(
                    card: card,
                    isFront: card.id == front.id,
                    flipped: flippedId == card.id,
                    revealed: revealed?.cardId == card.id ? revealed : null,
                    onTap: () {
                      if (card.id == front.id) {
                        onFlip(card);
                      } else {
                        HapticFeedback.selectionClick().ignore();
                        onSelect(card.id);
                      }
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StackedCard extends StatelessWidget {
  const _StackedCard({
    required this.card,
    required this.isFront,
    required this.flipped,
    required this.revealed,
    required this.onTap,
  });

  final PaymentCard card;
  final bool isFront;
  final bool flipped;
  final RevealedCard? revealed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final front = CardFront(
      style: card.style,
      last4: card.last4,
      network: card.network,
      kindLabel: card.kind.label,
      nickname: card.nickname,
      frozen: card.frozen,
      elevated: isFront,
    );
    return Semantics(
      button: true,
      hint: isFront ? 'Tap to flip' : 'Tap to show this card',
      child: GestureDetector(
        onTap: onTap,
        child: isFront
            ? FlipCard(
                flipped: flipped,
                front: front,
                back: CardBack(
                  style: card.style,
                  last4: card.last4,
                  network: card.network,
                  holder: card.holder,
                  expiry: revealed == null ? null : card.expiry,
                  number: revealed?.secrets.number,
                  cvv: revealed?.secrets.cvv,
                  hidesInSeconds: revealed?.secondsLeft,
                  frozen: card.frozen,
                ),
              )
            : front,
      ),
    );
  }
}
