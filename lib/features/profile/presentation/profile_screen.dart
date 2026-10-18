import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kazzi_credit/core/router/routes.dart';
import 'package:kazzi_credit/core/theme/app_tokens.dart';
import 'package:kazzi_credit/core/theme/theme_extensions.dart';
import 'package:kazzi_credit/core/theme/theme_mode_controller.dart';
import 'package:kazzi_credit/core/widgets/app_sheet.dart';
import 'package:kazzi_credit/core/widgets/app_toast.dart';
import 'package:kazzi_credit/core/widgets/surface_panel.dart';
import 'package:kazzi_credit/features/auth/application/auth_controller.dart';
import 'package:kazzi_credit/features/profile/application/profile_controller.dart';
import 'package:kazzi_credit/features/profile/presentation/edit_profile_sheet.dart';
import 'package:material_ui/material_ui.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final auth = ref.watch(authControllerProvider);
    final bio = ref.watch(biometricAvailabilityProvider).value;
    final mode = ref.watch(themeModeProvider);
    final c = context.colors;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.lg,
            AppSpacing.page,
            AppSpacing.xxxl,
          ),
          children: [
            Semantics(
              header: true,
              child: Text('Profile', style: context.text.headlineMedium),
            ),
            const SizedBox(height: AppSpacing.xl),
            _ProfileHeader(
              profile: profile,
              onEdit: () => showEditProfileSheet(context),
            ),
            const _Section('Preferences'),
            SurfacePanel(
              children: [
                _Tile(
                  icon: Icons.dark_mode_outlined,
                  title: 'Appearance',
                  value: switch (mode) {
                    ThemeMode.light => 'Light',
                    ThemeMode.dark => 'Dark',
                    ThemeMode.system => 'System',
                  },
                  onTap: () => _pickAppearance(context, ref),
                ),
                _Tile(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications',
                  onTap: () => context.push(AppRoutes.notificationSettings),
                ),
                const _Tile(
                  icon: Icons.payments_outlined,
                  title: 'Currency',
                  value: 'Philippine peso (₱)',
                ),
              ],
            ),
            const _Section('Security'),
            SurfacePanel(
              children: [
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  secondary: Icon(
                    Icons.fingerprint_rounded,
                    color: c.textSecondary,
                  ),
                  title: Text(
                    'Unlock with ${bio?.label ?? 'biometrics'}',
                    style: context.text.bodyLarge,
                  ),
                  subtitle: bio?.isAvailable ?? false
                      ? null
                      : Text(
                          'Not set up on this phone',
                          style: context.text.bodySmall,
                        ),
                  value: auth.biometricsEnabled && (bio?.isAvailable ?? false),
                  onChanged: bio?.isAvailable ?? false
                      ? (on) => _toggleBiometrics(context, ref, on: on)
                      : null,
                ),
                _Tile(
                  icon: Icons.lock_outline_rounded,
                  title: 'Lock now',
                  onTap: () => ref.read(authControllerProvider.notifier).lock(),
                ),
              ],
            ),
            const _Section('About'),
            SurfacePanel(
              children: [
                _Tile(
                  icon: Icons.help_outline_rounded,
                  title: 'Help & support',
                  onTap: () => showAppSheet<void>(
                    context: context,
                    title: 'Help & support',
                    message:
                        'Kazzi Credit keeps your cards and activity on this '
                        'phone. For a lost or stolen card, freeze it from the '
                        'wallet, then call the hotline on the back of your '
                        'physical card.',
                  ),
                ),
                _Tile(
                  icon: Icons.info_outline_rounded,
                  title: 'About Kazzi Credit',
                  value: 'Version 1.0',
                  // Developer shortcut to the component gallery.
                  onLongPress: () => context.go(AppRoutes.designSystem),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: TextButton(
                style: TextButton.styleFrom(foregroundColor: c.error),
                onPressed: () => _reset(context, ref),
                child: const Text('Reset app'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleBiometrics(
    BuildContext context,
    WidgetRef ref, {
    required bool on,
  }) async {
    final auth = ref.read(authControllerProvider.notifier);
    if (on) {
      final ok = await ref
          .read(biometricServiceProvider)
          .authenticate('Confirm to turn on biometric unlock');
      if (!ok) return;
    }
    await auth.setBiometricsEnabled(enabled: on);
    if (context.mounted) {
      showAppToast(
        context,
        on ? 'Biometric unlock is on' : 'Biometric unlock is off',
        tone: on ? ToastTone.success : ToastTone.neutral,
      );
    }
  }

  Future<void> _pickAppearance(BuildContext context, WidgetRef ref) =>
      showAppSheet<void>(
        context: context,
        title: 'Appearance',
        child: Consumer(
          builder: (context, ref, _) {
            final mode = ref.watch(themeModeProvider);
            return Column(
              children: [
                for (final (m, label) in const [
                  (ThemeMode.system, 'Match phone'),
                  (ThemeMode.light, 'Light'),
                  (ThemeMode.dark, 'Dark'),
                ])
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(label),
                    trailing: m == mode
                        ? Icon(
                            Icons.check_rounded,
                            color: context.colors.textPrimary,
                          )
                        : null,
                    onTap: () {
                      HapticFeedback.selectionClick().ignore();
                      ref.read(themeModeProvider.notifier).mode = m;
                    },
                  ),
              ],
            );
          },
        ),
      );

  Future<void> _reset(BuildContext context, WidgetRef ref) async {
    final ok = await showConfirmSheet(
      context: context,
      title: 'Reset Kazzi Credit?',
      message:
          'This removes your profile, PIN, cards and activity from this '
          "phone. You'll start setup again.",
      confirmLabel: 'Reset app',
      destructive: true,
    );
    if (ok) await ref.read(authControllerProvider.notifier).resetApp();
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile, required this.onEdit});

  final Profile profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final details = [
      if (profile.mobile.isNotEmpty) profile.mobileDisplay,
      if (profile.email.isNotEmpty) profile.email,
    ];
    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: c.surfaceHigh,
          child: profile.initials.isEmpty
              ? Icon(Icons.person_rounded, color: c.textSecondary, size: 32)
              : Text(profile.initials, style: context.text.headlineSmall),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.isEmpty ? 'Add your name' : profile.name,
                style: context.text.titleLarge,
              ),
              for (final d in details) Text(d, style: context.text.bodySmall),
              Text(
                'Member since '
                '${DateFormat.yMMM().format(profile.memberSince)}',
                style: context.text.bodySmall?.copyWith(color: c.textTertiary),
              ),
            ],
          ),
        ),
        OutlinedButton(
          onPressed: onEdit,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          ),
          child: const Text('Edit'),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        AppSpacing.xxl,
        0,
        AppSpacing.sm,
      ),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: context.text.labelMedium?.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    this.value,
    this.onTap,
    this.onLongPress,
  });

  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      leading: Icon(icon, color: c.textSecondary),
      title: Text(title, style: context.text.bodyLarge),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null) Text(value!, style: context.text.bodySmall),
          if (onTap != null)
            Icon(Icons.chevron_right_rounded, color: c.textTertiary),
        ],
      ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
