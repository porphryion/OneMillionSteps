import 'package:material_ui/material_ui.dart';

import '../../game/catalog.dart';
import '../../game/economy.dart' as eco;
import '../../game/game_controller.dart';
import '../../game/game_state.dart';
import '../../game/models.dart';
import '../../game/schedule.dart';
import '../format.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/badges.dart';
import '../widgets/common.dart';
import '../widgets/clay.dart';
import '../widgets/conditions.dart';
import '../widgets/race_widgets.dart';
import '../widgets/training_path.dart';
import 'marathon_detail_screen.dart';
import 'training_detail_screen.dart';

/// Tab 2: the training ladder, this week's races and next week's preview.
/// Until the ladder is done it comes first; afterwards it folds away at the
/// bottom.
class MarathonsScreen extends StatelessWidget {
  const MarathonsScreen({
    super.key,
    required this.game,
    required this.onSync,
    required this.onJoined,
  });

  final GameController game;
  final Future<void> Function() onSync;

  /// Called after the player joins a race (or opens the one they run).
  final VoidCallback onJoined;

  Future<void> _open(BuildContext context, MarathonEvent e) async {
    final goToRace = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => MarathonDetailScreen(game: game, event: e),
      ),
    );
    if (goToRace == true) onJoined();
  }

  Future<void> _openStage(BuildContext context, TrainingStage s) async {
    final goToRace = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TrainingDetailScreen(game: game, stage: s),
      ),
    );
    if (goToRace == true) onJoined();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: game,
      builder: (context, _) {
        final week = game.thisWeek;
        final next = game.nextWeek;
        final lastDay = week.first.closesAt.subtract(const Duration(hours: 12));
        return Scaffold(
          appBar: AppBar(
            title: const Text('Maratonlar'),
            actions: [CoinBalance(game.state.coins)],
          ),
          body: RefreshIndicator(
            onRefresh: onSync,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: pagePadding(context, top: 0),
              children: [
                if (!game.trainingComplete) ...[
                  TrainingHeader(game: game),
                  TrainingPath(
                    game: game,
                    onOpen: (s) => _openStage(context, s),
                  ),
                ],
                SectionHeader(
                  'Bu hafta',
                  subtitle:
                      '${dateRange(week.first.opensAt, lastDay)} · '
                      '${timeLeftLabel(game.daysLeft(week.first))}',
                ),
                for (final e in week) ...[
                  MarathonCard(
                    game: game,
                    event: e,
                    onTap: () => _open(context, e),
                  ),
                  const SizedBox(height: AppSpace.s12),
                ],
                SectionHeader(
                  'Gelecek hafta',
                  subtitle: 'Pazartesi ${dayMonth(next.first.opensAt)} açılır',
                ),
                for (final e in next) ...[
                  MarathonCard(
                    game: game,
                    event: e,
                    onTap: () => _open(context, e),
                  ),
                  const SizedBox(height: AppSpace.s12),
                ],
                if (game.trainingComplete)
                  _LadderDone(
                    game: game,
                    onOpen: (s) => _openStage(context, s),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class MarathonCard extends StatelessWidget {
  const MarathonCard({
    super.key,
    required this.game,
    required this.event,
    required this.onTap,
  });

  final GameController game;
  final MarathonEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final course = event.course;
    final parts = game.bonusParts(course);
    final status = game.statusOf(event);
    final result = game.resultFor(event);

    return ClayCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CourseBanner(
            course: course,
            borderRadius: BorderRadius.zero,
            locked: status == EventStatus.locked,
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpace.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpace.s8,
                  runSpacing: AppSpace.s8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpace.s4),
                      child: Text(
                        formatKm(course.meters),
                        style: tabular(t.titleLarge),
                      ),
                    ),
                    ConditionChip.weather(course.weather, bonus: parts.weather),
                    ConditionChip.terrain(course.terrain, bonus: parts.terrain),
                  ],
                ),
                const SizedBox(height: AppSpace.s12),
                Row(
                  children: [
                    Expanded(child: _StatusLine(game, event, status)),
                    const SizedBox(width: AppSpace.s8),
                    if (result != null && result.coins > 0)
                      CoinAmount(result.coins, signed: true)
                    else if (status != EventStatus.missed &&
                        status != EventStatus.closed)
                      Semantics(
                        label: 'Ödül en fazla',
                        child: CoinAmount(eco.rewardCoins(course, Medal.gold)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine(this.game, this.event, this.status);

  final GameController game;
  final MarathonEvent event;
  final EventStatus status;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final orange = GameColors.of(context).primaryText;

    Widget line(IconData icon, String text, {Color? color}) => Row(
      children: [
        ExcludeSemantics(
          child: Icon(icon, size: AppIconSize.sm, color: color ?? muted),
        ),
        const SizedBox(width: AppSpace.s4),
        Flexible(
          child: Text(
            text,
            style: t.labelLarge?.copyWith(color: color ?? muted),
          ),
        ),
      ],
    );

    switch (status) {
      case EventStatus.open:
        return line(
          Icons.schedule_rounded,
          timeLeftLabel(game.daysLeft(event)),
        );
      case EventStatus.running:
        return line(
          Icons.directions_run_rounded,
          'Koşuyorsun · ${percent((game.raceProgress * 100).floor())}',
          color: orange,
        );
      case EventStatus.finished:
        final medal = game.resultFor(event)!.medal!;
        return Row(
          children: [
            MedalBadge(medal, size: 24),
            const SizedBox(width: AppSpace.s8),
            Flexible(
              child: Text('${medal.label} madalya', style: t.labelLarge),
            ),
          ],
        );
      case EventStatus.missed:
        final withdrew = game.resultFor(event)!.outcome == RaceOutcome.withdrew;
        return line(Icons.flag_outlined, withdrew ? 'Çekildin' : 'Süre doldu');
      case EventStatus.locked:
        final gate = stageUnlocking(event.course.length)!;
        return line(Icons.lock_rounded, 'Kademe ${gate.tier} ile açılır');
      case EventStatus.upcoming:
        return line(Icons.event_rounded, 'Pazartesi açılır');
      case EventStatus.closed:
        return line(Icons.lock_rounded, 'Kapandı');
    }
  }
}

/// Folded ladder for players who finished it.
class _LadderDone extends StatelessWidget {
  const _LadderDone({required this.game, required this.onOpen});

  final GameController game;
  final void Function(TrainingStage stage) onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.s12),
      child: ClayCard(
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          leading: StageNode(
            status: StageStatus.done,
            tier: trainingStages.length,
          ),
          title: const Text('Hazırlık tamamlandı'),
          subtitle: Text(
            '${trainingStages.length}/${trainingStages.length} kademe',
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpace.s16,
            0,
            AppSpace.s16,
            AppSpace.s16,
          ),
          children: [TrainingPath(game: game, onOpen: onOpen)],
        ),
      ),
    );
  }
}
