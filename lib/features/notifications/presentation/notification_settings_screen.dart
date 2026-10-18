import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kazzi_credit/core/theme/app_tokens.dart';
import 'package:kazzi_credit/core/theme/theme_extensions.dart';
import 'package:kazzi_credit/core/utils/money_format.dart';
import 'package:kazzi_credit/core/widgets/app_button.dart';
import 'package:kazzi_credit/core/widgets/app_toast.dart';
import 'package:kazzi_credit/core/widgets/motion_size.dart';
import 'package:kazzi_credit/core/widgets/surface_panel.dart';
import 'package:kazzi_credit/features/notifications/application/notification_center.dart';
import 'package:kazzi_credit/features/notifications/domain/app_notification.dart';
import 'package:material_ui/material_ui.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  static const _thresholds = <double>[1000, 2500, 5000, 10000, 25000];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(notificationSettingsProvider);
    final settings = ref.read(notificationSettingsProvider.notifier);
    final c = context.colors;

    return Scaffold(
      appBar: AppBar(title: const Text('Notification settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.sm,
          AppSpacing.page,
          AppSpacing.xxxl,
        ),
        children: [
          const _SectionTitle('Alerts'),
          SurfacePanel(
            children: [
              for (final type in NotificationType.values)
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xs,
                  ),
                  secondary: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: type.color.withValues(alpha: 0.14),
                      borderRadius: AppRadii.mdAll,
                    ),
                    child: Icon(type.icon, color: type.color, size: 20),
                  ),
                  title: Text(type.label, style: context.text.titleSmall),
                  subtitle: Text(
                    type.required
                        ? 'Always on to keep your account safe'
                        : type.description,
                    style: context.text.bodySmall,
                  ),
                  value: s.isEnabled(type),
                  onChanged: type.required
                      ? null
                      : (on) => settings.toggle(type, enabled: on),
                ),
            ],
          ),
          MotionSize(
            child: s.isEnabled(NotificationType.largePurchase)
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionTitle('Large purchase threshold'),
                      Text(
                        'Alert me about charges of at least:',
                        style: context.text.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (final t in _thresholds)
                            ChoiceChip(
                              label: Text(
                                MoneyFormat.format(t).replaceAll('.00', ''),
                              ),
                              showCheckmark: false,
                              selected: s.largePurchaseThreshold == t,
                              onSelected: (_) => settings.update(
                                (x) => x.copyWith(largePurchaseThreshold: t),
                              ),
                            ),
                        ],
                      ),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
          const _SectionTitle('Quiet hours'),
          SurfacePanel(
            children: [
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xs,
                ),
                title: Text('Quiet hours', style: context.text.titleSmall),
                subtitle: Text(
                  'No sounds or banners. Alerts still show up here.',
                  style: context.text.bodySmall,
                ),
                value: s.quietHoursEnabled,
                onChanged: (on) =>
                    settings.update((x) => x.copyWith(quietHoursEnabled: on)),
              ),
              if (s.quietHoursEnabled) ...[
                _TimeRow(
                  label: 'From',
                  minutes: s.quietStartMinutes,
                  onPicked: (m) =>
                      settings.update((x) => x.copyWith(quietStartMinutes: m)),
                ),
                _TimeRow(
                  label: 'To',
                  minutes: s.quietEndMinutes,
                  onPicked: (m) =>
                      settings.update((x) => x.copyWith(quietEndMinutes: m)),
                ),
              ],
            ],
          ),
          const _SectionTitle('Try it'),
          Text(
            'Demo purchases also arrive on their own every 30–60 seconds '
            'in debug builds.',
            style: context.text.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Simulate a purchase',
            icon: Icons.bolt_rounded,
            variant: AppButtonVariant.secondary,
            onPressed: () => _simulate(context, ref, suspicious: false),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Simulate a suspicious charge',
            icon: Icons.gpp_maybe_rounded,
            variant: AppButtonVariant.secondary,
            onPressed: () => _simulate(context, ref, suspicious: true),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: c.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  "If banners don't appear, allow notifications for Kazzi "
                  'Credit in your phone settings.',
                  style: context.text.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _simulate(
    BuildContext context,
    WidgetRef ref, {
    required bool suspicious,
  }) {
    final tx = ref
        .read(liveSimulatorProvider)
        .simulateOnce(suspicious: suspicious);
    showAppToast(
      context,
      tx == null
          ? 'All cards are frozen — unfreeze one to simulate'
          : 'New charge: ${tx.merchant} ${MoneyFormat.format(tx.amount)}',
      icon: Icons.bolt_rounded,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.md),
      child: Semantics(
        header: true,
        child: Text(text, style: context.text.titleMedium),
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.label,
    required this.minutes,
    required this.onPicked,
  });

  final String label;
  final int minutes;
  final ValueChanged<int> onPicked;

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      title: Text(label, style: context.text.bodyMedium),
      trailing: Text(time.format(context), style: context.text.titleSmall),
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time,
        );
        if (picked != null) onPicked(picked.hour * 60 + picked.minute);
      },
    );
  }
}
