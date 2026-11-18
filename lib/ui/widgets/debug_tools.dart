import 'package:material_ui/material_ui.dart';

import '../../game/clock.dart';
import '../../game/config.dart';
import '../../game/game_controller.dart';
import '../../steps/step_source.dart';
import '../format.dart';
import '../theme/tokens.dart';

/// Test buttons: add steps, and jump to the next day (to get past the
/// daily cap or to test multi-day races). Shown when `kTestTools` is on.
class DebugTools extends StatelessWidget {
  const DebugTools({
    super.key,
    required this.game,
    required this.steps,
    required this.clock,
    required this.onSync,
  });

  final GameController game;
  final FakeStepSource steps;
  final DebugClock? clock;
  final Future<void> Function() onSync;

  void _say(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _addSteps(BuildContext context) async {
    final before = game.todaySteps;
    steps.addSteps(5000);
    await onSync();
    if (!context.mounted) return;
    if (game.todaySteps == before && game.dailyCapReached) {
      _say(
        context,
        'Bugünün ${groupThousands(Tuning.dailyStepCap)} adım sınırı dolu, '
        'adımlar sayılmadı. Denemeye devam etmek için ertesi güne geç.',
      );
    }
  }

  Future<void> _nextDay(BuildContext context) async {
    clock!.nextDay();
    await game.clockChanged();
    await onSync();
    if (!context.mounted) return;
    _say(context, '${dayMonth(game.now)} oldu. Günlük sayaç sıfırlandı.');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (clock != null) ...[
          FloatingActionButton.extended(
            heroTag: 'debug_next_day',
            onPressed: () => _nextDay(context),
            backgroundColor: cs.surfaceContainerLow,
            foregroundColor: cs.onSurface,
            icon: const Icon(Icons.event_repeat_rounded),
            label: const Text('Ertesi gün (debug)'),
          ),
          const SizedBox(height: AppSpace.s12),
        ],
        FloatingActionButton.extended(
          heroTag: 'debug_steps',
          onPressed: () => _addSteps(context),
          icon: const Icon(Icons.directions_walk_rounded),
          label: const Text('+5.000 adım (debug)'),
        ),
      ],
    );
  }
}
