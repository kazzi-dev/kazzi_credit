import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kazzi_credit/core/theme/app_tokens.dart';
import 'package:kazzi_credit/core/theme/theme_extensions.dart';
import 'package:kazzi_credit/core/widgets/shake.dart';
import 'package:kazzi_credit/features/auth/application/auth_controller.dart';
import 'package:kazzi_credit/features/auth/data/auth_repository.dart';
import 'package:kazzi_credit/features/auth/presentation/widgets/pin_dots.dart';
import 'package:kazzi_credit/features/auth/presentation/widgets/pin_error_line.dart';
import 'package:kazzi_credit/features/auth/presentation/widgets/pin_pad.dart';
import 'package:material_ui/material_ui.dart';

/// Confirms it's really the user before showing sensitive data: biometrics
/// when enabled, falling back to the PIN.
Future<bool> reauthenticate(
  BuildContext context,
  WidgetRef ref, {
  required String reason,
}) async {
  if (ref.read(authControllerProvider).biometricsEnabled) {
    final availability = await ref.read(biometricAvailabilityProvider.future);
    if (availability.isAvailable &&
        await ref.read(biometricServiceProvider).authenticate(reason)) {
      return true;
    }
  }
  if (!context.mounted) return false;
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _PinConfirmSheet(reason: reason),
  );
  return ok ?? false;
}

class _PinConfirmSheet extends ConsumerStatefulWidget {
  const _PinConfirmSheet({required this.reason});

  final String reason;

  @override
  ConsumerState<_PinConfirmSheet> createState() => _PinConfirmSheetState();
}

class _PinConfirmSheetState extends ConsumerState<_PinConfirmSheet> {
  final _shakeKey = GlobalKey<ShakeState>();
  String _pin = '';
  String? _error;
  bool _busy = false;
  bool _lockedOut = false;

  void _onDigit(String d) {
    if (_busy || _lockedOut || _pin.length == 6) return;
    setState(() {
      _pin += d;
      _error = null;
    });
    if (_pin.length == 6) _submit().ignore();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    final result = await ref.read(authRepositoryProvider).verifyPin(_pin);
    if (!mounted) return;
    switch (result) {
      case PinCorrect():
        Navigator.of(context).pop(true);
        return;
      case PinWrong(:final attemptsLeft):
        _error = 'Incorrect PIN. $attemptsLeft attempts left.';
      case PinLockedOut():
        _error = 'Too many attempts. Try again in a little while.';
        _lockedOut = true;
    }
    setState(() {
      _pin = '';
      _busy = false;
    });
    await _shakeKey.currentState?.shake();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        0,
        AppSpacing.page,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Enter your PIN', style: context.text.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.reason,
            textAlign: TextAlign.center,
            style: context.text.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Shake(
            key: _shakeKey,
            child: PinDots(filled: _pin.length, error: _error != null),
          ),
          const SizedBox(height: AppSpacing.md),
          PinErrorLine(message: _error),
          PinPad(
            enabled: !_busy && !_lockedOut,
            onDigit: _onDigit,
            onBackspace: () {
              if (_pin.isNotEmpty) {
                setState(() => _pin = _pin.substring(0, _pin.length - 1));
              }
            },
          ),
        ],
      ),
    );
  }
}
