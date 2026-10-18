import 'dart:convert';

import 'package:kazzi_credit/core/storage/key_value_store.dart';
import 'package:kazzi_credit/features/cards/domain/payment_card.dart';

/// Full card numbers and CVVs, kept only in the OS keystore-backed store.
class CardVault {
  CardVault(this._store);

  final KeyValueStore _store;

  static String _key(String cardId) => 'card.$cardId.secrets';

  Future<CardSecrets?> read(String cardId) async {
    final raw = await _store.read(_key(cardId));
    if (raw == null) return null;
    return CardSecrets.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> write(String cardId, CardSecrets secrets) =>
      _store.write(_key(cardId), jsonEncode(secrets.toJson()));

  Future<void> delete(String cardId) => _store.delete(_key(cardId));

  /// Seeds demo cards on first run (or after a reset wiped the store).
  Future<void> seedIfMissing(Map<String, CardSecrets> secrets) async {
    for (final MapEntry(:key, :value) in secrets.entries) {
      if (await _store.read(_key(key)) == null) await write(key, value);
    }
  }
}
