import 'package:flutter_test/flutter_test.dart';
import 'package:kazzi_credit/core/widgets/app_button.dart';
import 'package:kazzi_credit/features/auth/data/auth_repository.dart';
import 'package:kazzi_credit/features/cards/data/card_repository.dart';
import 'package:kazzi_credit/features/cards/data/card_vault.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/fakes.dart';

final Finder _addButton = find.widgetWithText(AppButton, 'Add card');

Finder _field(String name) => find.descendant(
  of: find.byKey(ValueKey('field-$name')),
  matching: find.byType(TextField),
);

Future<InMemoryKeyValueStore> _openAddCard(WidgetTester tester) async {
  final store = InMemoryKeyValueStore();
  await testRepository(store).setPin('482915');
  await pumpKazziApp(
    tester,
    store: store,
    status: const AuthStatus(
      onboarded: true,
      hasPin: true,
      biometricsEnabled: false,
    ),
  );
  await enterPin(tester, '482915');

  await tester.tap(find.text('+ Add card'));
  await settle(tester);
  expect(find.text('Card details'), findsOneWidget);
  return store;
}

Future<void> _fill(WidgetTester tester, Map<String, String> values) async {
  for (final MapEntry(:key, :value) in values.entries) {
    await tester.enterText(_field(key), value);
    await tester.pump();
  }
  await settle(tester);
}

void main() {
  testWidgets('adds a card, celebrates, and shows it in the wallet', (
    tester,
  ) async {
    final store = await _openAddCard(tester);

    await _fill(tester, {
      'number': '4111111111111111',
      'expiry': '0830',
      'cvv': '123',
      'holder': 'Sam Rivera',
      'nickname': 'Weekend',
    });
    expect(
      find.descendant(
        of: _field('number'),
        matching: find.text('4111 1111 1111 1111'),
      ),
      findsOneWidget,
    );

    await tester.ensureVisible(_addButton);
    await tester.tap(_addButton);
    await settle(tester);
    expect(find.text('Card added'), findsOneWidget);

    await tester.tap(find.text('Go to wallet'));
    await settle(tester);
    expect(
      find.bySemanticsLabel(RegExp('Weekend credit card ending in 1111')),
      findsOneWidget,
    );

    // Persisted: metadata in the card list, full number only in the vault.
    final saved = (await CardRepository(store).load())!;
    final card = saved.singleWhere((c) => c.last4 == '1111');
    expect(card.nickname, 'Weekend');
    expect((await CardVault(store).read(card.id))!.number, '4111111111111111');
  });

  testWidgets('flags a mistyped number as soon as it is complete', (
    tester,
  ) async {
    await _openAddCard(tester);
    await _fill(tester, {'number': '4111111111111112'});
    expect(find.textContaining('Check for typos'), findsOneWidget);
  });

  testWidgets('refuses a card that is already in the wallet', (tester) async {
    await _openAddCard(tester);
    await _fill(tester, {
      'number': '4539140000054821', // the demo "Everyday" card
      'expiry': '0929',
      'cvv': '417',
      'holder': 'Alex Morgan',
    });
    await tester.ensureVisible(_addButton);
    await tester.tap(_addButton);
    await settle(tester);

    expect(find.text('This card is already in your wallet'), findsOneWidget);
    expect(find.text('Card added'), findsNothing);
  });

  testWidgets('shows every missing field on submit', (tester) async {
    await _openAddCard(tester);
    await tester.ensureVisible(_addButton);
    await tester.tap(_addButton);
    await settle(tester);

    expect(find.text('Enter the card number'), findsOneWidget);
    expect(find.text('Enter the expiry date'), findsOneWidget);
    expect(find.text('Enter the security code'), findsOneWidget);
  });
}
