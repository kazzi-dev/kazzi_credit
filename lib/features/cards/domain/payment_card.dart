import 'package:flutter/foundation.dart';
import 'package:kazzi_credit/core/theme/card_styles.dart';
import 'package:kazzi_credit/features/cards/domain/card_network.dart';

enum CardKind {
  credit('Credit'),
  debit('Debit');

  CardKind(this.label);
  final String label;
}

/// What the app keeps about a card in normal storage. The full number and
/// CVV live separately in [CardSecrets], in the secure vault.
@immutable
class PaymentCard {
  const PaymentCard({
    required this.id,
    required this.nickname,
    required this.holder,
    required this.last4,
    required this.network,
    required this.expiryMonth,
    required this.expiryYear,
    required this.themeId,
    required this.creditLimit,
    required this.balance,
    required this.statementBalance,
    required this.minimumDue,
    required this.dueDate,
    this.kind = CardKind.credit,
    this.frozen = false,
  });

  factory PaymentCard.fromJson(Map<String, dynamic> j) => PaymentCard(
    id: j['id'] as String,
    nickname: j['nickname'] as String,
    holder: j['holder'] as String,
    last4: j['last4'] as String,
    network: CardNetwork.values.byName(j['network'] as String),
    expiryMonth: j['expiryMonth'] as int,
    expiryYear: j['expiryYear'] as int,
    themeId: j['themeId'] as String,
    kind: CardKind.values.byName(j['kind'] as String),
    creditLimit: (j['creditLimit'] as num).toDouble(),
    balance: (j['balance'] as num).toDouble(),
    statementBalance: (j['statementBalance'] as num).toDouble(),
    minimumDue: (j['minimumDue'] as num).toDouble(),
    dueDate: DateTime.parse(j['dueDate'] as String),
    frozen: j['frozen'] as bool? ?? false,
  );

  final String id;
  final String nickname;
  final String holder;
  final String last4;
  final CardNetwork network;
  final int expiryMonth;

  /// Four-digit year.
  final int expiryYear;
  final String themeId;
  final CardKind kind;
  final double creditLimit;

  /// Current amount owed.
  final double balance;
  final double statementBalance;
  final double minimumDue;
  final DateTime dueDate;
  final bool frozen;

  CardStyle get style => CardStyle.byId(themeId);

  String get expiry =>
      '${expiryMonth.toString().padLeft(2, '0')}/'
      '${(expiryYear % 100).toString().padLeft(2, '0')}';

  double get available => (creditLimit - balance).clamp(0, creditLimit);

  /// Share of the limit in use, 0..1.
  double get utilization =>
      creditLimit <= 0 ? 0 : (balance / creditLimit).clamp(0, 1);

  int daysUntilDue(DateTime now) =>
      _dateOnly(dueDate).difference(_dateOnly(now)).inDays;

  PaymentCard copyWith({
    String? holder,
    bool? frozen,
    String? nickname,
    String? themeId,
    double? balance,
    double? statementBalance,
    double? minimumDue,
  }) => PaymentCard(
    id: id,
    nickname: nickname ?? this.nickname,
    holder: holder ?? this.holder,
    last4: last4,
    network: network,
    expiryMonth: expiryMonth,
    expiryYear: expiryYear,
    themeId: themeId ?? this.themeId,
    kind: kind,
    creditLimit: creditLimit,
    balance: balance ?? this.balance,
    statementBalance: statementBalance ?? this.statementBalance,
    minimumDue: minimumDue ?? this.minimumDue,
    dueDate: dueDate,
    frozen: frozen ?? this.frozen,
  );

  /// Never contains the full number or CVV.
  Map<String, dynamic> toJson() => {
    'id': id,
    'nickname': nickname,
    'holder': holder,
    'last4': last4,
    'network': network.name,
    'expiryMonth': expiryMonth,
    'expiryYear': expiryYear,
    'themeId': themeId,
    'kind': kind.name,
    'creditLimit': creditLimit,
    'balance': balance,
    'statementBalance': statementBalance,
    'minimumDue': minimumDue,
    'dueDate': dueDate.toIso8601String(),
    'frozen': frozen,
  };

  /// True when the limit is unknown or the card is debit.
  bool get tracksCredit => kind == CardKind.credit && creditLimit > 0;
}

@immutable
class CardSecrets {
  const CardSecrets({required this.number, required this.cvv});

  factory CardSecrets.fromJson(Map<String, dynamic> json) =>
      CardSecrets(number: json['number'] as String, cvv: json['cvv'] as String);

  final String number;
  final String cvv;

  Map<String, dynamic> toJson() => {'number': number, 'cvv': cvv};
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
