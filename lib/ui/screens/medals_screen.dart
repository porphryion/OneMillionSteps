import 'package:material_ui/material_ui.dart';

import '../../game/game_controller.dart';
import '../../game/game_state.dart';
import '../../game/models.dart';
import '../format.dart';
import '../theme/tokens.dart';
import '../widgets/badges.dart';
import '../widgets/clay.dart';
import '../widgets/common.dart';
import '../widgets/mascot.dart';

/// Tab 4: medal collection, totals and race history.
class MedalsScreen extends StatelessWidget {
  const MedalsScreen({super.key, required this.game, required this.onBrowse});

  final GameController game;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: game,
      builder: (context, _) {
        // Training walks have their own ladder; this is the race record.
        final results = game.state.results.where((r) => !r.isTraining).toList();
        final finished = results
            .where((r) => r.outcome == RaceOutcome.finished)
            .toList();
        final raced = results.fold(0.0, (sum, r) => sum + r.meters);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Madalyalar'),
            actions: [CoinBalance(game.state.coins)],
          ),
          body: ListView(
            padding: pagePadding(context),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final m in Medal.values) ...[
                    if (m != Medal.values.first)
                      const SizedBox(width: AppSpace.s8),
                    Expanded(
                      child: _MedalCount(
                        medal: m,
                        count: finished.where((r) => r.medal == m).length,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpace.s8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: StatTile(
                      label: 'Biten yarış',
                      value: '${finished.length}',
                    ),
                  ),
                  const SizedBox(width: AppSpace.s8),
                  Expanded(
                    child: StatTile(
                      label: 'Yarış mesafesi',
                      value: formatKm(raced),
                    ),
                  ),
                  const SizedBox(width: AppSpace.s8),
                  Expanded(
                    child: StatTile(
                      label: 'Toplam adım',
                      value: groupThousands(game.state.lifetimeSteps),
                    ),
                  ),
                ],
              ),
              const SectionHeader('Geçmiş'),
              if (results.isEmpty)
                EmptyState(
                  look: MascotLook.of(game),
                  title: 'Henüz madalyan yok',
                  body: game.trainingComplete
                      ? 'İlk maratonunu bitir, madalyan burada parlasın.'
                      : 'Hazırlık kademeleri yarışların kilidini açar. '
                            'İlk yarışını bitir, madalyan burada parlasın.',
                  action: GameButton(
                    onPressed: onBrowse,
                    icon: Icons.flag_rounded,
                    label: 'Maratonlara göz at',
                  ),
                )
              else
                for (final r in results.reversed) ...[
                  _ResultTile(r),
                  const SizedBox(height: AppSpace.s8),
                ],
            ],
          ),
        );
      },
    );
  }
}

class _MedalCount extends StatelessWidget {
  const _MedalCount({required this.medal, required this.count});

  final Medal medal;
  final int count;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return MergeSemantics(
      child: ClayCard(
        padding: const EdgeInsets.all(AppSpace.s12),
        child: Column(
          children: [
            MedalBadge(medal, size: 44),
            const SizedBox(height: AppSpace.s8),
            Text('$count', style: tabular(t.titleLarge)),
            Text(
              medal.label,
              style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile(this.r);
  final RaceResult r;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final medal = r.medal;
    final detail = switch (r.outcome) {
      RaceOutcome.finished => '${formatKm(r.meters)} · ${r.daysUsed} gün',
      RaceOutcome.timeUp => 'Süre doldu · ${formatKm(r.meters)}',
      RaceOutcome.withdrew => 'Çekildin · ${formatKm(r.meters)}',
    };
    return ClayCard(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpace.s16,
          vertical: AppSpace.s4,
        ),
        leading: medal != null
            ? MedalBadge(medal, size: 40)
            : Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.flag_outlined, color: cs.onSurfaceVariant),
              ),
        title: Text(r.course.name),
        subtitle: Text('$detail · ${dayMonth(r.endedAt)}'),
        trailing: r.coins > 0 ? CoinAmount(r.coins, signed: true) : null,
      ),
    );
  }
}
