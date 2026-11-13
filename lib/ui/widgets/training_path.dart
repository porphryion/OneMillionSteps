import 'package:material_ui/material_ui.dart';

import '../../game/catalog.dart';
import '../../game/economy.dart' as eco;
import '../../game/game_controller.dart';
import '../../game/models.dart';
import '../format.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'badges.dart';
import 'clay.dart';
import 'common.dart';
import 'mascot.dart';

/// What finishing [s] opens: the next tier and/or a weekly race length.
List<String> unlockLines(TrainingStage s) {
  final next = s.tier < trainingStages.length ? trainingStages[s.tier] : null;
  return [
    if (next != null) 'Kademe ${next.tier} açılır · ${next.course.name}',
    if (s.unlocks != null) '${s.unlocks!.plural} açılır',
  ];
}

/// Round, raised marker of a training stage, like a level button on a game
/// map. Fill, icon and text all change with the status, so color is never
/// the only signal.
class StageNode extends StatelessWidget {
  const StageNode({
    super.key,
    required this.status,
    required this.tier,
    this.size = 52,
  });

  final StageStatus status;
  final int tier;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final game = GameColors.of(context);
    final (Color face, Color fg, Color lip) = switch (status) {
      StageStatus.done => (cs.secondary, cs.onSecondary, game.secondaryLip),
      StageStatus.running ||
      StageStatus.available => (cs.primary, cs.onPrimary, game.primaryLip),
      StageStatus.locked => (
        game.lockedFace,
        cs.onSurfaceVariant,
        game.lockedLip,
      ),
    };
    final depth = size * 0.08;
    final iconSize = size * 0.5;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        margin: EdgeInsets.only(bottom: depth),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.3, -0.5),
            radius: 0.9,
            colors: [Color.lerp(face, Colors.white, 0.25)!, face],
          ),
          boxShadow: [
            BoxShadow(color: lip, offset: Offset(0, depth)),
            // The next stage glows.
            if (status == StageStatus.available)
              BoxShadow(
                color: cs.primary.withValues(alpha: 0.35),
                spreadRadius: size * 0.12,
              ),
          ],
        ),
        child: switch (status) {
          StageStatus.done => Icon(
            Icons.check_rounded,
            size: iconSize,
            color: fg,
          ),
          StageStatus.running => Icon(
            Icons.directions_walk_rounded,
            size: iconSize,
            color: fg,
          ),
          StageStatus.locked => Icon(
            Icons.lock_rounded,
            size: iconSize * 0.85,
            color: fg,
          ),
          StageStatus.available => Text(
            '$tier',
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(color: fg, height: 1, fontSize: size * 0.48),
          ),
        },
      ),
    );
  }
}

/// Header of the ladder: the mascot, how far the player got, and one pip per
/// stage.
class TrainingHeader extends StatelessWidget {
  const TrainingHeader({super.key, required this.game});
  final GameController game;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final done = game.stagesDone;
    final total = trainingStages.length;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.s16, bottom: AppSpace.s16),
      child: ClayCard(
        color: cs.primaryContainer,
        borderColor: cs.primary.withValues(alpha: 0.35),
        padding: const EdgeInsets.fromLTRB(
          AppSpace.s8,
          AppSpace.s12,
          AppSpace.s16,
          AppSpace.s16,
        ),
        child: Row(
          children: [
            Mascot(size: 84, pose: MascotPose.walk, look: MascotLook.of(game)),
            const SizedBox(width: AppSpace.s8),
            Expanded(
              child: Semantics(
                header: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hazırlık',
                      style: t.headlineSmall?.copyWith(
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      'Kademeleri bitir, yarışları aç!',
                      style: t.bodyMedium?.copyWith(
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: AppSpace.s8),
                    MergeSemantics(
                      child: Row(
                        children: [
                          for (var i = 0; i < total; i++) ...[
                            if (i > 0) const SizedBox(width: AppSpace.s4),
                            Expanded(child: _Pip(filled: i < done)),
                          ],
                          const SizedBox(width: AppSpace.s8),
                          Text(
                            '$done/$total',
                            style: tabular(t.labelLarge)
                                ?.copyWith(color: cs.onPrimaryContainer),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pip extends StatelessWidget {
  const _Pip({required this.filled});
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 10,
      decoration: BoxDecoration(
        color: filled ? cs.secondary : cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: filled
              ? GameColors.of(context).secondaryLip
              : cs.primary.withValues(alpha: 0.35),
          width: kClayBorder,
        ),
      ),
    );
  }
}

/// The training ladder: raised stage nodes joined by a trail of footprints,
/// each with its card. Each stage is one tap target.
class TrainingPath extends StatelessWidget {
  const TrainingPath({super.key, required this.game, required this.onOpen});

  final GameController game;
  final void Function(TrainingStage stage) onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final s in trainingStages)
          _StageRow(
            game: game,
            stage: s,
            isLast: s == trainingStages.last,
            onTap: () => onOpen(s),
          ),
      ],
    );
  }
}

class _StageRow extends StatelessWidget {
  const _StageRow({
    required this.game,
    required this.stage,
    required this.isLast,
    required this.onTap,
  });

  final GameController game;
  final TrainingStage stage;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final colors = GameColors.of(context);
    final green = colors.accentText;
    final status = game.statusOfStage(stage);
    final c = stage.course;
    final done = status == StageStatus.done;
    final current =
        status == StageStatus.available || status == StageStatus.running;
    final locked = status == StageStatus.locked;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 60,
            child: Column(
              children: [
                const SizedBox(height: AppSpace.s12),
                StageNode(status: status, tier: stage.tier),
                if (!isLast)
                  Expanded(
                    child: CustomPaint(
                      painter: _FootprintsPainter(
                        color: done
                            ? cs.secondary
                            : cs.onSurfaceVariant.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.s8),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpace.s12),
              child: MergeSemantics(
                child: ClayCard(
                  onTap: onTap,
                  color: current
                      ? cs.surfaceContainerLow
                      : locked
                      ? cs.surfaceContainerHigh
                      : null,
                  borderColor: current ? cs.primary : null,
                  lipColor: current ? colors.primaryLip : null,
                  padding: const EdgeInsets.all(AppSpace.s12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trUpper('Kademe ${stage.tier}'),
                              style: t.labelSmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            Text(c.name, style: t.titleLarge),
                            Text(
                              '${formatKm(c.meters)} · ${c.weather.label} · '
                              '${c.terrain.label}',
                              style: t.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            if (stage.unlocks != null) ...[
                              const SizedBox(height: AppSpace.s8),
                              _Milestone(
                                text:
                                    '${stage.unlocks!.plural} '
                                    '${done ? 'açıldı' : 'açılır'}',
                                done: done,
                                green: green,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpace.s8),
                      _StageTrailing(game: game, stage: stage, status: status),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Kısa yarışlar açılır" with a little flag, or an open lock once done.
class _Milestone extends StatelessWidget {
  const _Milestone({
    required this.text,
    required this.done,
    required this.green,
  });

  final String text;
  final bool done;
  final Color green;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final color = done ? green : cs.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.s8,
        vertical: AppSpace.s4,
      ),
      decoration: BoxDecoration(
        color: done ? cs.secondaryContainer : cs.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Icon(
              done ? Icons.lock_open_rounded : Icons.emoji_events_rounded,
              size: AppIconSize.sm,
              color: done ? green : GameColors.of(context).primaryText,
            ),
          ),
          const SizedBox(width: AppSpace.s4),
          Flexible(
            child: Text(text, style: t.labelMedium?.copyWith(color: color)),
          ),
        ],
      ),
    );
  }
}

/// Footprints walking down from one stage node to the next.
class _FootprintsPainter extends CustomPainter {
  _FootprintsPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final cx = size.width / 2;
    var left = true;
    for (var y = 10.0; y + 10 < size.height; y += 15) {
      final c = Offset(cx + (left ? -5 : 5), y);
      canvas.drawOval(Rect.fromCenter(center: c, width: 6, height: 9), paint);
      canvas.drawCircle(c.translate(0, -7), 2.2, paint);
      left = !left;
    }
  }

  @override
  bool shouldRepaint(_FootprintsPainter old) => old.color != color;
}

class _StageTrailing extends StatelessWidget {
  const _StageTrailing({
    required this.game,
    required this.stage,
    required this.status,
  });

  final GameController game;
  final TrainingStage stage;
  final StageStatus status;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final colors = GameColors.of(context);
    return switch (status) {
      StageStatus.done => Text(
        'Tamamlandı',
        style: t.labelMedium?.copyWith(color: colors.accentText),
      ),
      StageStatus.running => Text(
        percent((game.raceProgress * 100).floor()),
        style: t.titleLarge?.copyWith(color: colors.primaryText),
      ),
      StageStatus.available => Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.s8,
              vertical: AppSpace.s4,
            ),
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              'Sırada',
              style: t.labelMedium?.copyWith(color: cs.onPrimary),
            ),
          ),
          const SizedBox(height: AppSpace.s8),
          CoinAmount(eco.trainingReward(stage.course), iconSize: 18),
        ],
      ),
      StageStatus.locked => Text(
        'Kilitli',
        style: t.labelMedium?.copyWith(color: cs.onSurfaceVariant),
      ),
    };
  }
}

/// Coins and unlocks a training stage gives on completion.
class StageRewards extends StatelessWidget {
  const StageRewards({super.key, required this.stage});
  final TrainingStage stage;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final green = GameColors.of(context).accentText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CoinAmount(
          eco.trainingReward(stage.course),
          signed: true,
          style: t.headlineSmall,
          iconSize: 28,
        ),
        for (final line in unlockLines(stage)) ...[
          const SizedBox(height: AppSpace.s8),
          Row(
            children: [
              ExcludeSemantics(
                child: Icon(
                  Icons.lock_open_rounded,
                  size: AppIconSize.sm,
                  color: green,
                ),
              ),
              const SizedBox(width: AppSpace.s8),
              Expanded(
                child: Text(line, style: t.labelLarge?.copyWith(color: green)),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
