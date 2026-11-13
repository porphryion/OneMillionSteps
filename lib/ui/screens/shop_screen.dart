import 'package:material_ui/material_ui.dart';

import '../../game/catalog.dart';
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

/// Tab 3: shoes and tracksuit sets.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key, required this.game});
  final GameController game;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  GearSlot _slot = GearSlot.shoes;

  GameController get game => widget.game;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: game,
      builder: (context, _) {
        final course = game.activeCourse;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Mağaza'),
            actions: [CoinBalance(game.state.coins)],
          ),
          body: ListView(
            padding: pagePadding(context),
            children: [
              _Wardrobe(game: game),
              const SizedBox(height: AppSpace.s16),
              SegmentedButton<GearSlot>(
                showSelectedIcon: false,
                segments: [
                  for (final s in GearSlot.values)
                    ButtonSegment(
                      value: s,
                      icon: Icon(gearSlotIcon(s)),
                      label: Text(s.label),
                    ),
                ],
                selected: {_slot},
                onSelectionChanged: (s) => setState(() => _slot = s.first),
              ),
              const SizedBox(height: AppSpace.s16),
              _ContextNote(course: course),
              const SizedBox(height: AppSpace.s12),
              for (final g in gearFor(_slot)) ...[
                _GearCard(
                  game: game,
                  gear: g,
                  course: course,
                  onBuy: () => _buy(context, g),
                ),
                const SizedBox(height: AppSpace.s12),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _buy(BuildContext context, GearDef g) async {
    final t = Theme.of(context).textTheme;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(g.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GearArt(g, size: 48),
                const SizedBox(width: AppSpace.s16),
                CoinAmount(g.price, style: t.titleLarge, iconSize: 24),
              ],
            ),
            const SizedBox(height: AppSpace.s16),
            const Text('Satın alınca hemen giyilir.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Vazgeç'),
          ),
          GameButton(
            onPressed: () => Navigator.pop(c, true),
            label: 'Satın al',
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    if (game.buy(g)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('${g.name} giyildi.')));
    }
  }
}

class _ContextNote extends StatelessWidget {
  const _ContextNote({required this.course});
  final Course? course;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final c = course;
    return Container(
      padding: const EdgeInsets.all(AppSpace.s12),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IconBubble(Icons.bolt_rounded),
          const SizedBox(width: AppSpace.s8),
          Expanded(
            child: Text(
              c == null
                  ? 'Bir yarışa katıldığında, hangi ekipmanın o parkurda seni '
                        'hızlandıracağını burada görürsün.'
                  : 'Şu anki parkurun: ${c.name} · ${c.weather.label} · '
                        '${c.terrain.label}. Uyan bonuslar yeşil.',
              style: t.bodyMedium?.copyWith(color: cs.onPrimaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

/// The mascot in the equipped shoes and tracksuit.
class _Wardrobe extends StatelessWidget {
  const _Wardrobe({required this.game});
  final GameController game;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return ClayCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.s8,
        AppSpace.s8,
        AppSpace.s16,
        AppSpace.s12,
      ),
      child: Row(
        children: [
          Mascot(
            size: 96,
            pose: MascotPose.cheer,
            look: MascotLook.of(game),
            // Cheers again whenever the outfit changes.
            playKey: game.equippedGear.map((g) => g.id).join(),
          ),
          const SizedBox(width: AppSpace.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Karakterin', style: t.titleLarge),
                const SizedBox(height: AppSpace.s4),
                for (final slot in GearSlot.values)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpace.s4),
                    child: MergeSemantics(
                      child: Row(
                        children: [
                          GearArt(game.equippedIn(slot), size: 28),
                          const SizedBox(width: AppSpace.s8),
                          Expanded(
                            child: Text(
                              game.equippedIn(slot).name,
                              style: t.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GearCard extends StatelessWidget {
  const _GearCard({
    required this.game,
    required this.gear,
    required this.course,
    required this.onBuy,
  });

  final GameController game;
  final GearDef gear;
  final Course? course;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final c = course;
    final chips = <Widget>[
      if (gear.basePct > 0)
        ConditionChip(
          icon: Icons.bolt_rounded,
          label: 'Her parkur',
          semanticKind: 'Genel',
          bonus: gear.basePct,
          highlight: c != null,
        ),
      for (final e in gear.weatherPct.entries)
        ConditionChip(
          icon: weatherIcon(e.key),
          label: e.key.label,
          semanticKind: 'Hava',
          bonus: e.value,
          highlight: c?.weather == e.key,
        ),
      for (final e in gear.terrainPct.entries)
        ConditionChip(
          icon: terrainIcon(e.key),
          label: e.key.label,
          semanticKind: 'Zemin',
          bonus: e.value,
          highlight: c?.terrain == e.key,
        ),
    ];

    return ClayCard(
      padding: const EdgeInsets.all(AppSpace.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GearArt(gear),
              const SizedBox(width: AppSpace.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(gear.name, style: t.titleMedium),
                    const SizedBox(height: AppSpace.s4),
                    Text(
                      gear.blurb,
                      style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s12),
          if (chips.isEmpty)
            Text(
              'Bonus yok',
              style: t.labelMedium?.copyWith(color: cs.onSurfaceVariant),
            )
          else
            Wrap(
              spacing: AppSpace.s8,
              runSpacing: AppSpace.s8,
              children: chips,
            ),
          if (c != null && gear.bonusFor(c) > 0) ...[
            const SizedBox(height: AppSpace.s8),
            Text(
              'Şu anki parkurunda ${bonusPercent(gear.bonusFor(c))}',
              style: t.labelLarge?.copyWith(
                color: GameColors.of(context).accentText,
              ),
            ),
          ],
          const SizedBox(height: AppSpace.s16),
          _action(context),
        ],
      ),
    );
  }

  Widget _action(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    if (game.isEquipped(gear)) {
      return const SizedBox(
        width: double.infinity,
        child: GameButton(
          onPressed: null,
          icon: Icons.check_rounded,
          label: 'Giyili',
        ),
      );
    }
    if (game.owns(gear)) {
      return SizedBox(
        width: double.infinity,
        child: GameButton(
          tone: ButtonTone.neutral,
          onPressed: () => game.equip(gear),
          label: 'Giy',
        ),
      );
    }
    final short = gear.price - game.state.coins;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GameButton(
          onPressed: short > 0 ? null : onBuy,
          child: Semantics(
            label: 'Satın al, ${groupThousands(gear.price)} coin',
            excludeSemantics: true,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Satın al'),
                const SizedBox(width: AppSpace.s12),
                // Text inherits the button color so disabled looks disabled.
                Opacity(
                  opacity: short > 0 ? 0.5 : 1,
                  child: const CoinIcon(size: 18),
                ),
                const SizedBox(width: AppSpace.s4),
                Text(
                  groupThousands(gear.price),
                  style: const TextStyle(
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (short > 0) ...[
          const SizedBox(height: AppSpace.s4),
          Text(
            '${groupThousands(short)} coin daha gerekiyor',
            textAlign: TextAlign.center,
            style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}
