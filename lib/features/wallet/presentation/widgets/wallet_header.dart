import 'package:kazzi_credit/core/theme/app_tokens.dart';
import 'package:kazzi_credit/core/theme/theme_extensions.dart';
import 'package:material_ui/material_ui.dart';

class WalletHeader extends StatelessWidget {
  const WalletHeader({
    required this.name,
    required this.initials,
    required this.unread,
    required this.onProfile,
    required this.onNotifications,
    super.key,
  });

  final String name;
  final String initials;
  final int unread;
  final VoidCallback onProfile;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Profile',
            excludeSemantics: true,
            child: InkWell(
              onTap: onProfile,
              customBorder: const CircleBorder(),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: c.accent,
                child: initials.isEmpty
                    ? Icon(Icons.person_rounded, color: c.onAccent)
                    : Text(
                        initials,
                        style: context.text.titleSmall?.copyWith(
                          color: c.onAccent,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Hi, $name',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.titleLarge,
            ),
          ),
          IconButton(
            tooltip: unread > 0
                ? 'Notifications, $unread unread'
                : 'Notifications',
            onPressed: onNotifications,
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              backgroundColor: c.error,
              child: const Icon(Icons.notifications_none_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
