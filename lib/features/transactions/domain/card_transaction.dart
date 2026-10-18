import 'package:material_ui/material_ui.dart';

enum TxCategory {
  food('Food & drink', Icons.restaurant_rounded, Color(0xFFF97316)),
  shopping('Shopping', Icons.shopping_bag_rounded, Color(0xFFEC4899)),
  transport('Transport', Icons.directions_car_rounded, Color(0xFF3B82F6)),
  bills('Bills', Icons.receipt_long_rounded, Color(0xFF8B5CF6)),
  entertainment('Entertainment', Icons.movie_rounded, Color(0xFFEAB308)),
  travel('Travel', Icons.flight_rounded, Color(0xFF06B6D4)),
  health('Health', Icons.favorite_rounded, Color(0xFFEF4444)),
  refund('Refunds', Icons.undo_rounded, Color(0xFF22C55E));

  TxCategory(this.label, this.icon, this.color);

  final String label;
  final IconData icon;

  /// Mid-tone hue used as icon color over a 14% tint of itself, which
  /// reads in both light and dark mode.
  final Color color;
}

enum TxStatus { pending, completed }

@immutable
class CardTransaction {
  const CardTransaction({
    required this.id,
    required this.cardId,
    required this.merchant,
    required this.category,
    required this.amount,
    required this.date,
    this.status = TxStatus.completed,
    this.note,
    this.dispute,
  });

  factory CardTransaction.fromJson(Map<String, dynamic> j) => CardTransaction(
    id: j['id'] as String,
    cardId: j['cardId'] as String,
    merchant: j['merchant'] as String,
    category: TxCategory.values.byName(j['category'] as String),
    amount: (j['amount'] as num).toDouble(),
    date: DateTime.parse(j['date'] as String),
    status: TxStatus.values.byName(j['status'] as String),
  );

  final String id;
  final String cardId;
  final String merchant;
  final TxCategory category;

  /// Negative for purchases, positive for refunds and credits.
  final double amount;
  final DateTime date;
  final TxStatus status;
  final String? note;

  /// Reason given when the user reported a problem with this charge.
  final String? dispute;

  bool get isPending => status == TxStatus.pending;
  bool get isRefund => amount > 0;

  /// Bank-provided fields only; user edits are stored separately.
  Map<String, dynamic> toJson() => {
    'id': id,
    'cardId': cardId,
    'merchant': merchant,
    'category': category.name,
    'amount': amount,
    'date': date.toIso8601String(),
    'status': status.name,
  };

  CardTransaction applying(TxEdit? edit) => edit == null
      ? this
      : CardTransaction(
          id: id,
          cardId: cardId,
          merchant: merchant,
          category: edit.category ?? category,
          amount: amount,
          date: date,
          status: status,
          note: switch (edit.note) {
            null => note,
            '' => null,
            final n => n,
          },
          dispute: edit.dispute ?? dispute,
        );
}

/// What the user changed about a transaction. Stored separately from the
/// (bank-provided) transaction itself.
@immutable
class TxEdit {
  const TxEdit({this.category, this.note, this.dispute});

  factory TxEdit.fromJson(Map<String, dynamic> j) => TxEdit(
    category: j['category'] == null
        ? null
        : TxCategory.values.byName(j['category'] as String),
    note: j['note'] as String?,
    dispute: j['dispute'] as String?,
  );

  final TxCategory? category;

  /// Empty string means "note removed".
  final String? note;
  final String? dispute;

  TxEdit merge(TxEdit other) => TxEdit(
    category: other.category ?? category,
    note: other.note ?? note,
    dispute: other.dispute ?? dispute,
  );

  Map<String, dynamic> toJson() => {
    if (category != null) 'category': category!.name,
    if (note != null) 'note': note,
    if (dispute != null) 'dispute': dispute,
  };
}
