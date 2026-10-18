import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:kazzi_credit/app.dart';
import 'package:kazzi_credit/core/widgets/app_button.dart';
import 'package:kazzi_credit/features/auth/data/auth_repository.dart';
import 'package:kazzi_credit/features/insights/application/insights_controller.dart';
import 'package:kazzi_credit/features/transactions/domain/card_transaction.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/fakes.dart';

Future<ProviderContainer> _openInsights(WidgetTester tester) async {
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
  await tester.tap(find.text('Insights'));
  await settle(tester);
  return ProviderScope.containerOf(tester.element(find.byType(KazziApp)));
}

Finder get _list => find.byType(Scrollable).last;

void main() {
  testWidgets('shows summary, categories, weeks, merchants and budgets', (
    tester,
  ) async {
    final container = await _openInsights(tester);
    final i = container.read(monthInsightsProvider);

    expect(
      find.text('Spent in ${DateFormat.MMMM().format(i.month)}'),
      findsOneWidget,
    );
    expect(find.text('Where it went'), findsOneWidget);
    // The largest category is selected by default and named in the center.
    final top = i.byCategory.first;
    expect(find.textContaining('% · ${top.category.label}'), findsOneWidget);

    for (final title in ['Weekly spending', 'Top merchants', 'Budgets']) {
      await tester.scrollUntilVisible(find.text(title), 300, scrollable: _list);
      expect(find.text(title), findsOneWidget);
    }
    await settle(tester);
  });

  testWidgets('tapping a legend row selects that category', (tester) async {
    final container = await _openInsights(tester);
    final second = container.read(monthInsightsProvider).byCategory[1];

    await tester.scrollUntilVisible(
      find.text(second.category.label).first,
      200,
      scrollable: _list,
    );
    await tester.ensureVisible(find.text(second.category.label).first);
    await settle(tester);
    await tester.tap(find.text(second.category.label).first);
    await settle(tester);

    expect(find.textContaining('% · ${second.category.label}'), findsOneWidget);
  });

  testWidgets('month switcher rescopes everything', (tester) async {
    final container = await _openInsights(tester);
    final now = DateTime.now();
    final prev = DateTime(now.year, now.month - 1);

    expect(find.byTooltip('Next month'), findsOneWidget);
    await tester.tap(find.byTooltip('Previous month'));
    await settle(tester);

    expect(find.text(DateFormat.yMMMM().format(prev)), findsOneWidget);
    expect(container.read(monthInsightsProvider).month, prev);
    expect(container.read(monthInsightsProvider).comparesToSamePoint, isFalse);
  });

  testWidgets('weekly chart has a table view', (tester) async {
    await _openInsights(tester);
    await tester.scrollUntilVisible(
      find.byTooltip('Show as table'),
      300,
      scrollable: _list,
    );
    await tester.tap(find.byTooltip('Show as table'));
    await settle(tester);
    expect(find.textContaining('(so far)'), findsOneWidget);
  });

  testWidgets('add a budget for a new category', (tester) async {
    final container = await _openInsights(tester);
    expect(
      container.read(budgetsProvider).containsKey(TxCategory.travel),
      isFalse,
    );

    await tester.scrollUntilVisible(find.text('Add'), 300, scrollable: _list);
    await tester.tap(find.text('Add'));
    await settle(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Travel'));
    await settle(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, '₱10,000'));
    await settle(tester);
    await tester.tap(find.widgetWithText(AppButton, 'Set budget'));
    await settle(tester);

    expect(container.read(budgetsProvider)[TxCategory.travel], 10000);
    expect(find.text('Travel budget set to ₱10,000.00'), findsOneWidget);
  });
}
