import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game/game_controller.dart';
import 'game/game_store.dart';
import 'steps/step_source.dart';
import 'ui/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final steps = FakeStepSource();
  final game = GameController(store: PrefsGameStore(prefs), steps: steps);
  final away = await game.load();
  runApp(OneMillionStepsApp(game: game, fakeSteps: steps, awayEarnings: away));
}

class OneMillionStepsApp extends StatelessWidget {
  const OneMillionStepsApp({
    super.key,
    required this.game,
    this.fakeSteps,
    this.awayEarnings = 0,
  });

  final GameController game;
  final FakeStepSource? fakeSteps;
  final double awayEarnings;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '1 Million Steps',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      ),
      home: HomeScreen(
        game: game,
        fakeSteps: fakeSteps,
        awayEarnings: awayEarnings,
      ),
    );
  }
}
