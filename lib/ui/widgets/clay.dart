import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// A raised, toy-like surface: a face with a 2 px border sitting on a darker
/// lip. With [onTap] the face sinks onto the lip while pressed.
class ClayCard extends StatefulWidget {
  const ClayCard({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.lipColor,
    this.borderColor,
    this.radius = AppRadius.lg,
    this.depth = AppDepth.card,
    this.padding,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// Face color. Defaults to `colorScheme.surfaceContainerLow`.
  final Color? color;
  final Color? lipColor;
  final Color? borderColor;
  final double radius;
  final double depth;
  final EdgeInsetsGeometry? padding;

  @override
  State<ClayCard> createState() => _ClayCardState();
}

class _ClayCardState extends State<ClayCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final game = GameColors.of(context);
    final cs = Theme.of(context).colorScheme;
    final r = BorderRadius.circular(widget.radius);
    final sink = _down ? widget.depth : 0.0;

    Widget content = widget.padding == null
        ? widget.child
        : Padding(padding: widget.padding!, child: widget.child);
    if (widget.onTap != null) {
      content = InkWell(
        onTap: widget.onTap,
        onHighlightChanged: (v) => setState(() => _down = v),
        child: content,
      );
    }

    return AnimatedContainer(
      duration: AppMotion.of(context, AppMotion.press),
      curve: AppMotion.enter,
      margin: EdgeInsets.only(top: sink, bottom: widget.depth - sink),
      decoration: BoxDecoration(
        color: widget.color ?? cs.surfaceContainerLow,
        borderRadius: r,
        boxShadow: [
          BoxShadow(
            color: widget.lipColor ?? game.lip,
            offset: Offset(0, widget.depth - sink),
          ),
        ],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: r,
        border: Border.all(
          color: widget.borderColor ?? game.line,
          width: kClayBorder,
        ),
      ),
      child: ClipRRect(
        borderRadius: r,
        child: Material(type: MaterialType.transparency, child: content),
      ),
    );
  }
}

enum ButtonTone { primary, success, danger, neutral }

/// Chunky game button: a colored face on a darker lip that sinks when
/// pressed. Disabled buttons turn flat beige.
class GameButton extends StatefulWidget {
  const GameButton({
    super.key,
    this.label,
    this.child,
    required this.onPressed,
    this.icon,
    this.tone = ButtonTone.primary,
  }) : assert((label == null) != (child == null));

  final String? label;

  /// Custom content instead of [label].
  final Widget? child;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ButtonTone tone;

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> {
  final _states = WidgetStatesController();
  bool _down = false;

  @override
  void initState() {
    super.initState();
    _states.addListener(() {
      final down = _states.value.contains(WidgetState.pressed);
      if (down != _down) setState(() => _down = down);
    });
  }

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final game = GameColors.of(context);
    final enabled = widget.onPressed != null;
    final (Color face, Color fg, Color lip) = !enabled
        ? (game.lockedFace, cs.onSurfaceVariant, game.lockedLip)
        : switch (widget.tone) {
            ButtonTone.primary => (cs.primary, cs.onPrimary, game.primaryLip),
            ButtonTone.success => (
              cs.secondary,
              cs.onSecondary,
              game.secondaryLip,
            ),
            ButtonTone.danger => (cs.error, cs.onError, game.dangerLip),
            ButtonTone.neutral => (
              cs.surfaceContainerHigh,
              cs.onSurface,
              game.lip,
            ),
          };
    const depth = AppDepth.button;
    final sink = _down && enabled ? depth : 0.0;
    final r = BorderRadius.circular(AppRadius.md);

    final label =
        widget.child ?? Text(widget.label!, textAlign: TextAlign.center);
    final content = widget.icon == null
        ? label
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: AppIconSize.md),
              const SizedBox(width: AppSpace.s8),
              Flexible(child: label),
            ],
          );

    return AnimatedContainer(
      duration: AppMotion.of(context, AppMotion.press),
      curve: AppMotion.enter,
      margin: EdgeInsets.only(top: sink, bottom: depth - sink),
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: [BoxShadow(color: lip, offset: Offset(0, depth - sink))],
      ),
      child: FilledButton(
        statesController: _states,
        onPressed: enabled
            ? () {
                HapticFeedback.lightImpact();
                widget.onPressed!();
              }
            : null,
        style: FilledButton.styleFrom(
          backgroundColor: face,
          foregroundColor: fg,
          disabledBackgroundColor: face,
          disabledForegroundColor: fg,
          minimumSize: const Size(64, AppLayout.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.s24),
          elevation: 0,
          textStyle: buttonTextStyle,
          shape: RoundedRectangleBorder(
            borderRadius: r,
            side: widget.tone == ButtonTone.neutral && enabled
                ? BorderSide(color: game.line, width: kClayBorder)
                : BorderSide.none,
          ),
        ),
        child: content,
      ),
    );
  }
}

/// Small raised pill for the app bar (coin balance and the like).
class HudPill extends StatelessWidget {
  const HudPill({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ClayCard(
    radius: AppRadius.pill,
    depth: AppDepth.chip + 1,
    padding: const EdgeInsets.fromLTRB(
      AppSpace.s8,
      AppSpace.s4,
      AppSpace.s12,
      AppSpace.s4,
    ),
    child: child,
  );
}
