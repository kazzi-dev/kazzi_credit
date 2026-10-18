import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kazzi_credit/core/theme/app_tokens.dart';
import 'package:kazzi_credit/core/theme/card_styles.dart';
import 'package:kazzi_credit/core/theme/theme_extensions.dart';
import 'package:kazzi_credit/core/theme/theme_mode_controller.dart';
import 'package:kazzi_credit/core/widgets/amount_text.dart';
import 'package:kazzi_credit/core/widgets/app_button.dart';
import 'package:kazzi_credit/core/widgets/app_sheet.dart';
import 'package:kazzi_credit/core/widgets/app_text_field.dart';
import 'package:kazzi_credit/core/widgets/app_toast.dart';
import 'package:kazzi_credit/core/widgets/empty_state.dart';
import 'package:kazzi_credit/core/widgets/section_header.dart';
import 'package:kazzi_credit/core/widgets/skeleton.dart';
import 'package:kazzi_credit/features/auth/application/auth_controller.dart';
import 'package:kazzi_credit/features/cards/presentation/widgets/card_front.dart';
import 'package:material_ui/material_ui.dart';

/// Living preview of the design system. Temporary home route until the
/// wallet feature exists; later it moves behind a debug-only menu.
class DesignGalleryScreen extends ConsumerWidget {
  const DesignGalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections = <Widget>[
      const _BalanceHero(),
      const _Section(title: 'Card themes', child: _CardThemes()),
      const _Section(title: 'Buttons', child: _Buttons()),
      const _Section(title: 'Inputs & chips', child: _Inputs()),
      const _Section(title: 'Feedback', child: _Feedback()),
      const _Section(title: 'Loading & empty', child: _LoadingAndEmpty()),
      const _Section(title: 'Colors', child: _ColorGrid()),
      const _Section(title: 'Typography', child: _TypeScale()),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Design system'),
        actions: [
          IconButton(
            tooltip: 'Lock app',
            onPressed: () => ref.read(authControllerProvider.notifier).lock(),
            icon: const Icon(Icons.lock_outline_rounded),
          ),
          const _ThemeToggle(),
          const SizedBox(width: AppSpacing.md),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.sm,
          AppSpacing.page,
          AppSpacing.xxxl,
        ),
        itemCount: sections.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xxl),
        itemBuilder: (context, i) => sections[i]
            .animate(delay: (60 * i).ms)
            .fadeIn(duration: AppMotion.of(context, AppMotion.slow))
            .slideY(begin: 0.08, curve: AppMotion.emphasized),
      ),
    );
  }
}

class _ThemeToggle extends ConsumerWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SegmentedButton<ThemeMode>(
      showSelectedIcon: false,
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
      segments: const [
        ButtonSegment(
          value: ThemeMode.light,
          icon: Icon(Icons.light_mode_rounded, size: 18),
          tooltip: 'Light',
        ),
        ButtonSegment(
          value: ThemeMode.system,
          icon: Icon(Icons.brightness_auto_rounded, size: 18),
          tooltip: 'System',
        ),
        ButtonSegment(
          value: ThemeMode.dark,
          icon: Icon(Icons.dark_mode_rounded, size: 18),
          tooltip: 'Dark',
        ),
      ],
      selected: {ref.watch(themeModeProvider)},
      onSelectionChanged: (s) =>
          ref.read(themeModeProvider.notifier).mode = s.first,
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    );
  }
}

class _BalanceHero extends StatelessWidget {
  const _BalanceHero();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: AppRadii.xlAll,
        border: context.isDark ? Border.all(color: c.border) : null,
        boxShadow: context.isDark ? null : AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total balance', style: context.text.labelMedium),
          const SizedBox(height: AppSpacing.sm),
          AmountText(
            12480.5,
            style: context.text.displayLarge,
            smallCents: true,
            countUp: true,
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _Pill(
                label: '+ 4.2% this month',
                background: c.income.withValues(alpha: 0.12),
                foreground: c.income,
              ),
              _Pill(
                label: 'Due in 6 days',
                background: c.accent,
                foreground: c.onAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadii.pillAll,
      ),
      child: Text(
        label,
        style: context.text.labelMedium?.copyWith(color: foreground),
      ),
    );
  }
}

class _CardThemes extends StatelessWidget {
  const _CardThemes();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: CardStyle.all.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.lg),
        itemBuilder: (context, i) {
          final theme = CardStyle.all[i];
          return SizedBox(
            width: 260,
            child: CardFront(
              style: theme,
              last4: '4821',
              nickname: theme.name,
              holder: 'Alex Morgan',
              expiry: '09/29',
            ),
          );
        },
      ),
    );
  }
}

class _Buttons extends StatefulWidget {
  const _Buttons();

  @override
  State<_Buttons> createState() => _ButtonsState();
}

class _ButtonsState extends State<_Buttons> {
  bool _loading = false;

  Future<void> _fakeLoad() async {
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppButton(label: 'Pay bill', isLoading: _loading, onPressed: _fakeLoad),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: 'Add card',
          icon: Icons.add_rounded,
          variant: AppButtonVariant.accent,
          onPressed: () {},
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: 'View statement',
          variant: AppButtonVariant.secondary,
          onPressed: () {},
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: 'Delete card',
          variant: AppButtonVariant.destructive,
          onPressed: () => showConfirmSheet(
            context: context,
            title: 'Delete this card?',
            message:
                'Midnight •• 4821 and its transaction history will be '
                'removed from this device.',
            confirmLabel: 'Delete card',
            destructive: true,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const AppButton(label: 'Disabled', onPressed: null),
      ],
    );
  }
}

class _Inputs extends StatefulWidget {
  const _Inputs();

  @override
  State<_Inputs> createState() => _InputsState();
}

class _InputsState extends State<_Inputs> {
  String _chip = 'All';
  bool _alerts = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppTextField(
          label: 'Search',
          hint: 'Merchant, category or amount',
          prefixIcon: Icons.search_rounded,
        ),
        const SizedBox(height: AppSpacing.lg),
        const AppTextField(
          label: 'Card nickname',
          hint: 'e.g. Travel card',
          errorText: 'Nickname is too long',
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final label in const ['All', 'Food', 'Shopping', 'Travel'])
              ChoiceChip(
                label: Text(label),
                selected: _chip == label,
                showCheckmark: false,
                onSelected: (_) => setState(() => _chip = label),
              ),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Large purchase alerts'),
          subtitle: const Text('Notify me above ₱5,000'),
          value: _alerts,
          onChanged: (v) => setState(() => _alerts = v),
        ),
      ],
    );
  }
}

class _Feedback extends StatelessWidget {
  const _Feedback();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Netflix', style: context.text.titleMedium)),
            AmountText(-15.99, style: context.text.titleMedium),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: Text('Refund · Zara', style: context.text.titleMedium),
            ),
            AmountText(
              49.9,
              signed: true,
              colorize: true,
              style: context.text.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            OutlinedButton(
              onPressed: () => showAppToast(
                context,
                'Card frozen',
                icon: Icons.ac_unit_rounded,
                onUndo: () {},
              ),
              child: const Text('Undo toast'),
            ),
            OutlinedButton(
              onPressed: () =>
                  showAppToast(context, 'Card added', tone: ToastTone.success),
              child: const Text('Success toast'),
            ),
          ],
        ),
      ],
    );
  }
}

class _LoadingAndEmpty extends StatelessWidget {
  const _LoadingAndEmpty();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SkeletonListTile(),
        const SkeletonListTile(),
        const SizedBox(height: AppSpacing.lg),
        EmptyState(
          icon: Icons.receipt_long_rounded,
          title: 'No transactions yet',
          message: 'Purchases on this card will show up here as they happen.',
          actionLabel: 'Add a card',
          onAction: () {},
        ),
      ],
    );
  }
}

class _ColorGrid extends StatelessWidget {
  const _ColorGrid();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final swatches = <(String, Color)>[
      ('Primary', c.primary),
      ('Accent', c.accent),
      ('Surface', c.surface),
      ('Surface high', c.surfaceHigh),
      ('Text', c.textPrimary),
      ('Text 2', c.textSecondary),
      ('Success', c.success),
      ('Warning', c.warning),
      ('Error', c.error),
    ];
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.lg,
      children: [
        for (final (name, color) in swatches)
          SizedBox(
            width: 92,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: AppRadii.mdAll,
                    border: Border.all(color: c.border),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(name, style: context.text.labelMedium),
              ],
            ),
          ),
      ],
    );
  }
}

class _TypeScale extends StatelessWidget {
  const _TypeScale();

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final styles = <(String, TextStyle?)>[
      ('Display L · 40', t.displayLarge),
      ('Display M · 32', t.displayMedium),
      ('Headline · 24', t.headlineMedium),
      ('Title · 18', t.titleLarge),
      ('Body · 16', t.bodyLarge),
      ('Body · 14', t.bodyMedium),
      ('Label · 13', t.labelMedium),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (name, style) in styles)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(name, style: style),
          ),
      ],
    );
  }
}
