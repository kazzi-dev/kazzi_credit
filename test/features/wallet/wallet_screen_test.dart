import 'package:flutter_test/flutter_test.dart';
import 'package:kazzi_credit/features/auth/data/auth_repository.dart';

import '../../helpers/fakes.dart';

const _onboarded = AuthStatus(
  onboarded: true,
  hasPin: true,
  biometricsEnabled: false,
);

Future<void> _openWallet(WidgetTester tester) async {
  final store = InMemoryKeyValueStore();
  await testRepository(store).setPin('482915');
  await pumpKazziApp(tester, store: store, status: _onboarded);
  await enterPin(tester, '482915');
}

void main() {
  testWidgets('shows the first card, its balance and recent activity', (
    tester,
  ) async {
    await _openWallet(tester);

    expect(
      find.bySemanticsLabel(RegExp('Everyday credit card ending in 4821')),
      findsOneWidget,
    );
    expect(find.text('Current balance'), findsOneWidget);
    expect(find.textContaining('Due in 6 days'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Recent activity'), 200);
    expect(find.text('Recent activity'), findsOneWidget);
    await settle(tester);
  });

  testWidgets('freeze is instant and can be undone', (tester) async {
    await _openWallet(tester);

    await tester.tap(find.bySemanticsLabel('Freeze'));
    await settle(tester);
    expect(
      find.bySemanticsLabel(RegExp('ending in 4821, frozen')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Unfreeze'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect(
      find.bySemanticsLabel(RegExp('ending in 4821, frozen')),
      findsNothing,
    );
  });

  testWidgets('card details need the PIN and hide again', (tester) async {
    await _openWallet(tester);

    await tester.tap(find.bySemanticsLabel('Details'));
    await settle(tester);
    expect(find.text('Enter your PIN'), findsOneWidget);

    await enterPin(tester, '482915');
    expect(
      find.bySemanticsLabel(RegExp('Card number 4539 1400 0005 4821')),
      findsOneWidget,
    );

    await tester.tap(find.bySemanticsLabel('Hide'));
    await settle(tester);
    expect(find.bySemanticsLabel(RegExp('Card number')), findsNothing);
  });

  testWidgets('paying the statement balance shows a confirmation', (
    tester,
  ) async {
    await _openWallet(tester);

    await tester.tap(find.bySemanticsLabel('Pay'));
    await settle(tester);
    await tester.tap(find.text('Pay ₱18,920.40'));
    await tester.pump(const Duration(milliseconds: 1300));
    await settle(tester);

    expect(find.text('Payment of ₱18,920.40 sent'), findsOneWidget);
  });
}
