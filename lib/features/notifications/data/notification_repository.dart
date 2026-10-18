import 'dart:convert';

import 'package:kazzi_credit/core/storage/key_value_store.dart';
import 'package:kazzi_credit/features/notifications/domain/app_notification.dart';

class NotificationRepository {
  NotificationRepository(this._store);

  static const _listKey = 'notifications.v1';
  static const _settingsKey = 'notification_settings.v1';

  /// Older notifications beyond this are dropped.
  static const maxStored = 100;

  final KeyValueStore _store;

  /// Null when nothing was saved yet (first run).
  Future<List<AppNotification>?> load() async {
    final raw = await _store.read(_listKey);
    if (raw == null) return null;
    return [
      for (final item in jsonDecode(raw) as List<dynamic>)
        AppNotification.fromJson(item as Map<String, dynamic>),
    ];
  }

  Future<void> save(List<AppNotification> items) => _store.write(
    _listKey,
    jsonEncode([for (final n in items.take(maxStored)) n.toJson()]),
  );

  Future<NotificationSettings> loadSettings() async {
    final raw = await _store.read(_settingsKey);
    if (raw == null) return const NotificationSettings();
    return NotificationSettings.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  Future<void> saveSettings(NotificationSettings s) =>
      _store.write(_settingsKey, jsonEncode(s.toJson()));
}
