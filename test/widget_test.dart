import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_million_steps/game/catalog.dart';
import 'package:one_million_steps/game/clock.dart';
import 'package:one_million_steps/game/config.dart';
import 'package:one_million_steps/game/economy.dart';
import 'package:one_million_steps/game/game_controller.dart';
import 'package:one_million_steps/game/game_state.dart';
import 'package:one_million_steps/game/game_store.dart';
import 'package:one_million_steps/main.dart';
import 'package:one_million_steps/steps/step_source.dart';

DateTime now() => DateTime(2026, 11, 9, 9); // Monday, week 149

Future<GameController> boot(WidgetTester tester, GameStore store) async {
  tester.view.physicalSize = const Size(1080, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final steps = FakeStepSource(clock: now);
  final game = GameController(store: store, steps: steps, clock: now);
  await tester.runAsync(game.load);
  await tester.pumpWidget(OneMillionStepsApp(game: game, fakeSteps: steps));
  await tester.pump();
  return game;
}

void main() {
  testWidgets('a new player starts the ladder with a park walk', (
    tester,
  ) async {
    final game = await boot(tester, MemoryGameStore());

    expect(find.text('Maratona giden yol'), findsOneWidget);
    await tester.tap(find.text('Hazırlığa başla'));
    await tester.pumpAndSettle();

    // Ladder first, weekly races locked behind their stage.
    expect(find.text('Hazırlık'), findsOneWidget);
    expect(find.text('Kademe 5 ile açılır'), findsWidgets);

    await tester.tap(find.text('Park Yürüyüşü'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Başla'));
    await tester.pumpAndSettle();

    expect(game.activeStage, trainingStages.first);
    expect(find.text('Yürüyüşü bırak'), findsOneWidget);
    expect(find.text('Süre sınırı yok'), findsOneWidget);

    // Dispose the shell so its sync timer is cancelled.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('after the ladder, join a marathon and see it on the race tab', (
    tester,
  ) async {
    final store = MemoryGameStore();
    final seeded = GameState.fresh(now(), coins: Tuning.startingCoins);
    for (final st in trainingStages) {
      seeded.results.add(
        RaceResult(
          courseId: st.course.id,
          week: null,
          outcome: RaceOutcome.finished,
          endedAt: now(),
          meters: st.course.meters,
        ),
      );
    }
    await store.save(seeded);
    final game = await boot(tester, store);

    expect(find.text('Aktif yarışın yok'), findsOneWidget);

    await tester.tap(find.text('Maratonlar').last);
    await tester.pumpAndSettle();
    expect(find.text('Bu hafta'), findsOneWidget);
    expect(find.text('Boğaz Maratonu'), findsOneWidget);
    expect(find.text('Peri Bacaları Ultra'), findsOneWidget);
    expect(find.text('Hazırlık tamamlandı'), findsOneWidget);

    await tester.tap(find.text('Boğaz Maratonu'));
    await tester.pumpAndSettle();
    expect(find.text('Ödüller'), findsOneWidget);

    await tester.tap(find.text('Katıl'));
    await tester.pumpAndSettle();

    expect(game.race?.courseId, 'bogaz_maratonu');
    expect(find.text('Yarıştan çekil'), findsOneWidget);
    expect(find.text('%0 tamamlandı'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('debug tools explain the daily cap and skip to the next day', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final clock = DebugClock();
    final steps = FakeStepSource(
      clock: clock.now,
      initial: {dayKey(clock.now()): 165000},
    );
    final game = GameController(
      store: MemoryGameStore(),
      steps: steps,
      clock: clock.now,
    );
    await tester.runAsync(game.load);
    await tester.runAsync(() => game.startTraining(trainingStages.first));
    await tester.pumpWidget(
      OneMillionStepsApp(game: game, fakeSteps: steps, debugClock: clock),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('sınırı doldu'), findsOneWidget);
    await tester.tap(find.text('+5.000 adım (debug)'));
    await tester.pumpAndSettle();
    expect(game.race!.steps, 0);
    expect(find.textContaining('ertesi güne geç'), findsOneWidget);

    await tester.tap(find.text('Ertesi gün (debug)'));
    await tester.pumpAndSettle();
    expect(clock.dayOffset, 1);
    expect(find.textContaining('sınırı doldu'), findsNothing);

    await tester.tap(find.text('+5.000 adım (debug)'));
    await tester.pumpAndSettle();
    expect(find.text('Kademe tamamlandı!'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('with Health steps, says where steps come from until they do', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final steps = FakeStepSource(clock: now);
    final game = GameController(
      store: MemoryGameStore(),
      steps: steps,
      clock: now,
    );
    await tester.runAsync(game.load);
    await tester.pumpWidget(OneMillionStepsApp(game: game, healthSteps: true));
    await tester.pump();

    expect(find.textContaining('Sağlık uygulamasından gelir'), findsOneWidget);
    // Health builds have no test buttons.
    expect(find.text('+5.000 adım (debug)'), findsNothing);

    steps.addSteps(1200);
    await tester.runAsync(game.syncSteps);
    await tester.pump();
    expect(find.textContaining('Sağlık uygulamasından gelir'), findsNothing);
    expect(find.text('1.200'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
