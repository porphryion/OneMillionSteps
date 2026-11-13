import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../game/game_controller.dart';
import '../../game/models.dart';
import '../theme/game_palette.dart';
import '../theme/tokens.dart';

enum MascotPose { idle, walk, cheer }

/// What the mascot wears: the equipped shoes' and outfit's tints.
class MascotLook {
  const MascotLook({required this.shoes, required this.band});

  final Color shoes;
  final Color band;

  static const starter = MascotLook(
    shoes: Palette.tintSlate,
    band: Palette.tintSlate,
  );

  static MascotLook of(GameController game) => MascotLook(
    shoes: gearTint(game.equippedIn(GearSlot.shoes).tint),
    band: gearTint(game.equippedIn(GearSlot.outfit).tint),
  );
}

/// The game's round, orange walker. Decorative: excluded from semantics.
///
/// Walk and cheer poses play a few cycles, then rest. Changing [playKey]
/// plays them again (pass the race progress so new steps make it walk).
/// With animations turned off it stays still.
class Mascot extends StatefulWidget {
  const Mascot({
    super.key,
    this.size = 96,
    this.pose = MascotPose.idle,
    this.look = MascotLook.starter,
    this.playKey,
  });

  final double size;
  final MascotPose pose;
  final MascotLook look;
  final Object? playKey;

  @override
  State<Mascot> createState() => _MascotState();
}

class _MascotState extends State<Mascot> with SingleTickerProviderStateMixin {
  static const _cycles = 3;
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppMotion.stride,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _play();
  }

  @override
  void didUpdateWidget(Mascot old) {
    super.didUpdateWidget(old);
    if (old.playKey != widget.playKey || old.pose != widget.pose) _play();
  }

  void _play() {
    if (widget.pose == MascotPose.idle || AppMotion.reduced(context)) {
      _c.value = 0;
      return;
    }
    _c.repeat(count: _cycles);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.square(widget.size),
          painter: _MascotPainter(
            phase: _c,
            pose: widget.pose,
            look: widget.look,
            shadow: Colors.black.withValues(alpha: dark ? 0.35 : 0.12),
          ),
        ),
      ),
    );
  }
}

class _MascotPainter extends CustomPainter {
  _MascotPainter({
    required this.phase,
    required this.pose,
    required this.look,
    required this.shadow,
  }) : super(repaint: phase);

  final Animation<double> phase;
  final MascotPose pose;
  final MascotLook look;
  final Color shadow;

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 100;
    final t = phase.value * 2 * math.pi;
    final walking = pose == MascotPose.walk;
    final cheering = pose == MascotPose.cheer;

    final bob = walking
        ? math.sin(t * 2).abs() * 2.5 * u
        : cheering
        ? math.sin(t).abs() * 9 * u
        : 0.0;
    final cy = 50 * u - bob;

    // Ground shadow shrinks while jumping.
    final shadowW = (52 - bob / u * 1.5) * u;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(50 * u, 94 * u),
        width: shadowW,
        height: 7 * u,
      ),
      Paint()..color = shadow,
    );

    // Feet: alternate while walking, together while cheering.
    // Both are zero at rest (t = 0), so the mascot stops on both feet.
    final swing = walking ? math.sin(t) : 0.0;
    final lift = swing;
    final leftFoot = Offset(
      40 * u + swing * 6 * u,
      86 * u - math.max(0, lift) * 4 * u - (cheering ? bob : 0),
    );
    final rightFoot = Offset(
      60 * u - swing * 6 * u,
      86 * u - math.max(0, -lift) * 4 * u - (cheering ? bob : 0),
    );

    final limb = Paint()
      ..color = MascotPalette.bodyShade
      ..strokeWidth = 6 * u
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(43 * u, cy + 24 * u),
      leftFoot.translate(0, -4 * u),
      limb,
    );
    canvas.drawLine(
      Offset(57 * u, cy + 24 * u),
      rightFoot.translate(0, -4 * u),
      limb,
    );
    paintSneaker(canvas, leftFoot, 20 * u, look.shoes);
    paintSneaker(canvas, rightFoot, 20 * u, look.shoes);

    // Arms.
    if (cheering) {
      final wave = math.sin(t * 2) * 3 * u;
      canvas.drawLine(
        Offset(24 * u, cy - 2 * u),
        Offset(11 * u, cy - 22 * u + wave),
        limb,
      );
      canvas.drawLine(
        Offset(76 * u, cy - 2 * u),
        Offset(89 * u, cy - 22 * u - wave),
        limb,
      );
    } else {
      final arm = swing * 5 * u;
      canvas.drawLine(
        Offset(21 * u, cy + 2 * u),
        Offset(15 * u - arm, cy + 14 * u),
        limb,
      );
      canvas.drawLine(
        Offset(79 * u, cy + 2 * u),
        Offset(85 * u + arm, cy + 14 * u),
        limb,
      );
    }

    // Body: a soft round blob lit from the top left.
    final body = Rect.fromCenter(
      center: Offset(50 * u, cy),
      width: 64 * u,
      height: 60 * u,
    );
    canvas.drawOval(
      body,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.45),
          radius: 0.95,
          colors: [
            MascotPalette.bodyGlow,
            MascotPalette.body,
            MascotPalette.bodyShade,
          ],
          stops: [0, 0.6, 1],
        ).createShader(body),
    );

    // Headband with two tails.
    canvas.save();
    canvas.clipPath(Path()..addOval(body));
    canvas.drawRect(
      Rect.fromLTWH(body.left, cy - 21 * u, body.width, 7 * u),
      Paint()..color = look.band,
    );
    canvas.restore();
    final tail = Paint()
      ..color = look.band
      ..strokeWidth = 4.5 * u
      ..strokeCap = StrokeCap.round;
    final knot = Offset(80 * u, cy - 16 * u);
    canvas.drawLine(knot, knot.translate(9 * u, -3 * u + bob * 0.3), tail);
    canvas.drawLine(knot, knot.translate(8 * u, 5 * u + bob * 0.3), tail);

    // Face.
    final ink = Paint()..color = MascotPalette.face;
    final eyeY = cy + 1 * u;
    if (cheering) {
      final happy = Paint()
        ..color = MascotPalette.face
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * u
        ..strokeCap = StrokeCap.round;
      for (final x in [40 * u, 60 * u]) {
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(x, eyeY + 2 * u),
            width: 10 * u,
            height: 9 * u,
          ),
          math.pi,
          math.pi,
          false,
          happy,
        );
      }
    } else {
      for (final x in [40 * u, 60 * u]) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(x, eyeY),
            width: 9 * u,
            height: 12 * u,
          ),
          ink,
        );
        canvas.drawCircle(
          Offset(x + 1.4 * u, eyeY - 2.4 * u),
          1.8 * u,
          Paint()..color = Colors.white,
        );
      }
    }

    final blush = Paint()..color = MascotPalette.blush.withValues(alpha: 0.75);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(30 * u, cy + 9 * u),
        width: 10 * u,
        height: 6 * u,
      ),
      blush,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(70 * u, cy + 9 * u),
        width: 10 * u,
        height: 6 * u,
      ),
      blush,
    );

    final mouthY = cy + 10 * u;
    if (cheering) {
      final mouth = Rect.fromCenter(
        center: Offset(50 * u, mouthY),
        width: 12 * u,
        height: 10 * u,
      );
      canvas.drawArc(mouth, 0, math.pi, true, ink);
    } else {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(50 * u, mouthY - 2 * u),
          width: 10 * u,
          height: 7 * u,
        ),
        0.15 * math.pi,
        0.7 * math.pi,
        false,
        Paint()
          ..color = MascotPalette.face
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.8 * u
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_MascotPainter old) =>
      old.pose != pose ||
      old.look.shoes != look.shoes ||
      old.look.band != look.band ||
      old.shadow != shadow;
}

/// A chunky sneaker pointing right, centered on [c] with width [w]: colored
/// upper, white sole, two white laces.
void paintSneaker(Canvas canvas, Offset c, double w, Color upper) {
  final h = w * 0.55;
  final top = c.dy - h / 2;
  final left = c.dx - w * 0.42;
  final shoe = Path()
    ..moveTo(left, c.dy + h * 0.32)
    ..lineTo(left, top + h * 0.25)
    ..quadraticBezierTo(left, top, left + w * 0.22, top)
    ..lineTo(left + w * 0.45, top)
    ..quadraticBezierTo(
      left + w * 0.55,
      top + h * 0.35,
      left + w * 0.75,
      top + h * 0.4,
    )
    ..quadraticBezierTo(left + w, top + h * 0.45, left + w, c.dy + h * 0.2)
    ..lineTo(left + w, c.dy + h * 0.32)
    ..close();
  canvas.drawPath(shoe, Paint()..color = upper);
  final sole = RRect.fromRectAndRadius(
    Rect.fromLTWH(left - w * 0.02, c.dy + h * 0.22, w * 1.04, h * 0.3),
    Radius.circular(h * 0.15),
  );
  canvas.drawRRect(sole, Paint()..color = MascotPalette.sole);
  final lace = Paint()
    ..color = MascotPalette.sole
    ..strokeWidth = math.max(1, w * 0.06)
    ..strokeCap = StrokeCap.round;
  for (final f in [0.48, 0.62]) {
    final x = left + w * f;
    canvas.drawLine(
      Offset(x, top + h * 0.28),
      Offset(x + w * 0.06, top + h * 0.44),
      lace,
    );
  }
}
