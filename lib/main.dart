import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game/clock.dart';
import 'game/game_controller.dart';
import 'game/game_store.dart';
import 'steps/step_source.dart';
import 'ui/screens/home_shell.dart';
import 'ui/theme/app_theme.dart';

const _debugStepsKey = 'debug_steps';
const _debugDayKey = 'debug_day_offset';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // Debug builds can jump ahead by days to test multi-day races.
  final clock = DebugClock(
    dayOffset: kDebugMode ? prefs.getInt(_debugDayKey) ?? 0 : 0,
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
  });

  final GameController game;
  final FakeStepSource? fakeSteps;
  final DebugClock? debugClock;

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
      home: HomeShell(game: game, fakeSteps: fakeSteps, debugClock: debugClock),
    );
  }
}
