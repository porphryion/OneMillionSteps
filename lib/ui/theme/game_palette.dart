import 'package:material_ui/material_ui.dart';

import '../../game/models.dart';
import 'tokens.dart';

/// Theme-independent game colors (same in light and dark).

Color regionTint(Region r) => switch (r) {
  Region.marmara => Palette.tintBlue,
  Region.aegean => Palette.tintTeal,
  Region.mediterranean => Palette.tintCyan,
  Region.centralAnatolia => Palette.tintOchre,
  Region.blackSea => Palette.tintGreen,
  Region.eastAnatolia => Palette.tintViolet,
  Region.southeastAnatolia => Palette.tintRed,
};

/// Banner color of a course: its region, or the training color for walks.
Color courseTint(Course c) {
  final region = c.region;
  return region == null ? Palette.tintTraining : regionTint(region);
}

Color gearTint(GearTint t) => switch (t) {
  GearTint.blue => Palette.tintBlue,
  GearTint.teal => Palette.tintTeal,
  GearTint.cyan => Palette.tintCyan,
  GearTint.ochre => Palette.tintOchre,
  GearTint.green => Palette.tintGreen,
  GearTint.violet => Palette.tintViolet,
  GearTint.red => Palette.tintRed,
  GearTint.slate => Palette.tintSlate,
};

/// Text and icons on any tint.
const Color onTint = Palette.white;

class DiscColors {
  const DiscColors(this.fill, this.ring, this.glyph, this.shine);
  final Color fill;
  final Color ring;
  final Color glyph;

  /// Highlight at the top-left of the disc.
  final Color shine;
}

DiscColors medalColors(Medal m) => switch (m) {
  Medal.gold => const DiscColors(
    Palette.goldFill,
    Palette.goldRing,
    Palette.goldGlyph,
    Palette.goldShine,
  ),
  Medal.silver => const DiscColors(
    Palette.silverFill,
    Palette.silverRing,
    Palette.silverGlyph,
    Palette.silverShine,
  ),
  Medal.bronze => const DiscColors(
    Palette.bronzeFill,
    Palette.bronzeRing,
    Palette.bronzeGlyph,
    Palette.bronzeShine,
  ),
};

const DiscColors coinColors = DiscColors(
  Palette.coinFill,
  Palette.coinRing,
  Palette.coinGlyph,
  Palette.coinShine,
);

/// Mascot colors: body, its shading, and the face details.
abstract final class MascotPalette {
  static const body = Palette.orange;
  static const bodyShade = Palette.orangeLip;
  static const bodyGlow = Palette.orangeGlow;
  static const face = Palette.ink;
  static const blush = Palette.blush;
  static const sole = Palette.white;
}

/// Banner decoration colors.
const Color sunColor = Palette.sun;
