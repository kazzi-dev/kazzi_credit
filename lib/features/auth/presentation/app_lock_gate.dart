import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kazzi_credit/core/theme/theme_extensions.dart';
import 'package:kazzi_credit/core/widgets/kazzi_logo.dart';
import 'package:kazzi_credit/features/auth/application/auth_controller.dart';
import 'package:material_ui/material_ui.dart';

/// Wraps the whole app to:
/// - relock after it has been in the background longer than
///   [autoLockAfterProvider];
/// - blur the UI whenever the app isn't in the foreground, so balances
///   and card details don't show in the app switcher.
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate> {
  late final AppLifecycleListener _listener;
  DateTime? _backgroundedAt;
  bool _obscured = false;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(onStateChange: _onStateChange);
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  void _onStateChange(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        final since = _backgroundedAt;
        _backgroundedAt = null;
        if (since != null &&
            DateTime.now().difference(since) >=
                ref.read(autoLockAfterProvider)) {
          ref.read(authControllerProvider.notifier).lock();
        }
        setState(() => _obscured = false);
      case AppLifecycleState.inactive:
        // Covers the app switcher. Also briefly shows behind system sheets
        // like the Face ID prompt, which is fine.
        setState(() => _obscured = true);
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _backgroundedAt ??= DateTime.now();
        setState(() => _obscured = true);
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_obscured)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: ColoredBox(
                color: context.colors.background.withValues(alpha: 0.55),
                child: const Center(child: KazziLogo(size: 64)),
              ),
            ),
          ),
      ],
    );
  }
}
