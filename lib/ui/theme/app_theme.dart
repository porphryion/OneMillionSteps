import 'package:material_ui/material_ui.dart';

import 'tokens.dart';

/// Theme colors Material's ColorScheme has no role for.
class GameColors extends ThemeExtension<GameColors> {
  const GameColors({
    required this.primaryText,
    required this.accentText,
    required this.track,
    required this.line,
    required this.lip,
    required this.primaryLip,
    required this.secondaryLip,
    required this.dangerLip,
    required this.lockedFace,
    required this.lockedLip,
  });

  /// Orange for text and icons on surfaces. `colorScheme.primary` is for fills.
  final Color primaryText;

  /// Green for bonus text and icons on surfaces.
  final Color accentText;

  /// Race road under the progress fill.
  final Color track;

  /// Border of raised surfaces (cards, tiles, chips).
  final Color line;

  /// The darker strip under a raised neutral surface.
  final Color lip;

  /// Lips under orange, green and red faces.
  final Color primaryLip;
  final Color secondaryLip;
  final Color dangerLip;

  /// Face and lip of locked stage nodes and disabled buttons.
  final Color lockedFace;
  final Color lockedLip;

  static const light = GameColors(
    primaryText: Palette.orangeText,
    accentText: Palette.greenText,
    track: Palette.road,
    line: Palette.cardLine,
    lip: Palette.cardLip,
    primaryLip: Palette.orangeLip,
    secondaryLip: Palette.greenLip,
    dangerLip: Palette.redLip,
    lockedFace: Palette.lockedFace,
    lockedLip: Palette.lockedLip,
  );

  static const dark = GameColors(
    primaryText: Palette.orangeTextDark,
    accentText: Palette.greenTextDark,
    track: Palette.nightRoad,
    line: Palette.nightLine,
    lip: Palette.nightLip,
    primaryLip: Palette.orangeLip,
    secondaryLip: Palette.greenLip,
    dangerLip: Palette.redLip,
    lockedFace: Palette.nightHighest,
    lockedLip: Palette.nightLip,
  );

  static GameColors of(BuildContext context) =>
      Theme.of(context).extension<GameColors>()!;

  @override
  GameColors copyWith({
    Color? primaryText,
    Color? accentText,
    Color? track,
    Color? line,
    Color? lip,
    Color? primaryLip,
    Color? secondaryLip,
    Color? dangerLip,
    Color? lockedFace,
    Color? lockedLip,
  }) => GameColors(
    primaryText: primaryText ?? this.primaryText,
    accentText: accentText ?? this.accentText,
    track: track ?? this.track,
    line: line ?? this.line,
    lip: lip ?? this.lip,
    primaryLip: primaryLip ?? this.primaryLip,
    secondaryLip: secondaryLip ?? this.secondaryLip,
    dangerLip: dangerLip ?? this.dangerLip,
    lockedFace: lockedFace ?? this.lockedFace,
    lockedLip: lockedLip ?? this.lockedLip,
  );

  @override
  GameColors lerp(GameColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return GameColors(
      primaryText: l(primaryText, other.primaryText),
      accentText: l(accentText, other.accentText),
      track: l(track, other.track),
      line: l(line, other.line),
      lip: l(lip, other.lip),
      primaryLip: l(primaryLip, other.primaryLip),
      secondaryLip: l(secondaryLip, other.secondaryLip),
      dangerLip: l(dangerLip, other.dangerLip),
      lockedFace: l(lockedFace, other.lockedFace),
      lockedLip: l(lockedLip, other.lockedLip),
    );
  }
}

const _lightScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Palette.orange,
  onPrimary: Palette.ink,
  primaryContainer: Palette.orangeSoft,
  onPrimaryContainer: Palette.orangeDeep,
  secondary: Palette.green,
  onSecondary: Palette.ink,
  secondaryContainer: Palette.greenSoft,
  onSecondaryContainer: Palette.greenDeep,
  error: Palette.red,
  onError: Palette.white,
  surface: Palette.cream,
  onSurface: Palette.ink,
  onSurfaceVariant: Palette.muted,
  surfaceContainerLowest: Palette.white,
  surfaceContainerLow: Palette.white,
  surfaceContainer: Palette.white,
  surfaceContainerHigh: Palette.peach,
  surfaceContainerHighest: Palette.peachDeep,
  outline: Palette.outline,
  outlineVariant: Palette.cardLine,
  inverseSurface: Palette.ink,
  onInverseSurface: Palette.cream,
  inversePrimary: Palette.orangeTextDark,
  surfaceTint: Colors.transparent,
);

const _darkScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Palette.orange,
  onPrimary: Palette.ink,
  primaryContainer: Palette.orangeNight,
  onPrimaryContainer: Palette.orangeSoft,
  secondary: Palette.green,
  onSecondary: Palette.ink,
  secondaryContainer: Palette.greenNight,
  onSecondaryContainer: Palette.greenNightOn,
  error: Palette.redDark,
  onError: Palette.ink,
  surface: Palette.night,
  onSurface: Palette.nightText,
  onSurfaceVariant: Palette.nightMuted,
  surfaceContainerLowest: Palette.nightLip,
  surfaceContainerLow: Palette.nightCard,
  surfaceContainer: Palette.nightCard,
  surfaceContainerHigh: Palette.nightHigh,
  surfaceContainerHighest: Palette.nightHighest,
  outline: Palette.nightOutline,
  outlineVariant: Palette.nightLine,
  inverseSurface: Palette.nightText,
  onInverseSurface: Palette.ink,
  inversePrimary: Palette.orangeText,
  surfaceTint: Colors.transparent,
);

// Baloo 2 has tall ascenders; even leading keeps it centered in buttons.
const _even = TextLeadingDistribution.even;

const _textTheme = TextTheme(
  displayLarge: TextStyle(
    fontFamily: AppFonts.display,
    fontWeight: FontWeight.w800,
    fontSize: 56,
    height: 1.0,
    leadingDistribution: _even,
  ),
  displayMedium: TextStyle(
    fontFamily: AppFonts.display,
    fontWeight: FontWeight.w800,
    fontSize: 44,
    height: 1.05,
    leadingDistribution: _even,
  ),
  displaySmall: TextStyle(
    fontFamily: AppFonts.display,
    fontWeight: FontWeight.w800,
    fontSize: 36,
    height: 1.1,
    leadingDistribution: _even,
  ),
  headlineLarge: TextStyle(
    fontFamily: AppFonts.display,
    fontWeight: FontWeight.w800,
    fontSize: 32,
    height: 1.15,
    leadingDistribution: _even,
  ),
  headlineMedium: TextStyle(
    fontFamily: AppFonts.display,
    fontWeight: FontWeight.w800,
    fontSize: 28,
    height: 1.2,
    leadingDistribution: _even,
  ),
  headlineSmall: TextStyle(
    fontFamily: AppFonts.display,
    fontWeight: FontWeight.w700,
    fontSize: 24,
    height: 1.2,
    leadingDistribution: _even,
  ),
  titleLarge: TextStyle(
    fontFamily: AppFonts.display,
    fontWeight: FontWeight.w700,
    fontSize: 21,
    height: 1.25,
    leadingDistribution: _even,
  ),
  titleMedium: TextStyle(
    fontFamily: AppFonts.body,
    fontWeight: FontWeight.w800,
    fontSize: 16,
    height: 1.4,
  ),
  titleSmall: TextStyle(
    fontFamily: AppFonts.body,
    fontWeight: FontWeight.w800,
    fontSize: 14,
    height: 1.4,
  ),
  bodyLarge: TextStyle(
    fontFamily: AppFonts.body,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 1.5,
  ),
  bodyMedium: TextStyle(
    fontFamily: AppFonts.body,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    height: 1.45,
  ),
  bodySmall: TextStyle(
    fontFamily: AppFonts.body,
    fontWeight: FontWeight.w600,
    fontSize: 12,
    height: 1.4,
  ),
  labelLarge: TextStyle(
    fontFamily: AppFonts.body,
    fontWeight: FontWeight.w800,
    fontSize: 15,
    height: 1.2,
  ),
  labelMedium: TextStyle(
    fontFamily: AppFonts.body,
    fontWeight: FontWeight.w800,
    fontSize: 13,
    height: 1.2,
  ),
  labelSmall: TextStyle(
    fontFamily: AppFonts.body,
    fontWeight: FontWeight.w800,
    fontSize: 12,
    height: 1.2,
    letterSpacing: 0.6,
  ),
);

/// Label of chunky buttons.
const TextStyle buttonTextStyle = TextStyle(
  fontFamily: AppFonts.display,
  fontWeight: FontWeight.w700,
  fontSize: 18,
  height: 1.1,
  leadingDistribution: _even,
);

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = dark ? _darkScheme : _lightScheme;
  final game = dark ? GameColors.dark : GameColors.light;
  final buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.md),
  );
  const buttonSize = Size(64, AppLayout.buttonHeight);

  final base = ThemeData(
    colorScheme: scheme,
    fontFamily: AppFonts.body,
    textTheme: _textTheme,
  );
  final text = base.textTheme;

  return base.copyWith(
    scaffoldBackgroundColor: scheme.surface,
    extensions: [game],
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.headlineMedium,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: game.line, width: kClayBorder),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: buttonSize,
        shape: buttonShape,
        elevation: 0,
        textStyle: buttonTextStyle,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, AppLayout.minTouch),
        shape: buttonShape,
        textStyle: buttonTextStyle,
        foregroundColor: scheme.onSurface,
        side: BorderSide(color: scheme.outline, width: kClayBorder),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(64, AppLayout.minTouch),
        shape: buttonShape,
        textStyle: text.labelLarge,
        // Orange text must use the text-safe shade (MASTER.md §2.4).
        foregroundColor: game.primaryText,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      extendedTextStyle: text.labelLarge,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: game.primaryLip, width: kClayBorder),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.primary,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => text.labelMedium?.copyWith(
          color: states.contains(WidgetState.selected)
              ? scheme.onSurface
              : scheme.onSurfaceVariant,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : scheme.onSurfaceVariant,
        ),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        minimumSize: const Size(64, AppLayout.minTouch),
        textStyle: text.labelLarge,
        foregroundColor: scheme.onSurface,
        backgroundColor: scheme.surfaceContainerLow,
        selectedBackgroundColor: scheme.primary,
        selectedForegroundColor: scheme.onPrimary,
        side: BorderSide(color: game.line, width: kClayBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    ),
    expansionTileTheme: ExpansionTileThemeData(
      iconColor: scheme.onSurface,
      collapsedIconColor: scheme.onSurfaceVariant,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: BorderSide(color: game.line, width: kClayBorder),
      ),
      titleTextStyle: text.headlineSmall?.copyWith(color: scheme.onSurface),
      contentTextStyle: text.bodyLarge?.copyWith(color: scheme.onSurface),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      contentTextStyle: text.labelLarge?.copyWith(
        color: scheme.onInverseSurface,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    ),
    dividerTheme: DividerThemeData(color: game.line, space: 1),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: game.primaryText,
      refreshBackgroundColor: scheme.surfaceContainerLow,
    ),
  );
}
