import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_million_steps/game/game_controller.dart';
import 'package:one_million_steps/game/game_store.dart';
import 'package:one_million_steps/main.dart';
import 'package:one_million_steps/steps/step_source.dart';

void main() {
  testWidgets('home screen shows progress and helpers', (tester) async {
    final steps = FakeStepSource();
    final game = GameController(store: MemoryGameStore(), steps: steps);
    await tester.runAsync(game.load);

    await tester.pumpWidget(OneMillionStepsApp(game: game, fakeSteps: steps));
    await tester.pump();

    expect(find.text('Lifetime steps'), findsOneWidget);
    expect(find.text('Paperboy'), findsOneWidget);
    expect(find.text('Walk to earn steps'), findsOneWidget);

    // Dispose the screen so its 1s ticker is cancelled.
    await tester.pumpWidget(const SizedBox());
  });
}
