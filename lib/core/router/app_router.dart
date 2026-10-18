import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kazzi_credit/core/router/routes.dart';
import 'package:kazzi_credit/features/auth/application/auth_controller.dart';
import 'package:kazzi_credit/features/auth/presentation/lock_screen.dart';
import 'package:kazzi_credit/features/cards/presentation/add_card_screen.dart';
import 'package:kazzi_credit/features/design_gallery/design_gallery_screen.dart';
import 'package:kazzi_credit/features/insights/presentation/insights_screen.dart';
import 'package:kazzi_credit/features/notifications/presentation/notification_settings_screen.dart';
import 'package:kazzi_credit/features/notifications/presentation/notifications_screen.dart';
import 'package:kazzi_credit/features/onboarding/presentation/finish_setup_screen.dart';
import 'package:kazzi_credit/features/onboarding/presentation/pin_setup_screen.dart';
import 'package:kazzi_credit/features/onboarding/presentation/profile_setup_screen.dart';
import 'package:kazzi_credit/features/onboarding/presentation/welcome_screen.dart';
import 'package:kazzi_credit/features/profile/presentation/profile_screen.dart';
import 'package:kazzi_credit/features/shell/presentation/home_shell.dart';
import 'package:kazzi_credit/features/transactions/presentation/transaction_detail_screen.dart';
import 'package:kazzi_credit/features/transactions/presentation/transactions_screen.dart';
import 'package:kazzi_credit/features/wallet/presentation/wallet_screen.dart';
import 'package:material_ui/material_ui.dart';

export 'package:kazzi_credit/core/router/routes.dart';

/// Where the user should be for a given auth state, or null to stay put.
@visibleForTesting
String? authRedirect(AuthState auth, Uri uri) {
  final loc = uri.path;
  final inOnboarding = loc.startsWith(AppRoutes.onboarding);

  if (!auth.onboarded) {
    if (!inOnboarding) return AppRoutes.onboarding;
    // Later setup steps make no sense without a PIN.
    final pastPin = loc == AppRoutes.finishSetup;
    if (pastPin && !auth.hasPin) return AppRoutes.pinSetup;
    return null;
  }

  if (!auth.unlocked) {
    if (loc == AppRoutes.lock) return null;
    // Keep query parameters (e.g. a deep-linked card) for after unlock.
    final from = uri.toString() == AppRoutes.home ? null : uri.toString();
    return Uri(
      path: AppRoutes.lock,
      queryParameters: from == null ? null : {'from': from},
    ).toString();
  }

  if (loc == AppRoutes.lock || inOnboarding) {
    // Return to where the user was when the app locked. Only accept
    // in-app paths.
    final from = uri.queryParameters['from'];
    final safe = from != null && from.startsWith('/') && !from.startsWith('//');
    return safe ? from : AppRoutes.home;
  }
  return null;
}

/// Where the app opens. main() overrides it when a notification tap
/// cold-started the app.
final initialLocationProvider = Provider<String>((ref) => AppRoutes.home);

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ValueNotifier<AuthState>(ref.read(authControllerProvider));
  ref
    ..listen(authControllerProvider, (_, next) => auth.value = next)
    ..onDispose(auth.dispose);

  final rootKey = GlobalKey<NavigatorState>();
  final router = GoRouter(
    navigatorKey: rootKey,
    initialLocation: ref.read(initialLocationProvider),
    refreshListenable: auth,
    redirect: (context, state) => authRedirect(auth.value, state.uri),
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const WelcomeScreen(),
        routes: [
          GoRoute(
            path: 'profile',
            builder: (context, state) => const ProfileSetupScreen(),
          ),
          GoRoute(
            path: 'pin',
            builder: (context, state) => const PinSetupScreen(),
          ),
          GoRoute(
            path: 'finish',
            builder: (context, state) => const FinishSetupScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.lock,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: LockScreen()),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
        routes: [
          GoRoute(
            path: 'settings',
            builder: (context, state) => const NotificationSettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.transactionPattern,
        builder: (context, state) => TransactionDetailScreen(
          id: state.pathParameters['id']!,
          from: state.uri.queryParameters['from'],
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const WalletScreen(),
                routes: [
                  // Full screen, above the bottom navigation.
                  GoRoute(
                    path: 'add-card',
                    parentNavigatorKey: rootKey,
                    pageBuilder: (context, state) => const MaterialPage(
                      fullscreenDialog: true,
                      child: AddCardScreen(),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.transactions,
                builder: (context, state) => const TransactionsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.insights,
                builder: (context, state) => const InsightsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'design-system',
                    builder: (context, state) => const DesignGalleryScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
