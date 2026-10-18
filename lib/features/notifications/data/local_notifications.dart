import 'dart:async';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kazzi_credit/core/notifications/notification_permission_service.dart';
import 'package:kazzi_credit/features/notifications/domain/app_notification.dart';

/// Shows alerts as OS notifications and reports taps on them.
abstract interface class AlertNotifier {
  /// Routes from notifications the user tapped while the app was running.
  Stream<String> get taps;

  Future<void> show(AppNotification notification);
}

class LocalNotifications
    implements AlertNotifier, NotificationPermissionService {
  LocalNotifications([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final _taps = StreamController<String>.broadcast();
  bool _initialized = false;

  /// Route from the notification that cold-started the app, if any.
  String? launchRoute;

  static bool get _supported => Platform.isAndroid || Platform.isIOS;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'kazzi_alerts',
      'Card alerts',
      channelDescription: 'Purchases, payment reminders and security alerts',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  @override
  Stream<String> get taps => _taps.stream;

  Future<void> initialize() async {
    if (_initialized || !_supported) return;
    // Don't prompt here — onboarding explains why first.
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: darwin,
      ),
      onDidReceiveNotificationResponse: (response) {
        final route = response.payload;
        if (route != null && route.startsWith('/')) _taps.add(route);
      },
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      launchRoute = launch!.notificationResponse?.payload;
    }
    _initialized = true;
  }

  @override
  Future<bool> request() async {
    await initialize();
    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.requestNotificationsPermission() ?? false;
    }
    if (Platform.isIOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      return await ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return false;
  }

  @override
  Future<void> show(AppNotification n) async {
    if (!_supported) return;
    await initialize();
    await _plugin.show(
      id: n.id.hashCode & 0x7fffffff,
      title: n.title,
      body: n.body,
      notificationDetails: _details,
      payload: n.route,
    );
  }
}

/// Single plugin instance; main() overrides it with an initialized one.
final localNotificationsProvider = Provider<LocalNotifications>(
  (ref) => LocalNotifications(),
);
