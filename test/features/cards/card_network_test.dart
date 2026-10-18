import 'package:flutter_test/flutter_test.dart';
import 'package:kazzi_credit/features/cards/data/mock_cards.dart';
import 'package:kazzi_credit/features/cards/domain/card_network.dart';

void main() {
  test('detects networks from the leading digits', () {
    expect(CardNetwork.detect('4539 1400'), CardNetwork.visa);
    expect(CardNetwork.detect('5522'), CardNetwork.mastercard);
    expect(CardNetwork.detect('2221 0000'), CardNetwork.mastercard);
    expect(CardNetwork.detect('3782'), CardNetwork.amex);
    expect(CardNetwork.detect('6011'), CardNetwork.discover);
    expect(CardNetwork.detect('9999'), CardNetwork.unknown);
  });

  test('groups digits per network', () {
    expect(CardNetwork.visa.format('4539140000054821'), '4539 1400 0005 4821');
    expect(CardNetwork.amex.format('378282000013456'), '3782 820000 13456');
    expect(CardNetwork.visa.format('45391'), '4539 1');
  });

  test('Luhn check', () {
    for (final s in mockCardSecrets.values) {
      expect(passesLuhn(s.number), isTrue, reason: s.number);
    }
    expect(passesLuhn('4539140000054822'), isFalse);
  });
}
