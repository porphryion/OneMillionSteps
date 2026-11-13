import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../game/catalog.dart';
import '../../game/economy.dart' as eco;
import '../../game/models.dart';
import '../format.dart';
import '../theme/app_theme.dart';
import '../theme/game_palette.dart';
import '../theme/tokens.dart';
import 'badges.dart';
import 'conditions.dart';
import 'mascot.dart';

/// Region-tinted block with a course's name: the race's identity. A strip
/// of scenery at the bottom shows the terrain and weather. Training walks use
/// the training color and show their tier.
class CourseBanner extends StatelessWidget {
  const CourseBanner({
    super.key,
    required this.course,
    this.large = false,
    this.locked = false,
    this.borderRadius,
  });

  final Course course;
  final bool large;

  /// Darkens the block and swaps the length pill for a lock.
  final bool locked;

  /// Defaults to all corners `xl`. Pass [BorderRadius.zero] inside a card.
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final tint = courseTint(course);
    final stage = stageByCourseId[course.id];
    final overline = course.region?.label ?? course.length.label;
    final tag = stage != null ? 'Kademe ${stage.tier}' : course.length.label;
    final pad = large ? AppSpace.s24 : AppSpace.s16;
    final scenery = large ? 56.0 : 44.0;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.xl),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(tint, Colors.white, 0.08)!, tint],
        ),
      ),
      child: Stack(
        children: [
          // Scenery sits below the text, so it never lowers text contrast.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: scenery,
            child: ExcludeSemantics(
              child: CustomPaint(
                painter: _SceneryPainter(
                  weather: course.weather,
                  terrain: course.terrain,
                ),
              ),
            ),
          ),
          if (locked)
            Positioned.fill(
              child: ColoredBox(color: Colors.black.withValues(alpha: 0.35)),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(pad, pad, pad, scenery),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        trUpper(overline),
                        style: t.labelSmall?.copyWith(color: onTint),
                      ),
                    ),
                    _TagPill(locked ? 'Kilitli' : tag, locked: locked),
                  ],
                ),
                const SizedBox(height: AppSpace.s4),
                Text(
                  course.name,
                  style: (large ? t.headlineLarge : t.headlineSmall)?.copyWith(
                    color: onTint,
                  ),
                ),
                Row(
                  children: [
                    const ExcludeSemantics(
                      child: Icon(
                        Icons.place_rounded,
                        size: AppIconSize.sm,
                        color: onTint,
                      ),
                    ),
                    const SizedBox(width: AppSpace.s4),
                    Text(
                      course.city,
                      style: t.bodyMedium?.copyWith(color: onTint),
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

class _TagPill extends StatelessWidget {
  const _TagPill(this.text, {this.locked = false});
  final String text;
  final bool locked;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpace.s12,
      vertical: AppSpace.s4,
    ),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      border: Border.all(
        color: onTint.withValues(alpha: 0.35),
        width: kClayBorder,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (locked) ...[
          const ExcludeSemantics(
            child: Icon(
              Icons.lock_rounded,
              size: AppIconSize.sm,
              color: onTint,
            ),
          ),
          const SizedBox(width: AppSpace.s4),
        ],
        Text(
          trUpper(text),
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: onTint),
        ),
      ],
    ),
  );
}

/// Bottom strip of a banner: terrain silhouettes and a weather mark.
class _SceneryPainter extends CustomPainter {
  _SceneryPainter({required this.weather, required this.terrain});

  final Weather weather;
  final Terrain terrain;

  static final _far = Paint()..color = Colors.white.withValues(alpha: 0.14);
  static final _near = Paint()..color = Colors.white.withValues(alpha: 0.24);
  static final _snow = Paint()..color = Colors.white.withValues(alpha: 0.7);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    _paintWeather(canvas, Offset(w - h * 1.4, h * 0.42), h);

    switch (terrain) {
      case Terrain.mountain:
        _peaks(canvas, w, h, [0.0, 0.22, 0.5, 0.78, 1.04], 0.15, _far);
        _peaks(
          canvas,
          w,
          h,
          [-0.1, 0.12, 0.36, 0.64, 0.9, 1.1],
          0.4,
          _near,
          snow: true,
        );
      case Terrain.sand:
        _waves(canvas, w, h, 0.45, 2, _far);
        _waves(canvas, w, h, 0.68, 1.5, _near);
      case Terrain.cobblestone:
        _waves(canvas, w, h, 0.55, 2, _far);
        _rooftops(canvas, w, h);
      case Terrain.asphalt:
        _waves(canvas, w, h, 0.4, 3, _far);
        _road(canvas, w, h);
      case Terrain.trail:
        _waves(canvas, w, h, 0.4, 3, _far);
        _trees(canvas, w, h);
        _waves(canvas, w, h, 0.72, 2.5, _near);
    }
  }

  void _paintWeather(Canvas canvas, Offset c, double h) {
    final r = h * 0.26;
    switch (weather) {
      case Weather.sunny || Weather.hot:
        final big = weather == Weather.hot;
        final rays = Paint()
          ..color = sunColor
          ..strokeWidth = r * 0.22
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          final d = Offset(math.cos(a), math.sin(a));
          canvas.drawLine(
            c + d * r * 1.35,
            c + d * r * (big ? 1.9 : 1.7),
            rays,
          );
        }
        canvas.drawCircle(c, big ? r * 1.15 : r, Paint()..color = sunColor);
      case Weather.rainy || Weather.cold:
        final cloud = Paint()..color = Colors.white.withValues(alpha: 0.85);
        canvas.drawCircle(c.translate(-r * 0.9, r * 0.2), r * 0.7, cloud);
        canvas.drawCircle(c, r, cloud);
        canvas.drawCircle(c.translate(r * 1.0, r * 0.25), r * 0.65, cloud);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(
              c.dx - r * 1.5,
              c.dy,
              c.dx + r * 1.6,
              c.dy + r * 0.85,
            ),
            Radius.circular(r * 0.4),
          ),
          cloud,
        );
        final drop = Paint()
          ..color = Colors.white.withValues(alpha: 0.75)
          ..strokeWidth = r * 0.2
          ..strokeCap = StrokeCap.round;
        for (final dx in [-0.8, 0.0, 0.8]) {
          final p = c.translate(r * dx, r * 1.3);
          if (weather == Weather.rainy) {
            canvas.drawLine(p, p.translate(-r * 0.15, r * 0.45), drop);
          } else {
            canvas.drawCircle(p.translate(0, r * 0.15), r * 0.14, drop);
          }
        }
      case Weather.windy:
        final gust = Paint()
          ..color = Colors.white.withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.22
          ..strokeCap = StrokeCap.round;
        for (final (dy, len) in [(-0.6, 2.2), (0.1, 2.8), (0.8, 1.8)]) {
          final y = c.dy + r * dy;
          final x0 = c.dx - r * 1.4;
          final x1 = x0 + r * len;
          canvas.drawPath(
            Path()
              ..moveTo(x0, y)
              ..lineTo(x1, y)
              ..arcToPoint(
                Offset(x1, y - r * 0.5),
                radius: Radius.circular(r * 0.25),
                clockwise: false,
              ),
            gust,
          );
        }
    }
  }

  /// Rolling hills: a sine band starting at [top] (fraction of h).
  void _waves(
    Canvas canvas,
    double w,
    double h,
    double top,
    double humps,
    Paint paint,
  ) {
    final path = Path()..moveTo(0, h);
    for (var x = 0.0; x <= w + 4; x += 4) {
      final y = h * top + math.sin(x / w * humps * 2 * math.pi) * h * 0.12;
      path.lineTo(x, y);
    }
    path
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _peaks(
    Canvas canvas,
    double w,
    double h,
    List<double> xs,
    double top,
    Paint paint, {
    bool snow = false,
  }) {
    for (var i = 0; i + 1 < xs.length; i++) {
      final l = xs[i] * w;
      final r = xs[i + 1] * w + w * 0.08;
      final peak = Offset((l + r) / 2, h * (top + (i.isEven ? 0.0 : 0.12)));
      canvas.drawPath(
        Path()
          ..moveTo(l, h)
          ..lineTo(peak.dx, peak.dy)
          ..lineTo(r, h)
          ..close(),
        paint,
      );
      if (snow) {
        const k = 0.28;
        final a = Offset.lerp(peak, Offset(l, h), k)!;
        final b = Offset.lerp(peak, Offset(r, h), k)!;
        canvas.drawPath(
          Path()
            ..moveTo(peak.dx, peak.dy)
            ..lineTo(a.dx, a.dy)
            ..lineTo(peak.dx, a.dy - h * 0.04)
            ..lineTo(b.dx, b.dy)
            ..close(),
          _snow,
        );
      }
    }
  }

  void _rooftops(Canvas canvas, double w, double h) {
    var x = w * 0.02;
    var i = 0;
    while (x < w) {
      final bw = h * (0.55 + (i % 3) * 0.15);
      final top = h * (0.45 + (i % 2) * 0.15);
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTRB(x, top, x + bw, h),
          topLeft: Radius.circular(bw * 0.15),
          topRight: Radius.circular(bw * 0.15),
        ),
        _near,
      );
      if (i % 4 == 1) {
        // A small dome and a slim tower.
        canvas.drawCircle(Offset(x + bw / 2, top), bw * 0.32, _near);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x + bw + h * 0.04, h * 0.18, h * 0.08, h * 0.82),
            Radius.circular(h * 0.04),
          ),
          _near,
        );
        x += h * 0.12;
      }
      x += bw + h * 0.12;
      i++;
    }
  }

  void _road(Canvas canvas, double w, double h) {
    final road = Rect.fromLTRB(0, h * 0.62, w, h);
    canvas.drawRect(road, _near);
    final dash = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = h * 0.06
      ..strokeCap = StrokeCap.round;
    for (var x = h * 0.3; x < w; x += h * 0.9) {
      canvas.drawLine(
        Offset(x, road.center.dy),
        Offset(x + h * 0.4, road.center.dy),
        dash,
      );
    }
  }

  void _trees(Canvas canvas, double w, double h) {
    for (var x = w * 0.06; x < w; x += h * 1.3) {
      final c = Offset(x, h * 0.48);
      canvas.drawRect(
        Rect.fromCenter(
          center: c.translate(0, h * 0.25),
          width: h * 0.07,
          height: h * 0.4,
        ),
        _near,
      );
      canvas.drawCircle(c, h * 0.2, _near);
    }
  }

  @override
  bool shouldRepaint(_SceneryPainter old) =>
      old.weather != weather || old.terrain != terrain;
}

/// Race progress as a little road: the filled part is orange, a checkered
/// line marks the finish and the mascot walks along it. Always pair it with a
/// text percentage.
class RaceTrack extends StatelessWidget {
  const RaceTrack({super.key, required this.progress, this.look});

  final double progress;

  /// The mascot's outfit. Without it a plain marker shows the position.
  final MascotLook? look;

  static const double _road = 20;
  static const double _mascot = 64;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final game = GameColors.of(context);
    final look = this.look;
    return Semantics(
      label: 'Yüzde ${(progress * 100).floor()} tamamlandı',
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: progress.clamp(0.0, 1.0)),
        duration: AppMotion.of(context, AppMotion.slow),
        curve: AppMotion.enter,
        builder: (context, value, _) => LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth;
            final x = _road / 2 + (w - _road * 1.5) * value;
            return SizedBox(
              height: look == null ? _road + 8 : _mascot + _road - 8,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: _road,
                    child: CustomPaint(
                      painter: _RoadPainter(
                        x: x,
                        road: game.track,
                        fill: cs.primary,
                        marker: look == null ? cs.primary : null,
                        cutout: cs.surfaceContainerLow,
                      ),
                    ),
                  ),
                  if (look != null)
                    Positioned(
                      left: (x - _mascot / 2).clamp(-8.0, w - _mascot + 8),
                      bottom: _road / 2 - 4,
                      child: Mascot(
                        size: _mascot,
                        pose: MascotPose.walk,
                        look: look,
                        playKey: progress,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RoadPainter extends CustomPainter {
  _RoadPainter({
    required this.x,
    required this.road,
    required this.fill,
    required this.marker,
    required this.cutout,
  });

  final double x;
  final Color road;
  final Color fill;
  final Color? marker;
  final Color cutout;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final r = Radius.circular(h / 2);
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(Offset.zero & size, r));
    canvas.drawRect(Offset.zero & size, Paint()..color = road);

    // Center dashes on the road still ahead.
    final dash = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var dx = x + 10; dx < size.width - h * 1.5; dx += 16) {
      canvas.drawLine(Offset(dx, h / 2), Offset(dx + 7, h / 2), dash);
    }

    // Checkered finish.
    final cell = h / 3;
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 2; col++) {
        canvas.drawRect(
          Rect.fromLTWH(
            size.width - h * 0.5 - cell * (2 - col),
            row * cell,
            cell,
            cell,
          ),
          Paint()
            ..color = (row + col).isEven
                ? Colors.white
                : Colors.black.withValues(alpha: 0.75),
        );
      }
    }

    // Covered distance, with a soft highlight along the top.
    if (x > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTRB(0, 0, x, h), r),
        Paint()..color = fill,
      );
      if (x > h * 0.9) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(h * 0.3, h * 0.18, x - h * 0.3, h * 0.38),
            Radius.circular(h * 0.1),
          ),
          Paint()..color = Colors.white.withValues(alpha: 0.3),
        );
      }
    }
    canvas.restore();

    if (marker != null) {
      canvas.drawCircle(Offset(x, h / 2), h * 0.7, Paint()..color = cutout);
      canvas.drawCircle(Offset(x, h / 2), h * 0.55, Paint()..color = marker!);
    }
  }

  @override
  bool shouldRepaint(_RoadPainter old) =>
      old.x != x ||
      old.road != road ||
      old.fill != fill ||
      old.marker != marker ||
      old.cutout != cutout;
}

/// Gear art tile: a raised tile in the item's tint with a sneaker or a
/// hanger.
class GearArt extends StatelessWidget {
  const GearArt(this.gear, {super.key, this.size = 56});

  final GearDef gear;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tint = gearTint(gear.tint);
    final depth = size >= 48 ? AppDepth.card : AppDepth.chip + 1;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        margin: EdgeInsets.only(bottom: depth),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.lerp(tint, Colors.white, 0.18)!, tint],
          ),
          borderRadius: BorderRadius.circular(size * 0.3),
          boxShadow: [
            BoxShadow(
              color: Color.lerp(tint, Colors.black, 0.35)!,
              offset: Offset(0, depth),
            ),
          ],
        ),
        child: gear.slot == GearSlot.shoes
            ? const CustomPaint(painter: _SneakerTilePainter())
            : Icon(gearSlotIcon(gear.slot), color: onTint, size: size * 0.55),
      ),
    );
  }
}

class _SneakerTilePainter extends CustomPainter {
  const _SneakerTilePainter();

  @override
  void paint(Canvas canvas, Size size) {
    paintSneaker(
      canvas,
      size.center(Offset(0, size.height * 0.04)),
      size.width * 0.72,
      Colors.white.withValues(alpha: 0.95),
    );
  }

  @override
  bool shouldRepaint(_SneakerTilePainter old) => false;
}

/// Medal tiers for a course: days allowed and coins. With [raceDay], tiers
/// already out of reach show as missed.
class MedalTargets extends StatelessWidget {
  const MedalTargets({super.key, required this.course, this.raceDay});

  final Course course;
  final int? raceDay;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      children: [
        for (final m in Medal.values) ...[
          if (m != Medal.values.first) const SizedBox(height: AppSpace.s12),
          Builder(
            builder: (context) {
              final days = switch (m) {
                Medal.gold => eco.goldDays(course),
                Medal.silver => eco.silverDays(course),
                Medal.bronze => null,
              };
              final missed = raceDay != null && days != null && raceDay! > days;
              return MergeSemantics(
                child: Row(
                  children: [
                    MedalBadge(m, size: 36),
                    const SizedBox(width: AppSpace.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${m.label} madalya', style: t.titleSmall),
                          Text(
                            days == null
                                ? 'Süre bitmeden bitir'
                                : '$days gün içinde bitir',
                            style: t.bodySmall?.copyWith(color: muted),
                          ),
                        ],
                      ),
                    ),
                    if (missed)
                      Text(
                        'Kaçtı',
                        style: t.labelMedium?.copyWith(color: muted),
                      )
                    else
                      CoinAmount(eco.rewardCoins(course, m)),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}
