import 'package:material_ui/material_ui.dart';

import '../../game/models.dart';
import '../format.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

const double _pillHeight = 32;

IconData weatherIcon(Weather w) => switch (w) {
  Weather.sunny => Icons.wb_sunny_rounded,
  Weather.hot => Icons.thermostat_rounded,
  Weather.rainy => Icons.water_drop_rounded,
  Weather.windy => Icons.air_rounded,
  Weather.cold => Icons.ac_unit_rounded,
};

IconData terrainIcon(Terrain t) => switch (t) {
  Terrain.asphalt => Icons.add_road_rounded,
  Terrain.trail => Icons.forest_rounded,
  Terrain.cobblestone => Icons.grid_view_rounded,
  Terrain.sand => Icons.beach_access_rounded,
  Terrain.mountain => Icons.landscape_rounded,
};

IconData gearSlotIcon(GearSlot s) => switch (s) {
  GearSlot.shoes => Icons.directions_run_rounded,
  GearSlot.outfit => Icons.checkroom_rounded,
};

/// Weather, terrain or bonus tag. [bonus] shows as "+%25" in green;
/// [highlight] adds a green border (the player's gear matches the race).
class ConditionChip extends StatelessWidget {
  const ConditionChip({
    super.key,
    required this.icon,
    required this.label,
    required this.semanticKind,
    this.bonus = 0,
    this.highlight = false,
  });

  ConditionChip.weather(Weather w, {Key? key, int bonus = 0})
    : this(
        key: key,
        icon: weatherIcon(w),
        label: w.label,
        semanticKind: 'Hava',
        bonus: bonus,
        highlight: bonus > 0,
      );

  ConditionChip.terrain(Terrain t, {Key? key, int bonus = 0})
    : this(
        key: key,
        icon: terrainIcon(t),
        label: t.label,
        semanticKind: 'Zemin',
        bonus: bonus,
        highlight: bonus > 0,
      );

  final IconData icon;
  final String label;
  final String semanticKind;
  final int bonus;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final game = GameColors.of(context);
    final green = game.accentText;
    final style = Theme.of(context).textTheme.labelMedium;
    return Semantics(
      label:
          '$semanticKind: $label'
          '${bonus > 0 ? ', bonus yüzde $bonus' : ''}',
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: AppMotion.of(context, AppMotion.fast),
        curve: AppMotion.enter,
        constraints: const BoxConstraints(minHeight: _pillHeight),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.s12,
          vertical: AppSpace.s4,
        ),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: highlight ? green : game.line,
            width: kClayBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: AppIconSize.sm,
              color: highlight ? green : cs.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpace.s4),
            Text(label, style: style),
            if (bonus > 0) ...[
              const SizedBox(width: AppSpace.s4),
              Text(
                bonusPercent(bonus),
                style: style?.copyWith(
                  color: green,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Total gear bonus on a race.
class BonusPill extends StatelessWidget {
  const BonusPill(this.pct, {super.key});
  final int pct;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final active = pct > 0;
    return Semantics(
      label: active ? 'Toplam ekipman bonusu yüzde $pct' : 'Ekipman bonusu yok',
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: _pillHeight),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.s12,
          vertical: AppSpace.s4,
        ),
        margin: const EdgeInsets.only(bottom: AppDepth.chip),
        decoration: BoxDecoration(
          color: active ? cs.secondary : cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: [
            BoxShadow(
              color: active
                  ? GameColors.of(context).secondaryLip
                  : GameColors.of(context).lip,
              offset: const Offset(0, AppDepth.chip),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bolt_rounded,
              size: AppIconSize.sm,
              color: active ? cs.onSecondary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpace.s4),
            Text(
              active ? bonusPercent(pct) : 'Bonus yok',
              style: t.labelMedium?.copyWith(
                color: active ? cs.onSecondary : cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
