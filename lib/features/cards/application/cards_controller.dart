import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kazzi_credit/features/auth/application/auth_controller.dart';
import 'package:kazzi_credit/features/cards/data/card_repository.dart';
import 'package:kazzi_credit/features/cards/data/card_vault.dart';
import 'package:kazzi_credit/features/cards/data/mock_cards.dart';
import 'package:kazzi_credit/features/cards/domain/card_network.dart';
import 'package:kazzi_credit/features/cards/domain/payment_card.dart';

/// Injectable clock so tests and demo data agree on "now".
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final cardVaultProvider = Provider<CardVault>(
  (ref) => CardVault(ref.watch(keyValueStoreProvider)),
);

final cardRepositoryProvider = Provider<CardRepository>(
  (ref) => CardRepository(ref.watch(keyValueStoreProvider)),
);

/// Cards loaded from storage in `main()`. Defaults to demo data.
final initialCardsProvider = Provider<List<PaymentCard>>(
  (ref) => mockCards(ref.watch(clockProvider)()),
);

class CardsController extends Notifier<List<PaymentCard>> {
  @override
  List<PaymentCard> build() {
    // "Forgot PIN" wipes storage; go back to the demo wallet with it.
    ref.listen(authControllerProvider.select((a) => a.onboarded), (
      wasOnboarded,
      onboarded,
    ) {
      if ((wasOnboarded ?? false) && !onboarded) {
        state = mockCards(ref.read(clockProvider)());
        _persist();
      }
    });
    return ref.watch(initialCardsProvider);
  }

  void _persist() {
    // Fire and forget: the in-memory state is the source of truth while
    // the app runs.
    unawaited(ref.read(cardRepositoryProvider).save(state));
  }

  void setFrozen(String id, {required bool frozen}) {
    state = [
      for (final c in state)
        if (c.id == id) c.copyWith(frozen: frozen) else c,
    ];
    _persist();
  }

  /// Mock payment toward the card's balance.
  void pay(String id, double amount) {
    state = [
      for (final c in state)
        if (c.id == id)
          c.copyWith(
            balance: (c.balance - amount).clamp(0, double.infinity),
            statementBalance: (c.statementBalance - amount).clamp(
              0,
              double.infinity,
            ),
            minimumDue: amount >= c.minimumDue ? 0 : c.minimumDue - amount,
          )
        else
          c,
    ];
    _persist();
  }

  /// A new purchase increases what's owed.
  void charge(String id, double amount) {
    state = [
      for (final c in state)
        if (c.id == id) c.copyWith(balance: c.balance + amount) else c,
    ];
    _persist();
  }

  /// Updates the printed name on every card (used when the profile name
  /// changes; a single-person wallet).
  void renameHolder(String name) {
    state = [for (final c in state) c.copyWith(holder: name)];
    _persist();
  }

  bool contains(String number) {
    final network = CardNetwork.detect(number);
    final last4 = number.substring(number.length - 4);
    return state.any((c) => c.network == network && c.last4 == last4);
  }

  /// Saves the full number and CVV to the vault first, so a card never
  /// appears in the wallet without its details.
  Future<PaymentCard> add({
    required String number,
    required String cvv,
    required String holder,
    required int expiryMonth,
    required int expiryYear,
    required String nickname,
    required String themeId,
    required CardKind kind,
    required double creditLimit,
  }) async {
    final now = ref.read(clockProvider)();
    final id = 'card_${now.microsecondsSinceEpoch}';
    await ref
        .read(cardVaultProvider)
        .write(id, CardSecrets(number: number, cvv: cvv));
    final card = PaymentCard(
      id: id,
      nickname: nickname,
      holder: holder,
      last4: number.substring(number.length - 4),
      network: CardNetwork.detect(number),
      expiryMonth: expiryMonth,
      expiryYear: expiryYear,
      themeId: themeId,
      kind: kind,
      creditLimit: creditLimit,
      balance: 0,
      statementBalance: 0,
      minimumDue: 0,
      dueDate: now.add(const Duration(days: 25)),
    );
    state = [...state, card];
    await ref.read(cardRepositoryProvider).save(state);
    return card;
  }
}

final cardsProvider = NotifierProvider<CardsController, List<PaymentCard>>(
  CardsController.new,
);
