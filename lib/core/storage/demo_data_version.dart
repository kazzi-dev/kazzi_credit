import 'package:kazzi_credit/core/storage/key_value_store.dart';

/// Bump when the shape or scale of the demo data changes. Installs with an
/// older version get their demo data cleared and reseeded on next launch;
/// the PIN, biometric choice and profile are kept.
const demoDataVersion = '2'; // v2: pesos and Philippine merchants

const _versionKey = 'demo.version';

const _demoKeys = [
  'cards.v1',
  'tx.edits.v1',
  'tx.live.v1',
  'budgets.v1',
  'notifications.v1',
  'notification_settings.v1',
];

Future<void> migrateDemoData(KeyValueStore store) async {
  if (await store.read(_versionKey) == demoDataVersion) return;
  for (final key in _demoKeys) {
    await store.delete(key);
  }
  await store.write(_versionKey, demoDataVersion);
}
