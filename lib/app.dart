import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kazzi_credit/core/router/app_router.dart';
import 'package:kazzi_credit/core/theme/app_theme.dart';
import 'package:kazzi_credit/core/theme/theme_mode_controller.dart';
import 'package:kazzi_credit/features/auth/presentation/app_lock_gate.dart';
import 'package:kazzi_credit/features/notifications/presentation/notification_tap_listener.dart';
import 'package:material_ui/material_ui.dart';

class KazziApp extends ConsumerWidget {
  const KazziApp({super.key, this.useGoogleFonts = true});

  /// Tests turn this off so they don't fetch fonts over the network.
  final bool useGoogleFonts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Kazzi Credit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(useGoogleFonts: useGoogleFonts),
      darkTheme: AppTheme.dark(useGoogleFonts: useGoogleFonts),
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) =>
          AppLockGate(child: NotificationTapListener(child: child!)),
    );
  }
}
