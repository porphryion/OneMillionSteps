import 'package:material_ui/material_ui.dart';

import '../../game/config.dart';
import '../../game/game_controller.dart';
import '../../game/models.dart';
import '../format.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/badges.dart';
import '../widgets/common.dart';
import '../widgets/clay.dart';
import '../widgets/conditions.dart';
import '../widgets/mascot.dart';
import '../widgets/race_widgets.dart';
import '../widgets/training_path.dart';

/// Tab 1: the active race or training walk, or a nudge to start one.
class RaceScreen extends StatelessWidget {
  const RaceScreen({
    super.key,
    required this.game,
    required this.onSync,
    required this.onBrowse,
    required this.onShop,
    this.healthSteps = false,
  });

  final GameController game;

  /// Steps come from Apple Health.
  final bool healthSteps;
  final Future<void> Function() onSync;
  final VoidCallback onBrowse;
  final VoidCallback onShop;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: game,
      builder: (context, _) {
        final course = game.activeCourse;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Yarış'),
            actions: [
              IconButton(
                tooltip: 'Adımları güncelle',
                icon: const Icon(Icons.sync_rounded),
                onPressed: onSync,
              ),
              CoinBalance(game.state.coins),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: onSync,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: pagePadding(context, bottom: 168),
              children: [
                _TodayStrip(
                  steps: game.todaySteps,
                  date: game.now,
                  capped: game.dailyCapReached,
                  // Until the first real steps arrive, say where they come
                  // from and how to allow it.
                  healthHint: healthSteps && game.state.lifetimeSteps == 0,
                ),
                if (course == null)
                  _emptyState()
                else
                  ..._raceContent(context, course),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _emptyState() {
    if (game.trainingComplete) {
      return EmptyState(
        look: MascotLook.of(game),
        title: 'Aktif yarışın yok',
        body:
            'Bu haftanın maratonlarından birine katıl; '
            'attığın her adım seni bitiş çizgisine taşısın.',
        action: GameButton(
          onPressed: onBrowse,
          icon: Icons.flag_rounded,
          label: 'Maratonlara göz at',
        ),
      );
    }
    final started = game.stagesDone > 0;
    return EmptyState(
      look: MascotLook.of(game),
      title: started ? 'Hazırlığa devam!' : 'Maratona giden yol',
      body:
          'Kısa yürüyüşlerle başla. Her kademe bir sonrakini, '
          'sonra da haftanın yarışlarını açar.',
      action: GameButton(
        onPressed: onBrowse,
        icon: Icons.directions_walk_rounded,
        label: started ? 'Sıradaki kademe' : 'Hazırlığa başla',
      ),
    );
  }

  List<Widget> _raceContent(BuildContext context, Course course) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final event = game.raceEvent;
    final stage = game.activeStage;
    final race = game.race!;
    final parts = game.bonusParts(course);
    final bonus = game.bonusFor(course);

    return [
      const SizedBox(height: AppSpace.s16),
      ClayCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CourseBanner(course: course, borderRadius: BorderRadius.zero),
            Padding(
              padding: const EdgeInsets.all(AppSpace.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MergeSemantics(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          formatKmValue(race.meters),
                          style: tabular(t.displayLarge),
                        ),
                        const SizedBox(width: AppSpace.s8),
                        Flexible(
                          child: Text(
                            '/ ${formatKm(course.meters)}',
                            style: t.titleLarge?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.s4),
                  RaceTrack(
                    progress: game.raceProgress,
                    look: MascotLook.of(game),
                  ),
                  const SizedBox(height: AppSpace.s8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${percent((game.raceProgress * 100).floor())} '
                          'tamamlandı',
                          style: t.labelLarge,
                        ),
                      ),
                      ExcludeSemantics(
                        child: Icon(
                          Icons.schedule_rounded,
                          size: AppIconSize.sm,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: AppSpace.s4),
                      Text(
                        event != null
                            ? timeLeftLabel(game.daysLeft(event))
                            : 'Süre sınırı yok',
                        style: t.labelLarge,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpace.s12),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: StatTile(
              icon: Icons.directions_walk_rounded,
              label: 'Kalan adım',
              value: groupThousands(game.stepsToFinish),
            ),
          ),
          if (event != null) ...[
            const SizedBox(width: AppSpace.s8),
            Expanded(
              child: StatTile(
                icon: Icons.today_rounded,
                label: 'Günlük hedef',
                value: groupThousands(game.stepsPerDayNeeded(event)),
              ),
            ),
          ],
          const SizedBox(width: AppSpace.s8),
          Expanded(
            child: StatTile(
              icon: Icons.flag_rounded,
              label: event != null ? 'Yarış günü' : 'Yürüyüş günü',
              value: '${game.raceDay}',
            ),
          ),
        ],
      ),
      SectionHeader(
        'Koşullar ve bonus',
        subtitle: bonus > 0
            ? 'Ekipmanın bu parkurda adımlarını uzatıyor.'
            : 'Bu parkura uygun ekipmanla daha hızlı ilerlersin.',
      ),
      Wrap(
        spacing: AppSpace.s8,
        runSpacing: AppSpace.s8,
        children: [
          ConditionChip.weather(course.weather, bonus: parts.weather),
          ConditionChip.terrain(course.terrain, bonus: parts.terrain),
          if (parts.base > 0)
            ConditionChip(
              icon: Icons.bolt_rounded,
              label: 'Her parkur',
              semanticKind: 'Genel',
              bonus: parts.base,
              highlight: true,
            ),
          BonusPill(bonus),
        ],
      ),
      if (stage != null) ...[
        const SectionHeader('Ödül', subtitle: 'Bitirince kazanacakların.'),
        StageRewards(stage: stage),
      ] else ...[
        const SectionHeader(
          'Madalya hedefi',
          subtitle: 'Hızlı bitir, daha parlak madalya kazan.',
        ),
        MedalTargets(course: course, raceDay: game.raceDay),
      ],
      SectionHeader(
        'Ekipmanın',
        trailing: TextButton(onPressed: onShop, child: const Text('Değiştir')),
      ),
      for (final slot in GearSlot.values) ...[
        _EquippedRow(gear: game.equippedIn(slot), course: course),
        if (slot != GearSlot.values.last) const SizedBox(height: AppSpace.s12),
      ],
      const SizedBox(height: AppSpace.s32),
      Center(
        child: TextButton.icon(
          style: TextButton.styleFrom(foregroundColor: cs.error),
          onPressed: () => _confirmWithdraw(context, training: stage != null),
          icon: const Icon(Icons.logout_rounded),
          label: Text(stage != null ? 'Yürüyüşü bırak' : 'Yarıştan çekil'),
        ),
      ),
    ];
  }

  Future<void> _confirmWithdraw(
    BuildContext context, {
    required bool training,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(
          training ? 'Yürüyüş bırakılsın mı?' : 'Yarıştan çekilsin mi?',
        ),
        content: Text(
          training
              ? 'İlerlemen silinir. Bu kademeye istediğin zaman yeniden '
                    'başlayabilirsin.'
              : 'İlerlemen silinir. Bu parkura bu hafta tekrar katılamazsın.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Vazgeç'),
          ),
          GameButton(
            tone: ButtonTone.danger,
            onPressed: () => Navigator.pop(c, true),
            label: training ? 'Bırak' : 'Çekil',
          ),
        ],
      ),
    );
    if (ok == true) game.withdraw();
  }
}

/// Today's counted steps. Says so when the daily cap is full, because then
/// new steps do nothing until tomorrow.
class _TodayStrip extends StatelessWidget {
  const _TodayStrip({
    required this.steps,
    required this.date,
    required this.capped,
    this.healthHint = false,
  });

  final int steps;
  final DateTime date;
  final bool capped;
  final bool healthHint;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return MergeSemantics(
      child: ClayCard(
        padding: const EdgeInsets.all(AppSpace.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const IconBubble(Icons.directions_walk_rounded, size: 40),
                const SizedBox(width: AppSpace.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bugün', style: t.titleMedium),
                      Text(
                        dayMonth(date),
                        style: t.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(groupThousands(steps), style: tabular(t.headlineSmall)),
                const SizedBox(width: AppSpace.s4),
                Text('adım', style: t.titleMedium),
              ],
            ),
            if (capped) ...[
              const SizedBox(height: AppSpace.s8),
              _StripNote(
                icon: Icons.bedtime_rounded,
                text:
                    'Günlük ${groupThousands(Tuning.dailyStepCap)} adım '
                    'sınırı doldu. Yeni adımların yarın sayılır.',
              ),
            ],
            if (healthHint) ...[
              const SizedBox(height: AppSpace.s8),
              const _StripNote(
                icon: Icons.favorite_rounded,
                text:
                    'Adımların Sağlık uygulamasından gelir. Oyunu ilk '
                    'açtığın andan sonra attığın adımlar sayılır. Adım '
                    "görünmüyorsa Sağlık'ta bu oyuna adım okuma izni ver.",
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A soft orange note under today's steps.
class _StripNote extends StatelessWidget {
  const _StripNote({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.s12,
        vertical: AppSpace.s8,
      ),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          ExcludeSemantics(
            child: Icon(
              icon,
              size: AppIconSize.sm,
              color: GameColors.of(context).primaryText,
            ),
          ),
          const SizedBox(width: AppSpace.s8),
          Expanded(
            child: Text(
              text,
              style: t.labelMedium?.copyWith(color: cs.onPrimaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _EquippedRow extends StatelessWidget {
  const _EquippedRow({required this.gear, required this.course});

  final GearDef gear;
  final Course course;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final bonus = gear.bonusFor(course);
    return MergeSemantics(
      child: Row(
        children: [
          GearArt(gear, size: 40),
          const SizedBox(width: AppSpace.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(gear.name, style: t.titleSmall),
                Text(
                  gear.slot.label,
                  style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Text(
            bonus > 0 ? bonusPercent(bonus) : 'Bonus yok',
            style: t.labelLarge?.copyWith(
              color: bonus > 0
                  ? GameColors.of(context).accentText
                  : cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
