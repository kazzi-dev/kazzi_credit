import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kazzi_credit/core/theme/app_tokens.dart';
import 'package:kazzi_credit/core/theme/theme_extensions.dart';
import 'package:kazzi_credit/core/widgets/app_button.dart';
import 'package:kazzi_credit/core/widgets/app_sheet.dart';
import 'package:kazzi_credit/core/widgets/app_text_field.dart';
import 'package:kazzi_credit/core/widgets/app_toast.dart';
import 'package:kazzi_credit/features/transactions/application/transactions_controller.dart';
import 'package:kazzi_credit/features/transactions/domain/card_transaction.dart';
import 'package:material_ui/material_ui.dart';

/// Recategorize, with undo — it's reversible, so no confirmation step.
Future<void> changeCategory(
  BuildContext context,
  WidgetRef ref,
  CardTransaction tx,
) async {
  final picked = await showAppSheet<TxCategory>(
    context: context,
    title: 'Category',
    message: tx.merchant,
    child: _CategoryGrid(selected: tx.category),
  );
  if (picked == null || picked == tx.category || !context.mounted) return;

  final edits = ref.read(txEditsProvider.notifier);
  final previous = ref.read(txEditsProvider)[tx.id];
  edits.edit(tx.id, TxEdit(category: picked));
  showAppToast(
    context,
    'Moved to ${picked.label}',
    icon: picked.icon,
    onUndo: () => edits.restore(tx.id, previous),
  );
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.selected});

  final TxCategory selected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 0.82,
      children: [
        for (final cat in TxCategory.values)
          Semantics(
            button: true,
            selected: cat == selected,
            label: cat.label,
            excludeSemantics: true,
            child: InkWell(
              borderRadius: AppRadii.lgAll,
              onTap: () {
                HapticFeedback.selectionClick().ignore();
                Navigator.of(context).pop(cat);
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: AppMotion.of(context, AppMotion.fast),
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: cat == selected
                          ? cat.color
                          : cat.color.withValues(alpha: 0.14),
                      borderRadius: AppRadii.lgAll,
                    ),
                    child: Icon(
                      cat.icon,
                      color: cat == selected ? Colors.white : cat.color,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    cat.label,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: context.text.labelSmall?.copyWith(
                      color: c.textPrimary,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

Future<void> editNote(
  BuildContext context,
  WidgetRef ref,
  CardTransaction tx,
) async {
  final result = await showAppSheet<String>(
    context: context,
    title: tx.note == null ? 'Add a note' : 'Edit note',
    message: tx.merchant,
    child: _NoteEditor(initial: tx.note ?? ''),
  );
  if (result == null || !context.mounted) return;
  ref.read(txEditsProvider.notifier).edit(tx.id, TxEdit(note: result));
  showAppToast(
    context,
    result.isEmpty ? 'Note removed' : 'Note saved',
    tone: ToastTone.success,
  );
}

class _NoteEditor extends StatefulWidget {
  const _NoteEditor({required this.initial});

  final String initial;

  @override
  State<_NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<_NoteEditor> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTextField(
          key: const ValueKey('note-field'),
          controller: _controller,
          hint: 'e.g. Split with Jamie',
          autofocus: true,
          maxLines: 4,
          maxLength: 140,
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'Save note',
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
        ),
        if (widget.initial.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Remove note',
            variant: AppButtonVariant.ghost,
            onPressed: () => Navigator.of(context).pop(''),
          ),
        ],
      ],
    );
  }
}

const List<(IconData, String)> _disputeReasons = [
  (Icons.person_off_outlined, "I don't recognize this charge"),
  (Icons.price_change_outlined, 'The amount is wrong'),
  (Icons.content_copy_rounded, 'I was charged twice'),
  (Icons.local_shipping_outlined, "I didn't receive what I paid for"),
];

/// Reporting is outward-facing, so it gets an explicit submit step.
Future<void> reportProblem(
  BuildContext context,
  WidgetRef ref,
  CardTransaction tx,
) async {
  final reason = await showAppSheet<String>(
    context: context,
    title: 'Report a problem',
    message:
        "Tell us what's wrong and we'll look into it. Your card stays "
        'active while we review.',
    child: const _ReasonPicker(),
  );
  if (reason == null || !context.mounted) return;
  ref.read(txEditsProvider.notifier).edit(tx.id, TxEdit(dispute: reason));
  HapticFeedback.mediumImpact().ignore();
  showAppToast(
    context,
    "Report sent. We'll update you within 10 days.",
    tone: ToastTone.success,
  );
}

class _ReasonPicker extends StatefulWidget {
  const _ReasonPicker();

  @override
  State<_ReasonPicker> createState() => _ReasonPickerState();
}

class _ReasonPickerState extends State<_ReasonPicker> {
  String? _reason;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        for (final (icon, label) in _disputeReasons) ...[
          Semantics(
            selected: _reason == label,
            inMutuallyExclusiveGroup: true,
            child: Material(
              color: _reason == label ? c.primarySoft : c.surfaceHigh,
              borderRadius: AppRadii.lgAll,
              child: InkWell(
                borderRadius: AppRadii.lgAll,
                onTap: () => setState(() => _reason = label),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      Icon(icon, color: c.textSecondary),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(label, style: context.text.titleSmall),
                      ),
                      Icon(
                        _reason == label
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: _reason == label ? c.primary : c.textTertiary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'Send report',
          onPressed: _reason == null
              ? null
              : () => Navigator.of(context).pop(_reason),
        ),
      ],
    );
  }
}
