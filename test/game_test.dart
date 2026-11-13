import 'package:flutter_test/flutter_test.dart';
import 'package:one_million_steps/game/config.dart';
import 'package:one_million_steps/game/economy.dart';
import 'package:one_million_steps/game/game_controller.dart';
import 'package:one_million_steps/game/game_store.dart';
import 'package:one_million_steps/steps/step_source.dart';

void main() {
  group('economy', () {
    test('shoes cost 100 then 60% more per level', () {
      expect(shoeCost(0), 100);
      expect(shoeCost(1), closeTo(160, 1e-9));
      expect(shoeCost(2), closeTo(256, 1e-9));
    });

    test('generators cost 15% more per purchase', () {
      final g = generatorDefs.first;
      expect(generatorCost(g, 1), closeTo(g.baseCost * 1.15, 1e-9));
    });

    test('coins per step = 1 + shoe level, times bonuses', () {
      expect(coinsPerStep(0), 1);
      expect(coinsPerStep(4, multiplier: 2), 10);
    });

    test('daily cap is 50,000', () {
      expect(countableDailySteps(60000), 50000);
      expect(countableDailySteps(7500), 7500);
    });

    test('offline time is capped at 8 hours and never negative', () {
      final t = DateTime(2026, 1, 1);
      expect(cappedElapsed(t, t.add(const Duration(hours: 20)), Tuning.offlineCap),
          const Duration(hours: 8));
      expect(cappedElapsed(t, t.subtract(const Duration(hours: 1)), Tuning.offlineCap),
          Duration.zero);
    });

    test('milestone bonuses at 25k, 75k, 125k ...', () {
      expect(milestoneBonusesReached(24999), 0);
      expect(milestoneBonusesReached(25000), 1);
      expect(milestoneBonusesReached(74999), 1);
      expect(milestoneBonusesReached(75000), 2);
    });
  });

  group('controller', () {
    late DateTime now;
    late FakeStepSource steps;
    late MemoryGameStore store;
    late GameController game;

    setUp(() async {
      now = DateTime(2026, 11, 12, 9);
      steps = FakeStepSource(clock: () => now);
      store = MemoryGameStore();
      game = GameController(store: store, steps: steps, clock: () => now);
      await game.load();
    });

    test('steps become pending, collect turns them into coins', () async {
      steps.addSteps(1200);
      await game.syncSteps();
      expect(game.state.lifetimeSteps, 1200);
      expect(game.state.pendingSteps, 1200);
      expect(game.collect(), 1200);
      expect(game.state.coins, 1200);
      expect(game.state.pendingSteps, 0);
    });

    test('syncing twice does not double count', () async {
      steps.addSteps(500);
      await game.syncSteps();
      await game.syncSteps();
      expect(game.state.lifetimeSteps, 500);
    });

    test('only 50,000 steps count per day', () async {
      steps.addSteps(70000);
      await game.syncSteps();
      expect(game.state.lifetimeSteps, 50000);
      now = now.add(const Duration(days: 1));
      steps.addSteps(1000);
      await game.syncSteps();
      expect(game.state.lifetimeSteps, 51000);
    });

    test('buying shoes raises coins per step', () async {
      steps.addSteps(100);
      await game.syncSteps();
      game.collect();
      expect(game.buyShoes(), isTrue);
      expect(game.state.coins, 0);
      expect(game.coinsPerStep, 2);
      expect(game.buyShoes(), isFalse);
    });

    test('locked generators cannot be bought', () async {
      steps.addSteps(5000);
      await game.syncSteps();
      game.collect();
      expect(game.buyGenerator(1), isFalse); // Dog walker needs 10,000
      expect(game.buyGenerator(0), isTrue);
    });

    test('away income is paid for at most 8 hours', () async {
      steps.addSteps(50);
      await game.syncSteps();
      game.collect();
      game.buyGenerator(0); // Paperboy: 1 coin/min
      await game.save();

      now = now.add(const Duration(hours: 30));
      final reloaded =
          GameController(store: store, steps: steps, clock: () => now);
      final away = await reloaded.load();
      expect(away, closeTo(8 * 60, 1e-6));
    });

    test('milestone bonus is paid once', () async {
      steps.addSteps(25000);
      await game.syncSteps();
      final coins = game.state.coins;
      expect(coins, Tuning.milestoneBonusSteps.toDouble());
      steps.addSteps(10);
      await game.syncSteps();
      expect(game.state.coins, coins);
    });
  });
}
