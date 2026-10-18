import 'package:intl/intl.dart';
import 'package:kazzi_credit/core/theme/app_tokens.dart';
import 'package:kazzi_credit/core/theme/theme_extensions.dart';
import 'package:kazzi_credit/features/transactions/domain/card_transaction.dart';
import 'package:material_ui/material_ui.dart';

enum _StepState { done, current, upcoming }

/// Vertical timeline of where a transaction is: authorized → posted, plus
/// a dispute step once one is opened.
class StatusTimeline extends StatelessWidget {
  const StatusTimeline({required this.tx, required this.now, super.key});

  final CardTransaction tx;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final f = DateFormat('MMM d · h:mm a');
    final day = DateFormat('MMM d');
    final posted = tx.date.add(const Duration(days: 1));
    final steps = <(String, String, _StepState)>[
      (
        tx.isRefund ? 'Refund issued' : 'Authorized',
        f.format(tx.date),
        _StepState.done,
      ),
      if (tx.isPending) ...[
        ('Processing', 'Usually takes 1–2 days', _StepState.current),
        (
          'Posted',
          'Expected by ${day.format(tx.date.add(const Duration(days: 2)))}',
          _StepState.upcoming,
        ),
      ] else
        (
          'Posted',
          day.format(posted.isAfter(now) ? now : posted),
          _StepState.done,
        ),
      if (tx.dispute != null)
        ('Under review', "We'll update you within 10 days", _StepState.current),
    ];

    return Column(
      children: [
        for (final (i, (title, subtitle, state)) in steps.indexed)
          _StepRow(
            title: title,
            subtitle: subtitle,
            state: state,
            isLast: i == steps.length - 1,
          ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.title,
    required this.subtitle,
    required this.state,
    required this.isLast,
  });

  final String title;
  final String subtitle;
  final _StepState state;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = switch (state) {
      _StepState.done => c.success,
      _StepState.current => c.primary,
      _StepState.upcoming => c.border,
    };
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                const SizedBox(height: 2),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: state == _StepState.done ? color : c.surface,
                    border: Border.all(color: color, width: 3),
                  ),
                  child: state == _StepState.done
                      ? const Icon(Icons.check, size: 9, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: state == _StepState.done ? color : c.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.text.titleSmall?.copyWith(
                      color: state == _StepState.upcoming
                          ? c.textTertiary
                          : c.textPrimary,
                    ),
                  ),
                  Text(subtitle, style: context.text.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
