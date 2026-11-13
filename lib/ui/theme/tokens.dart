import 'package:material_ui/material_ui.dart';

/// Design tokens from design-system/MASTER.md ("Toy box" style).
///
/// This is the only file allowed to hold raw color values. Widgets read
/// colors from `Theme.of(context).colorScheme`, [GameColors] or the helpers
/// in `game_palette.dart`.
abstract final class Palette {
  // Brand: sunny orange for fills, a darker "lip" under it, a text shade.
  static const orange = Color(0xFFFF8A1F);
  static const orangeLip = Color(0xFFCC5A0C);
  static const orangeText = Color(0xFFB83C0A);
  static const orangeTextDark = Color(0xFFFFAD5C);
  static const orangeSoft = Color(0xFFFFE2C2);
  static const orangeDeep = Color(0xFF8A3209);
  static const orangeNight = Color(0xFF5A2A12);
  static const orangeGlow = Color(0xFFFFA94D);

  // Bonus green
  static const green = Color(0xFF3DD66B);
  static const greenLip = Color(0xFF1E9E4A);
  static const greenText = Color(0xFF137538);
  static const greenTextDark = Color(0xFF5EE08A);
  static const greenSoft = Color(0xFFD3F8DF);
  static const greenDeep = Color(0xFF14532D);
  static const greenNight = Color(0xFF1B4D2E);
  static const greenNightOn = Color(0xFFC6F6D5);

  // Light: cream paper, white cards, plum ink
  static const ink = Color(0xFF2E2142);
  static const cream = Color(0xFFFFF5E8);
  static const white = Color(0xFFFFFFFF);
  static const peach = Color(0xFFFFEEDA);
  static const peachDeep = Color(0xFFFCE0BF);
  static const cardLine = Color(0xFFF2DCC2);
  static const cardLip = Color(0xFFE9CFAF);
  static const muted = Color(0xFF6A5B7B);
  static const outline = Color(0xFF928095);
  static const road = Color(0xFF6E6389);

  // Dark: night plum
  static const night = Color(0xFF1C1730);
  static const nightCard = Color(0xFF2A2342);
  static const nightHigh = Color(0xFF352D52);
  static const nightHighest = Color(0xFF43396A);
  static const nightLine = Color(0xFF3B3259);
  static const nightLip = Color(0xFF120E21);
  static const nightText = Color(0xFFFFF6EC);
  static const nightMuted = Color(0xFFC8BEDF);
  static const nightOutline = Color(0xFF8E82AD);
  static const nightRoad = Color(0xFF4A4068);

  // Status
  static const red = Color(0xFFC42A1E);
  static const redLip = Color(0xFF8E1B12);
  static const redDark = Color(0xFFFF8A80);

  // Decoration only (never behind text)
  static const sun = Color(0xFFFFC93C);
  static const sky = Color(0xFF4CC3F5);
  static const blush = Color(0xFFFF8FA3);
  static const lockedFace = Color(0xFFE6D6C3);
  static const lockedLip = Color(0xFFCDB89F);

  // Region / gear tints (white text on all, >= 4.5:1)
  static const tintBlue = Color(0xFF2563EB);
  static const tintTeal = Color(0xFF0F766E);
  static const tintCyan = Color(0xFF0E7490);
  static const tintOchre = Color(0xFFB45309);
  static const tintGreen = Color(0xFF15803D);
  static const tintViolet = Color(0xFF7C3AED);
  static const tintRed = Color(0xFFE11D48);
  static const tintSlate = Color(0xFF5B5470);

  /// Training walks (brand deep orange, white text 5.2:1).
  static const tintTraining = Color(0xFFC2410C);

  // Medals and coin: fill, ring, glyph, shine
  static const goldFill = Color(0xFFFBBF24);
  static const goldRing = Color(0xFF92400E);
  static const goldGlyph = Color(0xFF78350F);
  static const goldShine = Color(0xFFFDE68A);
  static const silverFill = Color(0xFFCBD5E1);
  static const silverRing = Color(0xFF475569);
  static const silverGlyph = Color(0xFF1E293B);
  static const silverShine = Color(0xFFF1F5F9);
  static const bronzeFill = Color(0xFFD4915D);
  static const bronzeRing = Color(0xFF7C2D12);
  static const bronzeGlyph = Color(0xFF431407);
  static const bronzeShine = Color(0xFFF2C39B);
  static const coinFill = Color(0xFFF59E0B);
  static const coinRing = Color(0xFFB45309);
  static const coinGlyph = Color(0xFF78350F);
  static const coinShine = Color(0xFFFCD34D);
}

/// 4/8 spacing grid. No other values.
abstract final class AppSpace {
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s48 = 48;
}

/// Chunky, toy-like corners.
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 28;
  static const double pill = 999;
}

/// Height of the darker "lip" under a raised surface. Pressing sinks the
/// face onto it.
abstract final class AppDepth {
  static const double chip = 2;
  static const double card = 4;
  static const double button = 5;
}

/// Border width of raised surfaces.
const double kClayBorder = 2;

abstract final class AppIconSize {
  static const double sm = 16;
  static const double md = 24;
  static const double lg = 32;
  static const double xl = 48;
}

abstract final class AppLayout {
  static const double gutter = AppSpace.s16;
  static const double gutterWide = AppSpace.s24;
  static const double wideBreakpoint = 600;
  static const double maxContentWidth = 600;
  static const double minTouch = 48;
  static const double buttonHeight = 52;
}

abstract final class AppFonts {
  /// Rounded, bubbly: headings, numbers, buttons.
  static const display = 'Baloo2';

  /// Rounded terminals: body text and labels.
  static const body = 'Nunito';
}

abstract final class AppMotion {
  static const press = Duration(milliseconds: 80);
  static const tap = Duration(milliseconds: 100);
  static const fast = Duration(milliseconds: 150);
  static const base = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 450);
  static const celebrate = Duration(milliseconds: 900);

  /// One mascot stride (two steps).
  static const stride = Duration(milliseconds: 900);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;

  /// Overshoot: press release, rewards, the next stage's pulse.
  static const Curve reward = Curves.easeOutBack;

  /// [d], or zero when the user has turned animations off.
  static Duration of(BuildContext context, Duration d) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : d;

  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);
}
