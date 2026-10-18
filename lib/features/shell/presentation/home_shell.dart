import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kazzi_credit/features/notifications/application/notification_center.dart';
import 'package:material_ui/material_ui.dart';

/// Bottom navigation around the four main tabs. Each tab keeps its own
/// navigation stack and scroll position.
class HomeShell extends ConsumerWidget {
  const HomeShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  static const List<(IconData, IconData, String)> _tabs = [
    (
      Icons.account_balance_wallet_outlined,
      Icons.account_balance_wallet_rounded,
      'Wallet',
    ),
    (Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Activity'),
    (Icons.donut_large_outlined, Icons.donut_large_rounded, 'Insights'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Live demo purchases only flow while the signed-in shell is shown.
    ref.watch(simulatorRunnerProvider);
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) {
          HapticFeedback.selectionClick().ignore();
          // Re-tapping the current tab pops it back to its root.
          shell.goBranch(i, initialLocation: i == shell.currentIndex);
        },
        destinations: [
          for (final (icon, selected, label) in _tabs)
            NavigationDestination(
              icon: Icon(icon),
              selectedIcon: Icon(selected),
              label: label,
            ),
        ],
      ),
    );
  }
}
