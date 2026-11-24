import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'build_flags.dart';
import 'game/clock.dart';
import 'game/game_controller.dart';
import 'game/game_store.dart';
import 'steps/health_step_source.dart';
import 'steps/step_source.dart';
import 'ui/screens/home_shell.dart';
import 'ui/theme/app_theme.dart';

const _debugStepsKey = 'debug_steps';
const _debugDayKey = 'debug_day_offset';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  if (useHealthSteps) {
    await _runWithHealthSteps(prefs);
  } else {
    await _runWithFakeSteps(prefs);
  }
}

/// Real steps from Apple Health, with their own save. Steps count from the
/// first launch of a build with real steps.
Future<void> _runWithHealthSteps(SharedPreferences prefs) async {
  final steps = HealthStepSource();
  final game = GameController(
    store: PrefsGameStore(prefs, key: PrefsGameStore.healthStepsKey),
    steps: steps,
  );
  await game.load();
  runApp(OneMillionStepsApp(game: game, healthSteps: true));

  // Ask for Health access once the first frame is up, so iOS has a window to
  // show its sheet on, then count the steps right away.
  await WidgetsBinding.instance.endOfFrame;
  await steps.authorize();
  await game.syncSteps();
}

Future<void> _runWithFakeSteps(SharedPreferences prefs) async {
  // Test builds can jump ahead by days to test multi-day races.
  final clock = DebugClock(
    dayOffset: kTestTools ? prefs.getInt(_debugDayKey) ?? 0 : 0,
    onChanged: (days) => prefs.setInt(_debugDayKey, days),
  );

  // Debug steps survive restarts so a race can be tested over several runs.
  final saved = prefs.getString(_debugStepsKey);
  final steps = FakeStepSource(
    clock: clock.now,
    initial: saved == null
        ? null
        : (jsonDecode(saved) as Map<String, dynamic>).map(
            (k, v) => MapEntry(k, (v as num).toInt()),
          ),
    onChanged: (totals) => prefs.setString(_debugStepsKey, jsonEncode(totals)),
  );

  final game = GameController(
    store: PrefsGameStore(prefs),
    steps: steps,
    clock: clock.now,
  );
  await game.load();
  runApp(OneMillionStepsApp(game: game, fakeSteps: steps, debugClock: clock));
}

class OneMillionStepsApp extends StatelessWidget {
  const OneMillionStepsApp({
    super.key,
    required this.game,
    this.fakeSteps,
    this.debugClock,
    this.healthSteps = false,
  });

  final GameController game;
  final FakeStepSource? fakeSteps;
  final DebugClock? debugClock;

  /// Steps come from Apple Health (shows where they come from until the
  /// first ones arrive).
  final bool healthSteps;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '1 Million Steps',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      locale: const Locale('tr', 'TR'),
      supportedLocales: const [Locale('tr', 'TR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: HomeShell(
        game: game,
        fakeSteps: fakeSteps,
        debugClock: debugClock,
        healthSteps: healthSteps,
      ),
    );
  }
}
