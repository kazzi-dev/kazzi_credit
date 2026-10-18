import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kazzi_credit/core/security/secure_screen.dart';
import 'package:kazzi_credit/features/auth/application/auth_controller.dart';
import 'package:kazzi_credit/features/cards/application/cards_controller.dart';
import 'package:kazzi_credit/features/cards/data/mock_cards.dart';
import 'package:kazzi_credit/features/cards/domain/payment_card.dart';

@immutable
class RevealedCard {
  const RevealedCard({
    required this.cardId,
    required this.secrets,
    required this.secondsLeft,
  });

  final String cardId;
  final CardSecrets secrets;
  final int secondsLeft;
}

/// Holds at most one card's full details in memory, for a short time.
///
/// Details hide automatically after [revealDuration], when another card is
/// revealed, and whenever the app locks.
class CardRevealController extends Notifier<RevealedCard?> {
  static const revealDuration = Duration(seconds: 30);

  Timer? _timer;

  @override
  RevealedCard? build() {
    ref
      ..onDispose(() => _timer?.cancel())
      ..listen(authControllerProvider.select((a) => a.unlocked), (_, unlocked) {
        if (!unlocked) hide();
      });
    return null;
  }

  /// Call only after `reauthenticate` succeeded.
  Future<bool> show(String cardId) async {
    final vault = ref.read(cardVaultProvider);
    var secrets = await vault.read(cardId);
    if (secrets == null) {
      // Demo only: "Forgot PIN" wipes the store mid-session.
      await vault.seedIfMissing(mockCardSecrets);
      secrets = await vault.read(cardId);
    }
    if (secrets == null) return false;
    _timer?.cancel();
    state = RevealedCard(
      cardId: cardId,
      secrets: secrets,
      secondsLeft: revealDuration.inSeconds,
    );
    await ref.read(secureScreenProvider).set(enabled: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final current = state;
      if (current == null) return;
      if (current.secondsLeft <= 1) {
        hide();
      } else {
        state = RevealedCard(
          cardId: current.cardId,
          secrets: current.secrets,
          secondsLeft: current.secondsLeft - 1,
        );
      }
    });
    return true;
  }

  void hide() {
    _timer?.cancel();
    _timer = null;
    if (state == null) return;
    state = null;
    ref.read(secureScreenProvider).set(enabled: false).ignore();
  }
}

final cardRevealProvider =
    NotifierProvider<CardRevealController, RevealedCard?>(
      CardRevealController.new,
    );
