import 'dart:convert';

import 'package:kazzi_credit/core/storage/key_value_store.dart';
import 'package:kazzi_credit/features/transactions/domain/card_transaction.dart';

class TxEditsRepository {
  TxEditsRepository(this._store);

  static const _key = 'tx.edits.v1';

  final KeyValueStore _store;

  Future<Map<String, TxEdit>> load() async {
    final raw = await _store.read(_key);
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return {
      for (final MapEntry(:key, :value) in map.entries)
        key: TxEdit.fromJson(value as Map<String, dynamic>),
    };
  }

  Future<void> save(Map<String, TxEdit> edits) => _store.write(
    _key,
    jsonEncode({
      for (final MapEntry(:key, :value) in edits.entries) key: value.toJson(),
    }),
  );
}
