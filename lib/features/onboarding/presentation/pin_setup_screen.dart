import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kazzi_credit/core/router/routes.dart';
import 'package:kazzi_credit/core/theme/app_tokens.dart';
import 'package:kazzi_credit/core/theme/theme_extensions.dart';
import 'package:kazzi_credit/core/widgets/fill_scroll.dart';
import 'package:kazzi_credit/core/widgets/shake.dart';
import 'package:kazzi_credit/features/auth/application/auth_controller.dart';
import 'package:kazzi_credit/features/auth/presentation/widgets/pin_dots.dart';
import 'package:kazzi_credit/features/auth/presentation/widgets/pin_error_line.dart';
import 'package:kazzi_credit/features/auth/presentation/widgets/pin_pad.dart';
import 'package:kazzi_credit/features/onboarding/presentation/widgets/setup_header.dart';
import 'package:material_ui/material_ui.dart';

const pinLength = 6;

/// PINs that are trivially guessable: repeats, straight runs, and the most
/// common 6-digit choices.
bool isWeakPin(String pin) {
  if (pin.split('').toSet().length == 1) return true;
  const ascending = '01234567890';
  const descending = '09876543210';
  if (ascending.contains(pin) || descending.contains(pin)) return true;
  const common = {'121212', '123123', '112233', '696969', '159753', '147258'};
  return common.contains(pin);
}

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  final _shakeKey = GlobalKey<ShakeState>();
  String? _first;
  String _pin = '';
  String? _error;
  bool _saving = false;

  bool get _confirming => _first != null;

  void _onDigit(String d) {
    if (_saving || _pin.length == pinLength) return;
    setState(() {
      _pin += d;
      _error = null;
    });
    if (_pin.length == pinLength) {
      // Let the last dot fill before reacting.
      Future<void>.delayed(const Duration(milliseconds: 160), _submit).ignore();
    }
  }

  void _onBackspace() {
    if (_saving || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _reject(String message, {bool restart = false}) async {
    setState(() {
      _error = message;
      _pin = '';
      if (restart) _first = null;
    });
    await _shakeKey.currentState?.shake();
  }

  Future<void> _submit() async {
    if (!mounted) return;
    if (!_confirming) {
      if (isWeakPin(_pin)) {
        await _reject('That PIN is easy to guess. Try another.');
        return;
      }
      setState(() {
        _first = _pin;
        _pin = '';
      });
      return;
    }
    if (_pin != _first) {
      await _reject("PINs didn't match. Let's start over.", restart: true);
      return;
    }
    setState(() => _saving = true);
    await ref.read(authControllerProvider.notifier).createPin(_pin);
    unawaited(HapticFeedback.mediumImpact());
    if (mounted) context.go(AppRoutes.finishSetup);
  }

  void _back() {
    if (_confirming) {
      setState(() {
        _first = null;
        _pin = '';
        _error = null;
      });
    } else {
      context.go(AppRoutes.profileSetup);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PopScope(
      canPop: !_confirming,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        body: SafeArea(
          child: FillScroll(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.page,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              children: [
                SetupHeader(step: 2, onBack: _back),
                const SizedBox(height: AppSpacing.xxl),
                AnimatedSwitcher(
                  duration: AppMotion.of(context, AppMotion.medium),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0.08, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: Column(
                    key: ValueKey(_confirming),
                    children: [
                      Text(
                        _confirming ? 'Confirm your PIN' : 'Create your PIN',
                        textAlign: TextAlign.center,
                        style: context.text.headlineMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _confirming ? 'Enter the same 6 digits again.' : "You'll use it to unlock the app and approve sensitive actions.",
                        textAlign: TextAlign.center,
                        style: context.text.bodyMedium?.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Shake(
                  key: _shakeKey,
                  child: _saving
                      ? const SizedBox(
                          height: 18,
                          child: Center(
                            child: SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        )
                      : PinDots(filled: _pin.length, error: _error != null),
                ),
                const SizedBox(height: AppSpacing.lg),
                PinErrorLine(message: _error),
                const Spacer(),
                const SizedBox(height: AppSpacing.lg),
                PinPad(
                  enabled: !_saving,
                  onDigit: _onDigit,
                  onBackspace: _onBackspace,
                  onClear: () => setState(() => _pin = ''),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
