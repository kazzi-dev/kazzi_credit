import 'package:flutter_test/flutter_test.dart';
import 'package:kazzi_credit/features/auth/data/auth_repository.dart';

import '../../helpers/fakes.dart';

void main() {
  late InMemoryKeyValueStore store;
  late DateTime now;
  late AuthRepository repo;

  setUp(() {
    store = InMemoryKeyValueStore();
    now = DateTime(2026, 10, 17, 12);
    repo = testRepository(store, clock: () => now);
  });

  test('stores a hash, never the PIN itself', () async {
    await repo.setPin('482915');

    expect(store.values.values, isNot(contains('482915')));
    expect((await repo.loadStatus()).hasPin, isTrue);
  });

  test('accepts the correct PIN', () async {
    await repo.setPin('482915');
    expect(await repo.verifyPin('482915'), isA<PinCorrect>());
  });

  test('counts down attempts, then locks out', () async {
    await repo.setPin('482915');

    for (var left = 4; left >= 1; left--) {
      final r = await repo.verifyPin('000001');
      expect(r, isA<PinWrong>().having((w) => w.attemptsLeft, 'left', left));
    }
    expect(await repo.verifyPin('000001'), isA<PinLockedOut>());

    // Even the right PIN is refused during the lockout.
    expect(await repo.verifyPin('482915'), isA<PinLockedOut>());

    now = now.add(AuthRepository.lockoutDuration);
    expect(await repo.verifyPin('482915'), isA<PinCorrect>());
  });

  test('a correct PIN resets the failure counter', () async {
    await repo.setPin('482915');
    await repo.verifyPin('000001');
    await repo.verifyPin('000001');
    await repo.verifyPin('482915');

    final r = await repo.verifyPin('000001');
    expect(r, isA<PinWrong>().having((w) => w.attemptsLeft, 'left', 4));
  });

  test('reset wipes everything', () async {
    await repo.setPin('482915');
    await repo.completeOnboarding();
    await repo.reset();

    final status = await repo.loadStatus();
    expect(status.onboarded, isFalse);
    expect(status.hasPin, isFalse);
  });
}
