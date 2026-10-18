import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kazzi_credit/core/security/secure_screen.dart';
import 'package:kazzi_credit/core/theme/app_tokens.dart';
import 'package:kazzi_credit/core/theme/card_styles.dart';
import 'package:kazzi_credit/core/theme/theme_extensions.dart';
import 'package:kazzi_credit/core/widgets/app_button.dart';
import 'package:kazzi_credit/core/widgets/app_sheet.dart';
import 'package:kazzi_credit/core/widgets/app_text_field.dart';
import 'package:kazzi_credit/core/widgets/motion_size.dart';
import 'package:kazzi_credit/features/cards/application/cards_controller.dart';
import 'package:kazzi_credit/features/cards/domain/card_network.dart';
import 'package:kazzi_credit/features/cards/domain/card_validation.dart';
import 'package:kazzi_credit/features/cards/domain/payment_card.dart';
import 'package:kazzi_credit/features/cards/presentation/card_input_formatters.dart';
import 'package:kazzi_credit/features/cards/presentation/widgets/add_card_success.dart';
import 'package:kazzi_credit/features/cards/presentation/widgets/card_back.dart';
import 'package:kazzi_credit/features/cards/presentation/widgets/card_front.dart';
import 'package:kazzi_credit/features/cards/presentation/widgets/card_theme_picker.dart';
import 'package:kazzi_credit/features/cards/presentation/widgets/flip_card.dart';
import 'package:material_ui/material_ui.dart';

enum _Field { number, expiry, cvv, holder, nickname, limit }

/// Add a card with a live preview: the card updates as you type and flips
/// to its back while the security code is being entered.
///
/// Pops with the new card's id on success.
class AddCardScreen extends ConsumerStatefulWidget {
  const AddCardScreen({super.key});

  @override
  ConsumerState<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends ConsumerState<AddCardScreen> {
  final Map<_Field, TextEditingController> _c = {
    for (final f in _Field.values) f: TextEditingController(),
  };
  final Map<_Field, FocusNode> _focus = {
    for (final f in _Field.values) f: FocusNode(),
  };

  /// Fields that have lost focus once — only these show errors, so the
  /// form doesn't scold while the user is still typing.
  final _touched = <_Field>{};
  bool _submitted = false;
  bool _saving = false;
  String? _duplicateError;
  CardStyle _theme = CardStyle.midnight;
  CardKind _kind = CardKind.credit;
  PaymentCard? _saved;

  // Kept from initState: Riverpod forbids `ref` in dispose().
  late final SecureScreen _secureScreen;

  String _text(_Field f) => _c[f]!.text;
  String get _digits => CardValidation.digitsOnly(_text(_Field.number));
  CardNetwork get _network => CardNetwork.detect(_digits);

  @override
  void initState() {
    super.initState();
    // The full card number is on screen: block screenshots.
    _secureScreen = ref.read(secureScreenProvider);
    unawaited(_secureScreen.set(enabled: true));
    for (final MapEntry(key: field, value: node) in _focus.entries) {
      node.addListener(() {
        if (!node.hasFocus) _touched.add(field);
        setState(() {}); // focus drives the preview flip and errors
      });
    }
  }

  @override
  void dispose() {
    unawaited(_secureScreen.set(enabled: false));
    for (final c in _c.values) {
      c.dispose();
    }
    for (final f in _focus.values) {
      f.dispose();
    }
    super.dispose();
  }

  String? _validate(_Field f) => switch (f) {
    _Field.number => _duplicateError ?? CardValidation.number(_text(f)),
    _Field.expiry => CardValidation.expiry(_text(f), ref.read(clockProvider)()),
    _Field.cvv => CardValidation.cvv(_text(f), _network),
    _Field.holder => CardValidation.holder(_text(f)),
    _Field.nickname => CardValidation.nickname(_text(f)),
    _Field.limit =>
      _kind == CardKind.credit ? CardValidation.creditLimit(_text(f)) : null,
  };

  String? _errorFor(_Field f) {
    final error = _validate(f);
    if (error == null) return null;
    // A complete-but-wrong card number is worth flagging immediately.
    final numberComplete =
        f == _Field.number && _digits.length >= _network.numberLength;
    if (_submitted || numberComplete) return error;
    // Don't interrupt a field while it's being typed in.
    return _touched.contains(f) && !_focus[f]!.hasFocus ? error : null;
  }

  void _onChanged(_Field f) {
    if (f == _Field.number) _duplicateError = null;
    setState(() {});
    // Move on automatically once a fixed-length field is complete.
    final next = switch (f) {
      _Field.number when _validate(f) == null => _Field.expiry,
      _Field.expiry when _validate(f) == null => _Field.cvv,
      _Field.cvv
          when CardValidation.digitsOnly(_text(f)).length ==
              _network.cvvLength =>
        _Field.holder,
      _ => null,
    };
    if (next != null) _focus[next]!.requestFocus();
  }

  Future<void> _save() async {
    setState(() => _submitted = true);
    final cards = ref.read(cardsProvider.notifier);
    if (_validate(_Field.number) == null && cards.contains(_digits)) {
      _duplicateError = 'This card is already in your wallet';
    }
    final firstInvalid = _Field.values
        .where((f) => _validate(f) != null)
        .firstOrNull;
    if (firstInvalid != null) {
      unawaited(HapticFeedback.heavyImpact());
      _focus[firstInvalid]!.requestFocus();
      setState(() {});
      return;
    }

    setState(() => _saving = true);
    final (month, year) = CardValidation.parseExpiry(_text(_Field.expiry))!;
    final nickname = _text(_Field.nickname).trim();
    final limit = CardValidation.digitsOnly(_text(_Field.limit));
    final card = await cards.add(
      number: _digits,
      cvv: CardValidation.digitsOnly(_text(_Field.cvv)),
      holder: _text(_Field.holder).trim(),
      expiryMonth: month,
      expiryYear: year,
      nickname: nickname.isEmpty ? _network.label : nickname,
      themeId: _theme.id,
      kind: _kind,
      creditLimit: _kind == CardKind.credit && limit.isNotEmpty
          ? double.parse(limit)
          : 0,
    );
    if (!mounted) return;
    unawaited(HapticFeedback.heavyImpact());
    FocusScope.of(context).unfocus();
    setState(() => _saved = card);
  }

  void _showScanInfo() => showAppSheet<void>(
    context: context,
    title: 'Scan your card',
    message:
        'Camera scanning is on the way. For now, type the details — it only '
        'takes a moment, and your phone may offer to autofill them.',
    child: Builder(
      builder: (context) => AppButton(
        label: 'Enter manually',
        onPressed: () => Navigator.of(context).pop(),
      ),
    ),
  );

  /// Typed digits, with dots for the ones still to come.
  String _previewNumber() {
    final network = _network == CardNetwork.unknown
        ? CardNetwork.visa
        : _network;
    final padded = _digits.padRight(network.numberLength, '•');
    final out = <String>[];
    var i = 0;
    for (final g in network.groups) {
      out.add(padded.substring(i, i + g));
      i += g;
    }
    return out.join('  ');
  }

  @override
  Widget build(BuildContext context) {
    final saved = _saved;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(saved?.id),
        ),
        title: Text(saved == null ? 'Add card' : ''),
        actions: [
          if (saved == null)
            IconButton(
              tooltip: 'Scan card',
              icon: const Icon(Icons.photo_camera_outlined),
              onPressed: _showScanInfo,
            ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: AnimatedSwitcher(
        duration: AppMotion.of(context, AppMotion.slow),
        child: saved != null
            ? AddCardSuccess(
                key: const ValueKey('success'),
                card: saved,
                onDone: () => context.pop(saved.id),
              )
            : _buildForm(context),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final c = context.colors;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final holder = _text(_Field.holder).trim();
    final expiry = _text(_Field.expiry);
    final cvvDigits = CardValidation.digitsOnly(_text(_Field.cvv));
    final nickname = _text(_Field.nickname).trim();

    final preview = FlipCard(
      flipped: _focus[_Field.cvv]!.hasFocus,
      front: AnimatedSwitcher(
        duration: AppMotion.of(context, AppMotion.medium),
        child: CardFront(
          key: ValueKey(_theme.id),
          style: _theme,
          last4: '',
          numberText: _previewNumber(),
          network: _network,
          holder: holder.isEmpty ? 'Your name' : holder,
          expiry: expiry.isEmpty ? 'MM/YY' : expiry,
          kindLabel: _kind.label,
          nickname: nickname.isEmpty ? null : nickname,
        ),
      ),
      back: CardBack(
        style: _theme,
        last4: _digits.length >= 4
            ? _digits.substring(_digits.length - 4)
            : '••••',
        network: _network,
        holder: holder,
        expiry: expiry.isEmpty ? null : expiry,
        cvv: cvvDigits.isEmpty
            ? null
            : cvvDigits.padRight(_network.cvvLength, '•'),
      ),
    );

    return Column(
      key: const ValueKey('form'),
      children: [
        // Preview shrinks while the keyboard is up to leave room for fields.
        AnimatedContainer(
          duration: AppMotion.of(context, AppMotion.medium),
          curve: AppMotion.standard,
          padding: EdgeInsets.fromLTRB(
            keyboardOpen ? AppSpacing.xxxl * 1.6 : AppSpacing.xxl,
            AppSpacing.sm,
            keyboardOpen ? AppSpacing.xxxl * 1.6 : AppSpacing.xxl,
            AppSpacing.lg,
          ),
          child: ExcludeSemantics(child: preview),
        ),
        Expanded(
          child: AutofillGroup(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.sm,
                AppSpacing.page,
                AppSpacing.xl,
              ),
              children: [
                Text('Card details', style: context.text.titleMedium),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  key: const ValueKey('field-number'),
                  label: 'Card number',
                  hint: '1234 5678 9012 3456',
                  controller: _c[_Field.number],
                  focusNode: _focus[_Field.number],
                  errorText: _errorFor(_Field.number),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.creditCardNumber],
                  inputFormatters: [CardNumberFormatter()],
                  onChanged: (_) => _onChanged(_Field.number),
                  suffix: _NetworkBadge(
                    network: _network,
                    valid: _validate(_Field.number) == null,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppTextField(
                        key: const ValueKey('field-expiry'),
                        label: 'Expiry',
                        hint: 'MM/YY',
                        controller: _c[_Field.expiry],
                        focusNode: _focus[_Field.expiry],
                        errorText: _errorFor(_Field.expiry),
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [
                          AutofillHints.creditCardExpirationDate,
                        ],
                        inputFormatters: [ExpiryFormatter()],
                        onChanged: (_) => _onChanged(_Field.expiry),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppTextField(
                        key: const ValueKey('field-cvv'),
                        label: 'Security code',
                        hint: _network == CardNetwork.amex
                            ? '4 digits'
                            : '3 digits',
                        controller: _c[_Field.cvv],
                        focusNode: _focus[_Field.cvv],
                        errorText: _errorFor(_Field.cvv),
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [
                          AutofillHints.creditCardSecurityCode,
                        ],
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(_network.cvvLength),
                        ],
                        onChanged: (_) => _onChanged(_Field.cvv),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  key: const ValueKey('field-holder'),
                  label: 'Name on card',
                  hint: 'As printed on the card',
                  controller: _c[_Field.holder],
                  focusNode: _focus[_Field.holder],
                  errorText: _errorFor(_Field.holder),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.creditCardName],
                  onChanged: (_) => _onChanged(_Field.holder),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text('Make it yours', style: context.text.titleMedium),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  key: const ValueKey('field-nickname'),
                  label: 'Nickname (optional)',
                  hint: 'e.g. Groceries',
                  controller: _c[_Field.nickname],
                  focusNode: _focus[_Field.nickname],
                  errorText: _errorFor(_Field.nickname),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => _onChanged(_Field.nickname),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Card style', style: context.text.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                CardThemePicker(
                  selected: _theme,
                  onChanged: (g) => setState(() => _theme = g),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Card type', style: context.text.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<CardKind>(
                  showSelectedIcon: false,
                  segments: [
                    for (final k in CardKind.values)
                      ButtonSegment(value: k, label: Text(k.label)),
                  ],
                  selected: {_kind},
                  onSelectionChanged: (s) => setState(() => _kind = s.first),
                ),
                MotionSize(
                  child: _kind == CardKind.credit
                      ? Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.lg),
                          child: AppTextField(
                            key: const ValueKey('field-limit'),
                            label: 'Credit limit (optional)',
                            hint: '80,000',
                            prefixText: '₱ ',
                            helperText:
                                'Lets us show how much of it you’ve used',
                            controller: _c[_Field.limit],
                            focusNode: _focus[_Field.limit],
                            errorText: _errorFor(_Field.limit),
                            keyboardType: TextInputType.number,
                            inputFormatters: [ThousandsFormatter()],
                            onChanged: (_) => _onChanged(_Field.limit),
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 18,
                      color: c.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Your card number and security code are encrypted on '
                        'this device and only shown after Face ID or your PIN.',
                        style: context.text.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.md,
            AppSpacing.page,
            AppSpacing.md + MediaQuery.paddingOf(context).bottom,
          ),
          decoration: BoxDecoration(
            color: c.background,
            border: Border(top: BorderSide(color: c.border)),
          ),
          child: AppButton(
            label: 'Add card',
            icon: Icons.add_card_rounded,
            isLoading: _saving,
            onPressed: _save,
          ),
        ),
      ],
    );
  }
}

/// Network name while typing; a check once the number is valid.
class _NetworkBadge extends StatelessWidget {
  const _NetworkBadge({required this.network, required this.valid});

  final CardNetwork network;
  final bool valid;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.md),
      child: AnimatedSwitcher(
        duration: AppMotion.of(context, AppMotion.fast),
        child: valid
            ? Icon(
                Icons.check_circle_rounded,
                key: const ValueKey('valid'),
                color: c.success,
                semanticLabel: '${network.label} number looks good',
              )
            : network == CardNetwork.unknown
            ? const SizedBox.shrink()
            : Text(
                network.label,
                key: ValueKey(network),
                style: context.text.labelMedium,
              ),
      ),
    );
  }
}
