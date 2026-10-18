import 'package:material_ui/material_ui.dart';

enum NotificationType {
  transaction(
    'Purchases',
    'Every charge on your cards, as it happens',
    Icons.receipt_long_rounded,
    Color(0xFF5667F5),
  ),
  largePurchase(
    'Large purchases',
    'Charges above your threshold',
    Icons.shopping_bag_rounded,
    Color(0xFFEC4899),
  ),
  paymentDue(
    'Payment reminders',
    '3 days and 1 day before a payment is due',
    Icons.event_rounded,
    Color(0xFFF59E0B),
  ),
  limitWarning(
    'Credit limit',
    'When you reach 80% and 100% of a limit',
    Icons.speed_rounded,
    Color(0xFFF97316),
  ),
  cardFrozen(
    'Card status',
    'When a card is frozen',
    Icons.ac_unit_rounded,
    Color(0xFF06B6D4),
  ),
  suspicious(
    'Suspicious activity',
    'Unusual charges we want you to confirm',
    Icons.gpp_maybe_rounded,
    Color(0xFFEF4444),
  );

  NotificationType(this.label, this.description, this.icon, this.color);

  final String label;
  final String description;
  final IconData icon;
  final Color color;

  /// Security alerts can't be turned off.
  bool get required => this == suspicious;
}

@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
    this.route,
    this.dedupeKey,
    this.txId,
    this.cardId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
    id: j['id'] as String,
    type: NotificationType.values.byName(j['type'] as String),
    title: j['title'] as String,
    body: j['body'] as String,
    createdAt: DateTime.parse(j['createdAt'] as String),
    read: j['read'] as bool? ?? false,
    route: j['route'] as String?,
    dedupeKey: j['dedupeKey'] as String?,
    txId: j['txId'] as String?,
    cardId: j['cardId'] as String?,
  );

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;

  /// In-app location this notification opens (also the OS payload).
  final String? route;

  /// Prevents sending the same reminder twice (e.g. "due in 3 days").
  final String? dedupeKey;
  final String? txId;
  final String? cardId;

  AppNotification copyWith({bool? read}) => AppNotification(
    id: id,
    type: type,
    title: title,
    body: body,
    createdAt: createdAt,
    read: read ?? this.read,
    route: route,
    dedupeKey: dedupeKey,
    txId: txId,
    cardId: cardId,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'title': title,
    'body': body,
    'createdAt': createdAt.toIso8601String(),
    'read': read,
    if (route != null) 'route': route,
    if (dedupeKey != null) 'dedupeKey': dedupeKey,
    if (txId != null) 'txId': txId,
    if (cardId != null) 'cardId': cardId,
  };
}

@immutable
class NotificationSettings {
  const NotificationSettings({
    this.disabled = const {},
    this.largePurchaseThreshold = 5000,
    this.quietHoursEnabled = false,
    this.quietStartMinutes = 22 * 60,
    this.quietEndMinutes = 7 * 60,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> j) =>
      NotificationSettings(
        disabled: {
          for (final name in (j['disabled'] as List<dynamic>? ?? const []))
            NotificationType.values.byName(name as String),
        },
        largePurchaseThreshold: (j['threshold'] as num?)?.toDouble() ?? 5000,
        quietHoursEnabled: j['quiet'] as bool? ?? false,
        quietStartMinutes: j['quietStart'] as int? ?? 22 * 60,
        quietEndMinutes: j['quietEnd'] as int? ?? 7 * 60,
      );

  final Set<NotificationType> disabled;
  final double largePurchaseThreshold;
  final bool quietHoursEnabled;

  /// Minutes after midnight.
  final int quietStartMinutes;
  final int quietEndMinutes;

  bool isEnabled(NotificationType t) => t.required || !disabled.contains(t);

  /// Quiet hours may wrap past midnight (22:00 → 07:00).
  bool isQuiet(DateTime at) {
    if (!quietHoursEnabled) return false;
    final m = at.hour * 60 + at.minute;
    if (quietStartMinutes == quietEndMinutes) return false;
    return quietStartMinutes < quietEndMinutes
        ? m >= quietStartMinutes && m < quietEndMinutes
        : m >= quietStartMinutes || m < quietEndMinutes;
  }

  NotificationSettings copyWith({
    Set<NotificationType>? disabled,
    double? largePurchaseThreshold,
    bool? quietHoursEnabled,
    int? quietStartMinutes,
    int? quietEndMinutes,
  }) => NotificationSettings(
    disabled: disabled ?? this.disabled,
    largePurchaseThreshold:
        largePurchaseThreshold ?? this.largePurchaseThreshold,
    quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
    quietStartMinutes: quietStartMinutes ?? this.quietStartMinutes,
    quietEndMinutes: quietEndMinutes ?? this.quietEndMinutes,
  );

  Map<String, dynamic> toJson() => {
    'disabled': [for (final t in disabled) t.name],
    'threshold': largePurchaseThreshold,
    'quiet': quietHoursEnabled,
    'quietStart': quietStartMinutes,
    'quietEnd': quietEndMinutes,
  };
}
