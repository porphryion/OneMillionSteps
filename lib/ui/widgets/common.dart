import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'clay.dart';
import 'mascot.dart';

/// [style] with tabular figures, for numbers that change.
TextStyle? tabular(TextStyle? style) =>
    style?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

/// Page padding: 16 on phones, 24 on wide screens, content capped at 600.
EdgeInsets pagePadding(
  BuildContext context, {
  double top = AppSpace.s8,
  double bottom = AppSpace.s24,
}) {
  final width = MediaQuery.sizeOf(context).width;
  final gutter = width >= AppLayout.wideBreakpoint
      ? AppLayout.gutterWide
      : AppLayout.gutter;
  final side = max(gutter, (width - AppLayout.maxContentWidth) / 2);
  return EdgeInsets.fromLTRB(side, top, side, bottom);
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.s24, bottom: AppSpace.s12),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: t.titleLarge),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: t.bodyMedium?.copyWith(color: muted),
                    ),
                ],
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// A value with a label on a small raised tile.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
  });

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return MergeSemantics(
      child: ClayCard(
        padding: const EdgeInsets.all(AppSpace.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              IconBubble(icon!),
              const SizedBox(height: AppSpace.s8),
            ],
            Text(value, style: tabular(t.titleLarge)),
            Text(
              label,
              style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small icon on a soft orange circle. Decorative.
class IconBubble extends StatelessWidget {
  const IconBubble(this.icon, {super.key, this.size = 28});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: size * 0.6,
        color: GameColors.of(context).primaryText,
      ),
    ),
  );
}

/// The mascot on a soft plate, a title, a line of help and an action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.body,
    this.look = MascotLook.starter,
    this.action,
  });

  final String title;
  final String body;
  final MascotLook look;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.s32),
      child: Column(
        children: [
          Container(
            width: 144,
            height: 144,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Mascot(size: 112, pose: MascotPose.walk, look: look),
          ),
          const SizedBox(height: AppSpace.s16),
          Text(title, style: t.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: AppSpace.s8),
          Text(
            body,
            style: t.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpace.s24),
            action!,
          ],
        ],
      ),
    );
  }
}
