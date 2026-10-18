import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kazzi_credit/core/router/routes.dart';
import 'package:kazzi_credit/core/theme/app_tokens.dart';
import 'package:kazzi_credit/core/theme/theme_extensions.dart';
import 'package:kazzi_credit/core/widgets/app_button.dart';
import 'package:kazzi_credit/core/widgets/app_text_field.dart';
import 'package:kazzi_credit/features/onboarding/presentation/widgets/setup_header.dart';
import 'package:kazzi_credit/features/profile/application/profile_controller.dart';
import 'package:kazzi_credit/features/profile/domain/profile_validation.dart';
import 'package:material_ui/material_ui.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  late final _name = TextEditingController(
    text: ref.read(profileProvider).name,
  );
  late final _mobile = TextEditingController(
    text: ref.read(profileProvider).mobile,
  );
  late final _email = TextEditingController(
    text: ref.read(profileProvider).email,
  );
  bool _submitted = false;

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    _email.dispose();
    super.dispose();
  }

  void _continue() {
    setState(() => _submitted = true);
    final errors = [
      ProfileValidation.name(_name.text),
      ProfileValidation.mobile(_mobile.text),
      ProfileValidation.email(_email.text),
    ];
    if (errors.any((e) => e != null)) {
      HapticFeedback.heavyImpact().ignore();
      return;
    }
    ref
        .read(profileProvider.notifier)
        .save(
          ref
              .read(profileProvider)
              .copyWith(
                name: _name.text.trim(),
                mobile: ProfileValidation.digits(_mobile.text),
                email: _email.text.trim(),
              ),
        );
    context.go(AppRoutes.pinSetup);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    String? err(String? e) => _submitted ? e : null;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.page,
                vertical: AppSpacing.sm,
              ),
              child: SetupHeader(
                step: 1,
                onBack: () => context.go(AppRoutes.onboarding),
              ),
            ),
            Expanded(
              child: AutofillGroup(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    AppSpacing.xl,
                    AppSpacing.page,
                    AppSpacing.xl,
                  ),
                  children: [
                    Text(
                      'What should we call you?',
                      style: context.text.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Your name appears on your cards in the app.',
                      style: context.text.bodyMedium?.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    AppTextField(
                      key: const ValueKey('field-name'),
                      label: 'Full name',
                      hint: 'Juan Dela Cruz',
                      controller: _name,
                      autofocus: true,
                      errorText: err(ProfileValidation.name(_name.text)),
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      key: const ValueKey('field-mobile'),
                      label: 'Mobile number (optional)',
                      hint: '917 123 4567',
                      prefixText: '+63 ',
                      controller: _mobile,
                      errorText: err(ProfileValidation.mobile(_mobile.text)),
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [
                        AutofillHints.telephoneNumberNational,
                      ],
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      key: const ValueKey('field-email'),
                      label: 'Email (optional)',
                      hint: 'juan@email.com',
                      controller: _email,
                      errorText: err(ProfileValidation.email(_email.text)),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.email],
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _continue(),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.sm,
                AppSpacing.page,
                AppSpacing.lg,
              ),
              child: AppButton(label: 'Continue', onPressed: _continue),
            ),
          ],
        ),
      ),
    );
  }
}
