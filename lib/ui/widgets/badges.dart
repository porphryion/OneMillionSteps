import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../../game/models.dart';
import '../format.dart';
import '../theme/game_palette.dart';
import '../theme/tokens.dart';
import 'clay.dart';
import 'common.dart';

/// Shiny disc with a ring, a lip and a star glyph. Base of coins and medals.
class _Disc extends StatelessWidget {
  const _Disc({required this.colors, required this.size});

  final DiscColors colors;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        center: const Alignment(-0.35, -0.45),
        radius: 0.9,
        colors: [colors.shine, colors.fill],
      ),
      border: Border.all(color: colors.ring, width: max(1.5, size * 0.07)),
      boxShadow: [
        BoxShadow(color: colors.ring, offset: Offset(0, max(1, size * 0.06))),
      ],
    ),
    child: Icon(Icons.star_rounded, size: size * 0.58, color: colors.glyph),
  );
}

class CoinIcon extends StatelessWidget {
  const CoinIcon({super.key, this.size = 20});
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: _Disc(colors: coinColors, size: size),
  );
}

/// Coin disc and a number. [signed] prefixes rewards with "+".
class CoinAmount extends StatelessWidget {
  const CoinAmount(
    this.amount, {
    super.key,
    this.style,
    this.iconSize = 20,
    this.signed = false,
  });

  final int amount;
  final TextStyle? style;
  final double iconSize;
  final bool signed;

  @override
  Widget build(BuildContext context) {
    final text = '${signed ? '+' : ''}${groupThousands(amount)}';
    return Semantics(
      label: '$text coin',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CoinIcon(size: iconSize),
          const SizedBox(width: AppSpace.s4),
          Text(
            text,
            style: tabular(
              style ??
                  Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontSize: 18, height: 1.1),
            ),
          ),
        ],
      ),
    );
  }
}

/// Coin balance for app bars: a raised pill.
class CoinBalance extends StatelessWidget {
  const CoinBalance(this.coins, {super.key});
  final int coins;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Bakiye',
    child: Padding(
      padding: const EdgeInsets.only(right: AppSpace.s16),
      child: Center(
        child: HudPill(
          child: CoinAmount(
            coins,
            iconSize: 22,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(height: 1),
          ),
        ),
      ),
    ),
  );
}

class MedalBadge extends StatelessWidget {
  const MedalBadge(this.medal, {super.key, this.size = 40});

  final Medal medal;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '${medal.label} madalya',
    excludeSemantics: true,
    child: _Disc(colors: medalColors(medal), size: size),
  );
}
