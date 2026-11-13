import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:one_million_steps/game/catalog.dart';
import 'package:one_million_steps/game/clock.dart';
import 'package:one_million_steps/game/config.dart';
import 'package:one_million_steps/game/economy.dart';
import 'package:one_million_steps/game/game_controller.dart';
import 'package:one_million_steps/game/game_state.dart';
import 'package:one_million_steps/game/game_store.dart';
import 'package:one_million_steps/game/models.dart';
import 'package:one_million_steps/game/schedule.dart';
import 'package:one_million_steps/steps/step_source.dart';
import 'package:one_million_steps/ui/format.dart';

/// Saves a fresh state with the first [upTo] training stages done.
Future<void> seedTraining(
  MemoryGameStore store,
  DateTime now, {
  int upTo = 6,
}) async {
  final s = GameState.fresh(now, coins: Tuning.startingCoins);
  for (final st in trainingStages.take(upTo)) {
    s.results.add(
      RaceResult(
        courseId: st.course.id,
        week: null,
        outcome: RaceOutcome.finished,
        endedAt: now,
        meters: st.course.meters,
      ),
    );
  }
  await store.save(s);
}

void main() {
  final bogaz = courseById['bogaz_maratonu']!;
  final surlar = courseById['surlar_10k']!;

  group('economy', () {
    test('gear bonuses add up per weather and terrain', () {
      final wind = gearById['outfit_wind']!;
      final asphalt = gearById['shoe_asphalt']!;
      expect(bonusPct([wind, asphalt], bogaz), 45); // windy 25 + asphalt 20
      expect(bonusPct([wind, asphalt], surlar), 0); // sunny cobblestone
      expect(metersPerStep(20), closeTo(0.9, 1e-9));
    });

    test('medal tiers follow days used', () {
      expect(baseSteps(bogaz), 56267);
      expect(goldDays(bogaz), 4);
      expect(silverDays(bogaz), 6);
      expect(medalFor(bogaz, 4), Medal.gold);
      expect(medalFor(bogaz, 5), Medal.silver);
      expect(medalFor(bogaz, 7), Medal.bronze);
    });

    test('coin reward scales with distance and medal', () {
      expect(rewardCoins(bogaz, Medal.gold), 844);
      expect(rewardCoins(bogaz, Medal.silver), 633);
      expect(rewardCoins(bogaz, Medal.bronze), 422);
    });

    test('days left counts today and ends at midnight', () {
      final closes = DateTime(2026, 11, 16);
      expect(daysLeft(DateTime(2026, 11, 13, 10), closes), 3);
      expect(daysLeft(DateTime(2026, 11, 15, 23), closes), 1);
      expect(daysLeft(closes, closes), 0);
    });

    test('daily cap is 50,000', () {
      expect(countableDailySteps(60000), 50000);
      expect(countableDailySteps(7500), 7500);
    });
  });

  group('schedule', () {
    test('weeks start on Monday', () {
      expect(weekIndexOf(DateTime(2026, 11, 9)), 149);
      expect(weekIndexOf(DateTime(2026, 11, 15, 23, 59)), 149);
      expect(weekIndexOf(DateTime(2026, 11, 16)), 150);
      expect(weekStart(149), DateTime(2026, 11, 9));
    });

    test('each week opens one short, one medium and one ultra race', () {
      final week = lineup(149);
      expect(week.map((e) => e.course.length), [
        RaceLength.short,
        RaceLength.medium,
        RaceLength.ultra,
      ]);
      expect(week[1].course, bogaz);
      expect(week[1].opensAt, DateTime(2026, 11, 9));
      expect(week[1].closesAt, DateTime(2026, 11, 16));
      expect(lineup(150)[1].course, isNot(bogaz));
    });

    test('every course and gear id is unique', () {
      final courses = [
        ...trainingStages.map((s) => s.course),
        ...coursePools.expand((p) => p),
      ];
      expect(courseById.length, courses.length);
      expect(gearById.length, gearDefs.length);
    });
  });

  group('format', () {
    test('Turkish numbers, percent and uppercase', () {
      expect(groupThousands(1234567), '1.234.567');
      expect(formatKm(42195), '42,1 km');
      expect(formatKm(1234500), '1.234,5 km');
      expect(bonusPercent(25), '+%25');
      expect(trUpper('İç Anadolu'), 'İÇ ANADOLU');
      expect(trUpper('ultra'), 'ULTRA');
      expect(trUpper('kısa'), 'KISA');
    });
  });

  group('controller', () {
    late DateTime now;
    late FakeStepSource steps;
    late MemoryGameStore store;
    late GameController game;

    MarathonEvent eventFor(Course c) =>
        game.thisWeek.firstWhere((e) => e.course == c);

    setUp(() async {
      now = DateTime(2026, 11, 9, 9); // Monday, week 149
      steps = FakeStepSource(clock: () => now);
      store = MemoryGameStore();
      await seedTraining(store, now); // race tests start with the ladder done
      game = GameController(store: store, steps: steps, clock: () => now);
      await game.load();
    });

    test('a seeded player starts with coins and starter gear', () {
      expect(game.state.coins, Tuning.startingCoins);
      expect(game.equippedIn(GearSlot.shoes).id, starterShoesId);
      expect(game.equippedIn(GearSlot.outfit).id, starterOutfitId);
      expect(game.race, isNull);
    });

    test('only steps taken after joining move the race', () async {
      steps.addSteps(3000);
      expect(await game.join(eventFor(bogaz)), isNull);
      steps.addSteps(1000);
      await game.syncSteps();
      expect(game.race!.steps, 1000);
      expect(game.race!.meters, closeTo(750, 1e-9));
      expect(game.state.lifetimeSteps, 4000);
    });

    test('matching gear makes each step go further', () async {
      expect(game.buy(gearById['outfit_wind']!), isTrue); // windy +25%
      expect(game.state.coins, 0);
      await game.join(eventFor(bogaz));
      steps.addSteps(1000);
      await game.syncSteps();
      expect(game.race!.meters, closeTo(937.5, 1e-9));
    });

    test('a fast finish earns gold and coins', () async {
      await game.join(eventFor(bogaz));
      for (var day = 0; day < 3; day++) {
        now = DateTime(2026, 11, 9 + day, 20);
        steps.addSteps(20000);
        await game.syncSteps();
      }
      expect(game.race, isNull);
      final r = game.state.results.last;
      expect(r.outcome, RaceOutcome.finished);
      expect(r.medal, Medal.gold);
      expect(r.daysUsed, 3);
      expect(game.state.coins, Tuning.startingCoins + 844);
      expect(game.statusOf(eventFor(bogaz)), EventStatus.finished);
      expect(game.takeUnseenResults(), [r]);
      expect(game.takeUnseenResults(), isEmpty);
    });

    test('a slow finish earns bronze', () async {
      await game.join(eventFor(surlar));
      for (var day = 0; day < 3; day++) {
        now = DateTime(2026, 11, 9 + day, 20);
        steps.addSteps(5000);
        await game.syncSteps();
      }
      final r = game.state.results.last;
      expect(r.medal, Medal.bronze);
      expect(r.coins, 100);
    });

    test('time runs out at the end of the week', () async {
      await game.join(eventFor(bogaz));
      steps.addSteps(10000);
      await game.syncSteps();

      // Sunday steps count even if synced on Monday; Monday steps do not.
      steps.addSteps(5000, at: DateTime(2026, 11, 15, 18));
      now = DateTime(2026, 11, 16, 10);
      steps.addSteps(3000);
      final sync = await game.syncSteps();

      expect(sync.ended?.outcome, RaceOutcome.timeUp);
      expect(game.race, isNull);
      final r = game.state.results.last;
      expect(r.meters, closeTo(15000 * 0.75, 1e-9));
      expect(r.coins, 0);
      expect(game.state.coins, Tuning.startingCoins);
    });

    test('one race at a time, and no rejoining after withdrawing', () async {
      await game.join(eventFor(bogaz));
      expect(await game.join(eventFor(surlar)), JoinError.raceInProgress);
      game.withdraw();
      expect(game.race, isNull);
      expect(game.takeUnseenResults(), isEmpty);
      expect(await game.join(eventFor(bogaz)), JoinError.alreadyRun);
      expect(await game.join(eventFor(surlar)), isNull);
    });

    test('next week cannot be joined yet', () async {
      final next = game.nextWeek.first;
      expect(game.statusOf(next), EventStatus.upcoming);
      expect(await game.join(next), JoinError.notOpen);
    });

    test('buying needs coins and puts the item on', () {
      expect(game.buy(gearById['shoe_carbon']!), isFalse);
      final shoes = gearById['shoe_asphalt']!;
      expect(game.buy(shoes), isTrue);
      expect(game.isEquipped(shoes), isTrue);
      expect(game.buy(shoes), isFalse); // already owned
      expect(game.equip(gearById[starterShoesId]!), isTrue);
      expect(game.isEquipped(shoes), isFalse);
    });

    test('progress survives a reload', () async {
      game.buy(gearById['shoe_asphalt']!);
      await game.join(eventFor(bogaz));
      steps.addSteps(2000);
      await game.syncSteps();
      await game.save();

      final reloaded = GameController(
        store: store,
        steps: steps,
        clock: () => now,
      );
      await reloaded.load();
      expect(reloaded.race!.courseId, bogaz.id);
      expect(reloaded.race!.steps, 2000);
      expect(reloaded.isEquipped(gearById['shoe_asphalt']!), isTrue);
    });

    test('saves from the old idle game are discarded', () {
      final old = jsonDecode(
        '{"v":1,"installedAt":"2026-11-01T00:00:00.000",'
        '"coins":5000}',
      ) as Map<String, dynamic>;
      expect(GameState.fromJson(old), isNull);
    });
  });

  group('training ladder', () {
    late DateTime now;
    late FakeStepSource steps;
    late MemoryGameStore store;
    late GameController game;

    TrainingStage stage(int tier) => trainingStages[tier - 1];
    MarathonEvent eventFor(Course c) =>
        game.thisWeek.firstWhere((e) => e.course == c);

    Future<void> start({int trained = 0}) async {
      now = DateTime(2026, 11, 9, 9);
      steps = FakeStepSource(clock: () => now);
      store = MemoryGameStore();
      if (trained > 0) await seedTraining(store, now, upTo: trained);
      game = GameController(store: store, steps: steps, clock: () => now);
      await game.load();
    }

    test('a new player starts at stage 1 with every race locked', () async {
      await start();
      expect(game.statusOfStage(stage(1)), StageStatus.available);
      expect(game.statusOfStage(stage(2)), StageStatus.locked);
      for (final e in game.thisWeek) {
        expect(game.statusOf(e), EventStatus.locked);
      }
      expect(await game.join(eventFor(bogaz)), JoinError.locked);
      expect(await game.startTraining(stage(2)), JoinError.locked);
    });

    test('finishing a stage pays coins and opens the next one', () async {
      await start();
      expect(await game.startTraining(stage(1)), isNull);
      steps.addSteps(3000); // 2 km = 2,667 steps
      final sync = await game.syncSteps();

      final r = sync.ended!;
      expect(r.isTraining, isTrue);
      expect(r.medal, isNull);
      expect(r.coins, 30);
      expect(game.state.coins, Tuning.startingCoins + 30);
      expect(game.statusOfStage(stage(1)), StageStatus.done);
      expect(game.statusOfStage(stage(2)), StageStatus.available);
      expect(game.takeUnseenResults(), [r]);
      expect(await game.startTraining(stage(1)), JoinError.alreadyRun);
    });

    test('training walks have no time limit', () async {
      await start(trained: 2);
      await game.startTraining(stage(3));
      steps.addSteps(1000);
      await game.syncSteps();
      now = now.add(const Duration(days: 20));
      await game.syncSteps();
      expect(game.race?.courseId, stage(3).course.id);
      expect(game.race!.steps, 1000);
    });

    test('leaving a walk drops progress but allows a restart', () async {
      await start();
      await game.startTraining(stage(1));
      steps.addSteps(1000);
      await game.syncSteps();
      expect(game.withdraw(), isNull);
      expect(game.race, isNull);
      expect(game.state.results, isEmpty);
      expect(await game.startTraining(stage(1)), isNull);
      expect(game.race!.steps, 0);
    });

    test('race lengths open at stages 4, 5 and 6', () async {
      await start(trained: 4);
      expect(game.isLengthUnlocked(RaceLength.short), isTrue);
      expect(game.isLengthUnlocked(RaceLength.medium), isFalse);
      expect(game.statusOf(eventFor(bogaz)), EventStatus.locked);
      expect(await game.join(eventFor(surlar)), isNull);

      await start(trained: 5);
      expect(game.isLengthUnlocked(RaceLength.medium), isTrue);
      expect(game.isLengthUnlocked(RaceLength.ultra), isFalse);

      await start(trained: 6);
      expect(game.trainingComplete, isTrue);
      expect(game.isLengthUnlocked(RaceLength.ultra), isTrue);
    });

    test('one active course at a time across walks and races', () async {
      await start(trained: 4);
      await game.startTraining(stage(5));
      expect(await game.join(eventFor(surlar)), JoinError.raceInProgress);
    });

    test('an active walk survives a reload', () async {
      await start();
      await game.startTraining(stage(1));
      steps.addSteps(500);
      await game.syncSteps();
      await game.save();
      final reloaded = GameController(
        store: store,
        steps: steps,
        clock: () => now,
      );
      await reloaded.load();
      expect(reloaded.activeStage, stage(1));
      expect(reloaded.race!.steps, 500);
    });

    test('a full daily cap stops a walk until the next day', () async {
      await start();
      // Steps before starting fill the cap but do not count for the walk.
      steps.addSteps(165000);
      await game.syncSteps();
      expect(game.dailyCapReached, isTrue);
      await game.startTraining(stage(1));

      steps.addSteps(5000);
      final sameDay = await game.syncSteps();
      expect(sameDay.newSteps, 0);
      expect(game.race!.steps, 0);

      now = now.add(const Duration(days: 1));
      expect(game.dailyCapReached, isFalse);
      steps.addSteps(5000);
      final nextDay = await game.syncSteps();
      expect(nextDay.ended?.courseId, stage(1).course.id);
    });
  });

  group('debug clock', () {
    test('jumps whole calendar days and reports the offset', () {
      final saved = <int>[];
      final clock = DebugClock(onChanged: saved.add);
      final before = clock.now();
      clock.nextDay();
      clock.nextDay();
      final after = clock.now();
      expect(
        dayKey(after),
        dayKey(DateTime(before.year, before.month, before.day + 2)),
      );
      expect(saved, [1, 2]);
      expect(DebugClock(dayOffset: 3).dayOffset, 3);
    });
  });
}
