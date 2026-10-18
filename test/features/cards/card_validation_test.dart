import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazzi_credit/features/cards/data/card_repository.dart';
import 'package:kazzi_credit/features/cards/data/mock_cards.dart';
import 'package:kazzi_credit/features/cards/domain/card_network.dart';
import 'package:kazzi_credit/features/cards/domain/card_validation.dart';
import 'package:kazzi_credit/features/cards/presentation/card_input_formatters.dart';

import '../../helpers/fakes.dart';

TextEditingValue _type(TextInputFormatter f, String old, String next) =>
    f.formatEditUpdate(
      TextEditingValue(
        text: old,
        selection: TextSelection.collapsed(offset: old.length),
      ),
      TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      ),
    );

void main() {
  final now = DateTime(2026, 10, 18);

  group('card number', () {
    test('accepts a valid number', () {
      expect(CardValidation.number('4111 1111 1111 1111'), isNull);
    });
    test('explains what is wrong', () {
      expect(CardValidation.number(''), 'Enter the card number');
      expect(CardValidation.number('4111 11'), 'Card number is incomplete');
      expect(CardValidation.number('4111 1111 1111 1112'), contains('typos'));
      expect(CardValidation.number('9999 9999'), contains('We support'));
    });
  });

  group('expiry', () {
    test('valid through the end of the expiry month', () {
      expect(CardValidation.expiry('10/26', now), isNull);
      expect(CardValidation.expiry('09/26', now), 'This card has expired');
    });
    test('rejects bad months and formats', () {
      expect(CardValidation.expiry('13/29', now), contains('01 and 12'));
      expect(CardValidation.expiry('1/2', now), 'Use the MM/YY format');
    });
  });

  test('CVV length depends on the network', () {
    expect(CardValidation.cvv('123', CardNetwork.visa), isNull);
    expect(CardValidation.cvv('123', CardNetwork.amex), 'Needs 4 digits');
  });

  test('holder name', () {
    expect(CardValidation.holder('Alex Morgan'), isNull);
    expect(CardValidation.holder(' '), 'Enter the name on the card');
    expect(CardValidation.holder('R2D2'), contains('numbers'));
  });

  group('formatters', () {
    test('card number groups per network and caps length', () {
      final f = CardNumberFormatter();
      expect(_type(f, '', '4111111111111111999').text, '4111 1111 1111 1111');
      expect(_type(f, '', '378282000013456').text, '3782 820000 13456');
    });

    test('expiry adds the slash and pads single-digit months', () {
      final f = ExpiryFormatter();
      expect(_type(f, '', '4').text, '04/');
      expect(_type(f, '1', '12').text, '12/');
      expect(_type(f, '12/', '12/2').text, '12/2');
      // Backspacing over the slash removes it instead of re-adding it.
      expect(_type(f, '12/', '12').text, '12');
    });

    test('thousands separators', () {
      expect(_type(ThousandsFormatter(), '', '12000').text, '12,000');
    });
  });

  test('card metadata round-trips through storage without secrets', () async {
    final store = InMemoryKeyValueStore();
    final repo = CardRepository(store);
    final cards = mockCards(now);

    await repo.save(cards);
    final loaded = await repo.load();

    expect(loaded!.map((c) => c.id), cards.map((c) => c.id));
    expect(loaded.first.dueDate, cards.first.dueDate);
    expect(store.values.values.join(), isNot(contains('4539140000054821')));
  });
}
