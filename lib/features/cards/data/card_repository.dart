import 'dart:convert';

import 'package:kazzi_credit/core/storage/key_value_store.dart';
import 'package:kazzi_credit/features/cards/domain/payment_card.dart';

/// Card metadata (no full numbers — those live in `CardVault`). Stored in
/// the same keystore-backed store, so it's encrypted at rest.
class CardRepository {
  CardRepository(this._store);

  static const _key = 'cards.v1';

  final KeyValueStore _store;

  /// Null when nothing has been saved yet (first run, or after a reset).
  Future<List<PaymentCard>?> load() async {
    final raw = await _store.read(_key);
    if (raw == null) return null;
    final list = jsonDecode(raw) as List<dynamic>;
    return [
      for (final item in list)
        PaymentCard.fromJson(item as Map<String, dynamic>),
    ];
  }

  Future<void> save(List<PaymentCard> cards) =>
      _store.write(_key, jsonEncode([for (final c in cards) c.toJson()]));
}
