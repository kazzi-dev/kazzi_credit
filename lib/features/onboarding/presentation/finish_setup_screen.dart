import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kazzi_credit/core/theme/app_tokens.dart';
import 'package:kazzi_credit/core/theme/theme_extensions.dart';
import 'package:kazzi_credit/core/widgets/app_button.dart';
import 'package:kazzi_credit/core/widgets/surface_panel.dart';
import 'package:kazzi_credit/features/auth/application/auth_controller.dart';
import 'package:kazzi_credit/features/auth/data/biometric_service.dart';
import 'package:kazzi_credit/features/onboarding/presentation/widgets/setup_header.dart';
import 'package:kazzi_credit/features/profile/application/profile_controller.dart';
import 'package:material_ui/material_ui.dart';

/// Last step: two switches instead of two permission screens.
class FinishSetupScreen extends ConsumerStatefulWidget {
  const FinishSetupScreen({super.key});

  @override
  ConsumerState<FinishSetupScreen> createState() => _FinishSetupScreenState();
}

class _FinishSetupScreenState extends ConsumerState<FinishSetupScreen> {
  bool _biometrics = true;
  bool _alerts = true;
  bool _busy = false;

  Future<void> _finish(BiometricAvailability bio) async {
    setState(() => _busy = true);
    final auth = ref.read(authControllerProvider.notifier);
    if (_biometrics && bio.isAvailable) {
      // Confirm with a real scan so we never enable a sensor that fails.
      final ok = await ref
          .read(biometricServiceProvider)
          .authenticate('Confirm to turn on ${bio.label} unlock');
      if (ok) await auth.setBiometricsEnabled(enabled: true);
    }
    if (_alerts) {
      await ref.read(notificationPermissionServiceProvider).request();
    }
    // Flips auth state; the router then moves to the wallet.
    await auth.completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bio =
        ref.watch(biometricAvailabilityProvider).value ??
        BiometricAvailability.none;
    final name = ref.watch(profileProvider).firstName;

    return PopScope(
      // The PIN is already saved; going back would mean re-creating it.
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.page,
                  vertical: AppSpacing.sm,
                ),
                child: SetupHeader(step: 3),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    AppSpacing.xl,
                    AppSpacing.page,
                    AppSpacing.xl,
                  ),
                  children: [
                    Text(
                      name.isEmpty ? 'Almost done' : 'Almost done, $name',
                      style: context.text.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'You can change these anytime in Profile.',
                      style: context.text.bodyMedium?.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    SurfacePanel(
                      children: [
                        SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.xs,
                          ),
                          secondary: Icon(
                            bio.kind == BiometricKind.face
                                ? Icons.face_rounded
                                : Icons.fingerprint_rounded,
                          ),
                          title: Text(
                            bio.isAvailable
                                ? 'Unlock with ${bio.label}'
                                : 'Biometric unlock',
                            style: context.text.titleSmall,
                          ),
                          subtitle: Text(
                            bio.isAvailable
                                ? 'Faster than your PIN. Stays on this phone.'
                                : 'Set up a fingerprint or face in your phone '
                                      'settings first.',
                            style: context.text.bodySmall,
                          ),
                          value: _biometrics && bio.isAvailable,
                          onChanged: bio.isAvailable && !_busy
                              ? (v) => setState(() => _biometrics = v)
                              : null,
                        ),
                        SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.xs,
                          ),
                          secondary: const Icon(
                            Icons.notifications_none_rounded,
                          ),
                          title: Text(
                            'Purchase alerts',
                            style: context.text.titleSmall,
                          ),
                          subtitle: Text(
                            'Every charge, due dates and anything unusual.',
                            style: context.text.bodySmall,
                          ),
                          value: _alerts,
                          onChanged: _busy
                              ? null
                              : (v) => setState(() => _alerts = v),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  AppSpacing.sm,
                  AppSpacing.page,
                  AppSpacing.lg,
                ),
                child: AppButton(
                  label: 'Finish setup',
                  isLoading: _busy,
                  onPressed: () => _finish(bio),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
