import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kazzi_credit/core/router/app_router.dart';
import 'package:kazzi_credit/features/notifications/application/notification_center.dart';
import 'package:material_ui/material_ui.dart';

/// Opens the screen behind an OS notification the user tapped while the
/// app was running. If the app is locked, the router sends them through
/// the lock screen first and then on to the destination.
class NotificationTapListener extends ConsumerStatefulWidget {
  const NotificationTapListener({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<NotificationTapListener> createState() =>
      _NotificationTapListenerState();
}

class _NotificationTapListenerState
    extends ConsumerState<NotificationTapListener> {
  StreamSubscription<String>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = ref.read(alertNotifierProvider).taps.listen(_open);
  }

  void _open(String route) {
    final router = ref.read(routerProvider);
    // Mark the matching in-app notification as read.
    final center = ref.read(notificationCenterProvider.notifier);
    for (final n in ref.read(notificationCenterProvider)) {
      if (n.route == route) center.markRead(n.id);
    }
    if (route.startsWith(AppRoutes.home)) {
      router.go(route);
    } else {
      unawaited(router.push(route));
    }
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
