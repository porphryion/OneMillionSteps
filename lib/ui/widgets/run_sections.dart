import 'package:material_ui/material_ui.dart';

import '../../game/game_controller.dart';
import '../../game/models.dart';
import '../format.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'clay.dart';
import 'common.dart';
import 'conditions.dart';
import 'race_widgets.dart';

/// Distance, time, weather and terrain as a 2×2 grid of tiles.
class CourseFacts extends StatelessWidget {
  const CourseFacts({super.key, required this.course, required this.timeValue});

  final Course course;

  /// Shown in the "Kapanış" tile ("5 gün kaldı", "Sınırsız" ...).
  final String timeValue;

  @override
  Widget build(BuildContext context) {
    Widget pair(Widget a, Widget b) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        const SizedBox(width: AppSpace.s8),
        Expanded(child: b),
      ],
    );
    return Column(
      children: [
        pair(
          StatTile(
            icon: Icons.straighten_rounded,
            label: 'Mesafe',
            value: formatKm(course.meters),
          ),
          StatTile(
            icon: Icons.schedule_rounded,
            label: 'Süre',
            value: timeValue,
          ),
        ),
        const SizedBox(height: AppSpace.s8),
        pair(
          StatTile(
            icon: weatherIcon(course.weather),
            label: 'Hava',
            value: course.weather.label,
          ),
          StatTile(
            icon: terrainIcon(course.terrain),
            label: 'Zemin',
            value: course.terrain.label,
          ),
        ),
      ],
    );
  }
}

/// "Bonusun" header with the total and one row per equipped item.
class GearBonusSection extends StatelessWidget {
  const GearBonusSection({super.key, required this.game, required this.course});

  final GameController game;
  final Course course;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final bonus = game.bonusFor(course);
    return Column(
      children: [
        SectionHeader(
          'Bonusun',
          subtitle: bonus > 0
              ? 'Giydiğin ekipman bu parkurda adımlarını uzatıyor.'
              : 'Bu parkura uygun ayakkabı ve eşofman takımıyla '
                    'daha hızlı ilerlersin.',
          trailing: BonusPill(bonus),
        ),
        for (final g in game.equippedGear) ...[
          MergeSemantics(
            child: Row(
              children: [
                GearArt(g, size: 40),
                const SizedBox(width: AppSpace.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(g.name, style: t.titleSmall),
                      Text(
                        g.slot.label,
                        style: t.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  g.bonusFor(course) > 0
                      ? bonusPercent(g.bonusFor(course))
                      : 'Bonus yok',
                  style: t.labelLarge?.copyWith(
                    color: g.bonusFor(course) > 0
                        ? GameColors.of(context).accentText
                        : cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s12),
        ],
      ],
    );
  }
}

/// Sticky bottom call to action with an optional reason above it.
class DetailCta extends StatelessWidget {
  const DetailCta({
    super.key,
    required this.label,
    this.onPressed,
    this.reason,
  });

  final String label;
  final VoidCallback? onPressed;

  /// Why the button is disabled, shown above it.
  final String? reason;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final pad = pagePadding(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          pad.left,
          AppSpace.s8,
          pad.right,
          AppSpace.s16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (reason != null) ...[
              Text(
                reason!,
                textAlign: TextAlign.center,
                style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpace.s8),
            ],
            GameButton(label: label, onPressed: onPressed),
          ],
        ),
      ),
    );
  }
}
