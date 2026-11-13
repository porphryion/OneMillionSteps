import 'package:material_ui/material_ui.dart';

import '../../game/economy.dart' as eco;
import '../../game/game_controller.dart';
import '../../game/models.dart';
import '../format.dart';
import '../theme/tokens.dart';
import '../widgets/badges.dart';
import '../widgets/common.dart';
import '../widgets/race_widgets.dart';
import '../widgets/run_sections.dart';
import '../widgets/training_path.dart';

/// A training stage's details and the start button. Pops with `true` when
/// the player should land on the race tab.
class TrainingDetailScreen extends StatelessWidget {
  const TrainingDetailScreen({
    super.key,
    required this.game,
    required this.stage,
  });

  final GameController game;
  final TrainingStage stage;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: game,
      builder: (context, _) {
        final t = Theme.of(context).textTheme;
        final course = stage.course;
        final status = game.statusOfStage(stage);
        final reason = _blockedReason(status);
        final canRun =
            status == StageStatus.available || status == StageStatus.running;

        return Scaffold(
          appBar: AppBar(actions: [CoinBalance(game.state.coins)]),
          body: ListView(
            padding: pagePadding(context),
            children: [
              CourseBanner(
                course: course,
                large: true,
                locked: status == StageStatus.locked,
              ),
              const SizedBox(height: AppSpace.s16),
              Text(course.blurb, style: t.bodyLarge),
              const SectionHeader('Parkur'),
              CourseFacts(course: course, timeValue: 'Sınırsız'),
              GearBonusSection(game: game, course: course),
              const SectionHeader('Tahmin'),
              Text(_estimate(status), style: t.bodyLarge),
              const SectionHeader(
                'Ödül',
                subtitle: 'Bitirince kazanacakların.',
              ),
              StageRewards(stage: stage),
            ],
          ),
          bottomNavigationBar: DetailCta(
            label: switch (status) {
              StageStatus.available => 'Başla',
              StageStatus.running => 'Yürüyüşe dön',
              StageStatus.done => 'Tamamlandı',
              StageStatus.locked => 'Kilitli',
            },
            reason: reason,
            onPressed: canRun && reason == null
                ? () => _onPressed(context, status)
                : null,
          ),
        );
      },
    );
  }

  String _estimate(StageStatus status) {
    if (status == StageStatus.running) {
      return 'Bitişe ~${groupThousands(game.stepsToFinish)} adım kaldı. '
          'Süre sınırı yok, kendi temponda yürü.';
    }
    final steps = eco.stepsFor(
      stage.course.meters,
      game.bonusFor(stage.course),
    );
    return 'Mevcut ekipmanınla ~${groupThousands(steps)} adım. '
        'Süre sınırı yok, kendi temponda yürü.';
  }

  String? _blockedReason(StageStatus status) {
    if (status == StageStatus.locked) return 'Önce önceki kademeyi bitir.';
    if (status == StageStatus.available && game.race != null) {
      return 'Aynı anda tek parkurda ilerleyebilirsin. '
          'Önce aktif yarışını bitir.';
    }
    return null;
  }

  Future<void> _onPressed(BuildContext context, StageStatus status) async {
    if (status == StageStatus.running) {
      Navigator.pop(context, true);
      return;
    }
    final error = await game.startTraining(stage);
    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(switch (error) {
            JoinError.raceInProgress => 'Önce aktif yarışını bitir.',
            JoinError.locked => 'Önce önceki kademeyi bitir.',
            JoinError.alreadyRun => 'Bu kademeyi zaten bitirdin.',
            JoinError.notOpen => 'Bu kademe şu an açık değil.',
          }),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Yürüyüş başladı. Kolay gelsin!')),
    );
    Navigator.pop(context, true);
  }
}
