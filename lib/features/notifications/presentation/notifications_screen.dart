import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kazzi_credit/core/router/routes.dart';
import 'package:kazzi_credit/core/theme/app_tokens.dart';
import 'package:kazzi_credit/core/theme/theme_extensions.dart';
import 'package:kazzi_credit/core/widgets/app_toast.dart';
import 'package:kazzi_credit/core/widgets/empty_state.dart';
import 'package:kazzi_credit/features/cards/application/cards_controller.dart';
import 'package:kazzi_credit/features/notifications/application/notification_center.dart';
import 'package:kazzi_credit/features/notifications/domain/app_notification.dart';
import 'package:kazzi_credit/features/transactions/domain/tx_query.dart';
import 'package:material_ui/material_ui.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(notificationCenterProvider);
    final unread = ref.watch(unreadCountProvider);
    final now = ref.watch(clockProvider)();
    final center = ref.read(notificationCenterProvider.notifier);

    // Group by calendar day, newest first.
    final groups = <(String, List<AppNotification>)>[];
    for (final n in items) {
      final label = dayLabel(n.createdAt, now);
      if (groups.isEmpty || groups.last.$1 != label) {
        groups.add((label, [n]));
      } else {
        groups.last.$2.add(n);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: unread == 0
                ? null
                : () {
                    HapticFeedback.lightImpact().ignore();
                    center.markAllRead();
                  },
            child: const Text('Mark all read'),
          ),
          IconButton(
            tooltip: 'Notification settings',
            onPressed: () => context.push(AppRoutes.notificationSettings),
            icon: const Icon(Icons.tune_rounded),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: items.isEmpty
          ? const Center(
              child: EmptyState(
                icon: Icons.notifications_none_rounded,
                title: "You're all caught up",
                message:
                    "We'll let you know about new purchases, due dates and "
                    'anything unusual.',
              ),
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
              children: [
                for (final (label, group) in groups) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.page,
                      AppSpacing.lg,
                      AppSpacing.page,
                      AppSpacing.sm,
                    ),
                    child: Semantics(
                      header: true,
                      child: Text(
                        label,
                        style: context.text.labelMedium?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  for (final n in group)
                    _NotificationTile(key: ValueKey(n.id), n: n, now: now),
                ],
              ],
            ),
    );
  }
}

String _ago(DateTime at, DateTime now) {
  final d = now.difference(at);
  if (d.inMinutes < 1) return 'now';
  if (d.inMinutes < 60) return '${d.inMinutes}m';
  if (d.inHours < 24) return '${d.inHours}h';
  return DateFormat.MMMd().format(at);
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.n, required this.now, super.key});

  final AppNotification n;
  final DateTime now;

  void _open(BuildContext context, WidgetRef ref) {
    ref.read(notificationCenterProvider.notifier).markRead(n.id);
    final route = n.route;
    if (route == null) return;
    // Tab destinations switch tabs; everything else stacks on top.
    if (route.startsWith(AppRoutes.home)) {
      context.go(route);
    } else {
      unawaited(context.push(route));
    }
  }

  void _dismiss(BuildContext context, WidgetRef ref) {
    final center = ref.read(notificationCenterProvider.notifier);
    final removed = center.dismiss(n.id);
    if (removed == null) return;
    showAppToast(
      context,
      'Notification dismissed',
      icon: Icons.delete_outline_rounded,
      onUndo: () => center.restore(removed),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final type = n.type;
    final unread = !n.read;

    return Dismissible(
      key: ValueKey('dismiss-${n.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _dismiss(context, ref),
      background: Container(
        color: c.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.white),
            SizedBox(width: AppSpacing.sm),
            Text('Dismiss', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
      child: Semantics(
        label: unread ? 'Unread' : null,
        customSemanticsActions: {
          const CustomSemanticsAction(label: 'Dismiss'): () =>
              _dismiss(context, ref),
        },
        child: Material(
          color: unread
              ? c.primarySoft.withValues(alpha: context.isDark ? 0.5 : 0.45)
              : c.background,
          child: InkWell(
            onTap: () => _open(context, ref),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.md,
                AppSpacing.page,
                AppSpacing.md,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: type.color.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(type.icon, color: type.color, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                n.title,
                                style: context.text.titleSmall?.copyWith(
                                  fontWeight: unread
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              _ago(n.createdAt, now),
                              style: context.text.bodySmall,
                            ),
                            if (unread) ...[
                              const SizedBox(width: AppSpacing.sm),
                              Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: c.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          n.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.bodySmall,
                        ),
                        if (type == NotificationType.suspicious && unread)
                          _SuspiciousActions(n: n),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Inline answers to "Was this you?" so the user can act without
/// opening anything.
class _SuspiciousActions extends ConsumerWidget {
  const _SuspiciousActions({required this.n});

  final AppNotification n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final center = ref.read(notificationCenterProvider.notifier);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            ),
            onPressed: () {
              center.markRead(n.id);
              showAppToast(
                context,
                "Thanks — we've marked it as yours",
                tone: ToastTone.success,
              );
            },
            child: const Text('It was me'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: c.error,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            ),
            onPressed: n.cardId == null
                ? null
                : () {
                    HapticFeedback.heavyImpact().ignore();
                    final cards = ref.read(cardsProvider.notifier)
                      ..setFrozen(n.cardId!, frozen: true);
                    center.markRead(n.id);
                    showAppToast(
                      context,
                      'Card frozen. Review the charge to report it.',
                      icon: Icons.ac_unit_rounded,
                      onUndo: () => cards.setFrozen(n.cardId!, frozen: false),
                    );
                  },
            child: const Text('Freeze card'),
          ),
        ],
      ),
    );
  }
}
