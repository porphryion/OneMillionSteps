import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../game/catalog.dart';
import '../../game/game_state.dart';
import '../../game/models.dart';
import '../format.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'badges.dart';
import 'clay.dart';
import 'mascot.dart';
import 'training_path.dart';

/// Shows how a race ended: medal and coins, or that time ran out.
Future<void> showRaceResultDialog(
  BuildContext context,
  RaceResult r, {
  MascotLook look = MascotLook.starter,
}) {
  if (r.outcome == RaceOutcome.finished) HapticFeedback.mediumImpact();
  return showDialog<void>(
    context: context,
    builder: (_) => _RaceResultDialog(r, look),
  );
}

class _RaceResultDialog extends StatelessWidget {
  const _RaceResultDialog(this.result, this.look);
  final RaceResult result;
  final MascotLook look;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final medal = result.medal;
    final finished = result.outcome == RaceOutcome.finished;
    final stage = stageByCourseId[result.courseId];

    Widget reveal(Widget child) => TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1),
      duration: AppMotion.of(context, AppMotion.celebrate),
      curve: AppMotion.reward,
      builder: (context, s, child) => Transform.scale(scale: s, child: child),
      child: child,
    );

    if (finished && stage != null) return _stageDone(context, stage, reveal);

    return AlertDialog(
      icon: finished && medal != null
          ? _Burst(child: reveal(MedalBadge(medal, size: 96)))
          : Icon(
              Icons.timer_off_rounded,
              size: AppIconSize.xl,
              color: cs.onSurfaceVariant,
            ),
      title: Text(
        finished ? 'Bitiş çizgisi!' : 'Süre doldu',
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            result.course.name,
            style: t.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpace.s8),
          if (finished && medal != null) ...[
            Text(
              '${medal.label} madalya · ${result.daysUsed} günde',
              style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpace.s16),
            CoinAmount(
              result.coins,
              signed: true,
              iconSize: 28,
              style: t.headlineSmall,
            ),
          ] else
            Text(
              '${formatKm(result.meters)} koştun. '
              'Bu haftanın maratonları seni bekliyor.',
              style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        GameButton(
          onPressed: () => Navigator.pop(context),
          label: finished ? 'Harika!' : 'Tamam',
        ),
      ],
    );
  }

  /// A training stage is done: coins plus what it opened.
  Widget _stageDone(
    BuildContext context,
    TrainingStage stage,
    Widget Function(Widget) reveal,
  ) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final green = GameColors.of(context).accentText;
    return AlertDialog(
      icon: _Burst(
        child: reveal(Mascot(size: 120, pose: MascotPose.cheer, look: look)),
      ),
      title: const Text('Kademe tamamlandı!', textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            stage.course.name,
            style: t.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpace.s8),
          Text(
            'Kademe ${stage.tier} · ${result.daysUsed} günde',
            style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpace.s16),
          CoinAmount(
            result.coins,
            signed: true,
            iconSize: 28,
            style: t.headlineSmall,
          ),
          for (final line in unlockLines(stage)) ...[
            const SizedBox(height: AppSpace.s8),
            Text(
              line,
              textAlign: TextAlign.center,
              style: t.labelLarge?.copyWith(color: green),
            ),
          ],
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        GameButton(onPressed: () => Navigator.pop(context), label: 'Devam'),
      ],
    );
  }
}

/// Soft sun rays behind a reward. Decorative.
class _Burst extends StatelessWidget {
  const _Burst({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: 168,
      height: 136,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          ExcludeSemantics(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: -0.4, end: 0),
              duration: AppMotion.of(context, AppMotion.celebrate),
              curve: AppMotion.enter,
              builder: (context, a, _) => Transform.rotate(
                angle: a,
                child: CustomPaint(
                  size: const Size.square(168),
                  painter: _BurstPainter(color),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  _BurstPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: 0.4), color.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    const rays = 12;
    for (var i = 0; i < rays; i++) {
      final a = i * 2 * math.pi / rays;
      const half = math.pi / rays / 2;
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy)
          ..lineTo(c.dx + r * math.cos(a - half), c.dy + r * math.sin(a - half))
          ..lineTo(c.dx + r * math.cos(a + half), c.dy + r * math.sin(a + half))
          ..close(),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.color != color;
}
