import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazzi_credit/app.dart';
import 'package:kazzi_credit/core/widgets/app_button.dart';
import 'package:kazzi_credit/features/auth/data/auth_repository.dart';
import 'package:kazzi_credit/features/transactions/application/transactions_controller.dart';
import 'package:kazzi_credit/features/transactions/domain/card_transaction.dart';
import 'package:kazzi_credit/features/transactions/domain/tx_query.dart';
import 'package:kazzi_credit/features/transactions/presentation/widgets/transaction_tile.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/fakes.dart';

Future<ProviderContainer> _openActivity(WidgetTester tester) async {
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
  await tester.tap(find.text('Activity'));
  await settle(tester);
  return ProviderScope.containerOf(tester.element(find.byType(KazziApp)));
}

Iterable<CardTransaction> _visibleTxs(WidgetTester tester) => tester
    .widgetList<TransactionTile>(find.byType(TransactionTile))
    .map((t) => t.tx);

void main() {
  testWidgets('loads grouped history with a monthly summary', (tester) async {
    await _openActivity(tester);

    expect(find.textContaining('Spent in'), findsOneWidget);
    expect(find.byType(TransactionTile), findsWidgets);
    final first = _visibleTxs(tester).first;
    expect(find.text(dayLabel(first.date, DateTime.now())), findsWidgets);
  });

  testWidgets('search narrows the list', (tester) async {
    await _openActivity(tester);

    await tester.enterText(find.byType(TextField).first, 'netflix');
    await tester.pump(const Duration(milliseconds: 300));
    await settle(tester);

    final txs = _visibleTxs(tester).toList();
    expect(txs, isNotEmpty);
    expect(txs.every((t) => t.merchant == 'Netflix'), isTrue);
    // The monthly summary hides while searching.
    expect(find.textContaining('Spent in'), findsNothing);
  });

  testWidgets('category filter shows a live count, then applies', (
    tester,
  ) async {
    final container = await _openActivity(tester);
    final travelCount = container
        .read(transactionsProvider)
        .where((t) => t.category == TxCategory.travel)
        .length;

    await tester.tap(find.bySemanticsLabel('Category filter'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilterChip, 'Travel'));
    await settle(tester);
    await tester.tap(
      find.widgetWithText(AppButton, 'Show $travelCount transactions'),
    );
    await settle(tester);

    expect(find.bySemanticsLabel('Travel filter'), findsOneWidget);
    expect(
      _visibleTxs(tester).every((t) => t.category == TxCategory.travel),
      isTrue,
    );
  });

  testWidgets('swipe to recategorize, with undo', (tester) async {
    final container = await _openActivity(tester);
    final first = _visibleTxs(tester).first;
    final target = first.category == TxCategory.health
        ? TxCategory.bills
        : TxCategory.health;

    await tester.drag(
      find.byType(TransactionTile).first,
      const Offset(-200, 0),
    );
    await settle(tester);
    await tester.tap(find.text('Categorize').first);
    await settle(tester);
    await tester.tap(find.bySemanticsLabel(target.label).last);
    await settle(tester);

    expect(find.text('Moved to ${target.label}'), findsOneWidget);
    expect(container.read(transactionByIdProvider(first.id))!.category, target);

    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect(
      container.read(transactionByIdProvider(first.id))!.category,
      first.category,
    );
  });

  testWidgets('detail: add a note and report a problem', (tester) async {
    final container = await _openActivity(tester);
    final first = _visibleTxs(tester).first;

    await tester.tap(find.byType(TransactionTile).first);
    await settle(tester);
    expect(find.text('Paid with'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Add a note'), 200);
    await tester.tap(find.text('Add a note'));
    await settle(tester);
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('note-field')),
        matching: find.byType(TextField),
      ),
      'Team lunch',
    );
    await tester.tap(find.text('Save note'));
    await settle(tester);
    expect(
      container.read(transactionByIdProvider(first.id))!.note,
      'Team lunch',
    );

    await tester.scrollUntilVisible(find.text('Report a problem'), 200);
    await tester.tap(find.text('Report a problem'));
    await settle(tester);
    await tester.tap(find.text('I was charged twice'));
    await settle(tester);
    await tester.tap(find.text('Send report'));
    await settle(tester);

    expect(
      container.read(transactionByIdProvider(first.id))!.dispute,
      'I was charged twice',
    );
    await tester.scrollUntilVisible(
      find.text("We're reviewing this charge"),
      -200,
    );
    expect(find.text("We're reviewing this charge"), findsOneWidget);
  });
}
