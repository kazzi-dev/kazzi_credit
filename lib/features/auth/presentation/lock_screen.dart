import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kazzi_credit/core/theme/app_tokens.dart';
import 'package:kazzi_credit/core/theme/theme_extensions.dart';
import 'package:kazzi_credit/core/widgets/app_sheet.dart';
import 'package:kazzi_credit/core/widgets/fill_scroll.dart';
import 'package:kazzi_credit/core/widgets/kazzi_logo.dart';
import 'package:kazzi_credit/core/widgets/shake.dart';
import 'package:kazzi_credit/features/auth/application/auth_controller.dart';
import 'package:kazzi_credit/features/auth/data/auth_repository.dart';
import 'package:kazzi_credit/features/auth/data/biometric_service.dart';
import 'package:kazzi_credit/features/auth/presentation/widgets/pin_dots.dart';
import 'package:kazzi_credit/features/auth/presentation/widgets/pin_error_line.dart';
import 'package:kazzi_credit/features/auth/presentation/widgets/pin_pad.dart';
import 'package:material_ui/material_ui.dart';

const _pinLength = 6;

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final _shakeKey = GlobalKey<ShakeState>();
  String _pin = '';
  String? _error;
  bool _checking = false;
  DateTime? _lockedUntil;
  Timer? _ticker;

  bool get _lockedOut => _lockedUntil != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    final until = await ref.read(authControllerProvider.notifier).lockedUntil();
    if (!mounted) return;
    if (until != null) {
      _startLockout(until);
    } else if (ref.read(authControllerProvider).biometricsEnabled) {
      await _tryBiometrics();
    }
  }

  Future<void> _tryBiometrics() async {
    if (_lockedOut || _checking) return;
    // On success the router leaves this screen by itself.
    await ref.read(authControllerProvider.notifier).unlockWithBiometrics();
  }

  void _onDigit(String d) {
    if (_checking || _lockedOut || _pin.length == _pinLength) return;
    setState(() {
      _pin += d;
      if (!_lockedOut) _error = null;
    });
    if (_pin.length == _pinLength) unawaited(_submit());
  }

  void _onBackspace() {
    if (_checking || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _submit() async {
    setState(() => _checking = true);
    final result = await ref
        .read(authControllerProvider.notifier)
        .unlockWithPin(_pin);
    if (!mounted) return;

    switch (result) {
      case PinCorrect():
        unawaited(HapticFeedback.mediumImpact());
        return;
      case PinWrong(:final attemptsLeft):
        setState(() {
          _error = attemptsLeft == 1
              ? 'Incorrect PIN. 1 attempt left before a short lock.'
              : 'Incorrect PIN. $attemptsLeft attempts left.';
        });
      case PinLockedOut(:final until):
        _startLockout(until);
    }
    setState(() {
      _pin = '';
      _checking = false;
    });
    await _shakeKey.currentState?.shake();
  }

  void _startLockout(DateTime until) {
    _ticker?.cancel();
    setState(() {
      _lockedUntil = until;
      _error = _lockoutMessage(until);
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (DateTime.now().isAfter(until)) {
        timer.cancel();
        setState(() {
          _lockedUntil = null;
          _error = null;
        });
      } else {
        setState(() => _error = _lockoutMessage(until));
      }
    });
  }

  String _lockoutMessage(DateTime until) {
    final secs = until.difference(DateTime.now()).inSeconds + 1;
    return 'Too many attempts. Try again in ${secs}s.';
  }

  Future<void> _forgotPin() async {
    final confirmed = await showConfirmSheet(
      context: context,
      title: 'Reset Kazzi Credit?',
      message:
          'For your security a forgotten PIN can’t be recovered. Resetting '
          'removes your cards and data from this device, then you’ll set up '
          'a new PIN.',
      confirmLabel: 'Reset app',
      destructive: true,
    );
    if (confirmed) {
      await ref.read(authControllerProvider.notifier).resetApp();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final auth = ref.watch(authControllerProvider);
    final bio = ref.watch(biometricAvailabilityProvider).value;
    final showBiometric = auth.biometricsEnabled && (bio?.isAvailable ?? false);

    return Scaffold(
      body: SafeArea(
        child: FillScroll(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.page,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            children: [
              const Spacer(),
              const KazziLogo(size: 56),
              const SizedBox(height: AppSpacing.xl),
              Text(
                _greeting(),
                textAlign: TextAlign.center,
                style: context.text.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Enter your PIN to unlock',
                textAlign: TextAlign.center,
                style: context.text.bodyMedium?.copyWith(
                  color: c.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Shake(
                key: _shakeKey,
                child: PinDots(
                  filled: _pin.length,
                  error: _error != null && _pin.isEmpty,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PinErrorLine(message: _error),
              const Spacer(),
              const SizedBox(height: AppSpacing.lg),
              PinPad(
                enabled: !_checking && !_lockedOut,
                onDigit: _onDigit,
                onBackspace: _onBackspace,
                onClear: () => setState(() => _pin = ''),
                leading: showBiometric
                    ? PinPadKey(
                        icon: bio!.kind == BiometricKind.face
                            ? Icons.face_rounded
                            : Icons.fingerprint_rounded,
                        semanticLabel: 'Unlock with ${bio.label}',
                        enabled: !_lockedOut,
                        onTap: _tryBiometrics,
                      )
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: _forgotPin,
                child: const Text('Forgot PIN?'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'Welcome back';
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }
}
