import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kazzi_credit/core/theme/app_tokens.dart';
import 'package:kazzi_credit/core/widgets/app_button.dart';
import 'package:kazzi_credit/core/widgets/app_sheet.dart';
import 'package:kazzi_credit/core/widgets/app_text_field.dart';
import 'package:kazzi_credit/core/widgets/app_toast.dart';
import 'package:kazzi_credit/features/profile/application/profile_controller.dart';
import 'package:kazzi_credit/features/profile/domain/profile_validation.dart';
import 'package:material_ui/material_ui.dart';

Future<void> showEditProfileSheet(BuildContext context) => showAppSheet<void>(
  context: context,
  title: 'Edit profile',
  child: const _EditProfileForm(),
);

class _EditProfileForm extends ConsumerStatefulWidget {
  const _EditProfileForm();

  @override
  ConsumerState<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends ConsumerState<_EditProfileForm> {
  late final Profile _initial = ref.read(profileProvider);
  late final _name = TextEditingController(text: _initial.name);
  late final _mobile = TextEditingController(text: _initial.mobile);
  late final _email = TextEditingController(text: _initial.email);
  bool _submitted = false;

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    _email.dispose();
    super.dispose();
  }

  void _save() {
    setState(() => _submitted = true);
    final invalid = [
      ProfileValidation.name(_name.text),
      ProfileValidation.mobile(_mobile.text),
      ProfileValidation.email(_email.text),
    ].any((e) => e != null);
    if (invalid) {
      HapticFeedback.heavyImpact().ignore();
      return;
    }
    ref
        .read(profileProvider.notifier)
        .save(
          _initial.copyWith(
            name: _name.text.trim(),
            mobile: ProfileValidation.digits(_mobile.text),
            email: _email.text.trim(),
          ),
        );
    showAppToast(context, 'Profile updated', tone: ToastTone.success);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    String? err(String? e) => _submitted ? e : null;
    return AutofillGroup(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            key: const ValueKey('edit-name'),
            label: 'Full name',
            controller: _name,
            errorText: err(ProfileValidation.name(_name.text)),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            key: const ValueKey('edit-mobile'),
            label: 'Mobile number',
            hint: '917 123 4567',
            prefixText: '+63 ',
            controller: _mobile,
            errorText: err(ProfileValidation.mobile(_mobile.text)),
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            key: const ValueKey('edit-email'),
            label: 'Email',
            controller: _email,
            errorText: err(ProfileValidation.email(_email.text)),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(label: 'Save', onPressed: _save),
        ],
      ),
    );
  }
}
