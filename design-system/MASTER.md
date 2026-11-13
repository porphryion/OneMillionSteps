# 1 Million Steps — Design System (MASTER)

> **Source of truth for every screen and UI component.**
> Before building a screen, check `design-system/pages/<screen-name>.md`. If it exists, its rules
> override this file for that screen only. Otherwise follow this file exactly.

| | |
|---|---|
| Product | Mobile game: real-world steps move the player through a training ladder and then virtual weekly marathons set in Turkey. Finishing earns medals and coins; coins buy shoes and tracksuit sets that speed you up for a race's weather and terrain. |
| Market | Turkey first. All UI copy is Turkish. |
| Platform | Flutter (Android + iOS), Material 3 via `package:material_ui`. Windows desktop for quick testing only. |
| Generated with | `ui-ux-pro-max` → `--design-system "casual mobile game cute playful walking"`. Style match: *Claymorphism* (best for casual games, onboarding, fun-focused apps). Font pairing adapted for Turkish (Fredoka lacks ğ ş İ, so Baloo 2 replaces it). Adapted from the web output to Flutter, verified for contrast, extended with game and Turkish-locale rules. |
| Implementation | `lib/ui/theme/tokens.dart` (raw values), `lib/ui/theme/app_theme.dart` (ThemeData + `GameColors`), `lib/ui/theme/game_palette.dart` (region tints, medal/coin/mascot colors), `lib/ui/format.dart` (Turkish formatting), `lib/ui/widgets/` (shared components; `clay.dart` and `mascot.dart` are the core of the style). |

---

## 1. Direction

**Style: "Toy box" — soft 3D clay, chunky and friendly.** Raised surfaces with a darker lip underneath, round shapes, bubbly type, warm cream paper and a little orange mascot. It should feel like a cozy casual game you want to open every day, not a fitness tracker.

Principles:

1. **Progress is the hero.** Every screen answers "how far am I, how far to go, how long left" before anything else.
2. **Things you can press look pressable.** Buttons and tappable cards stand on a lip and sink onto it when pressed. Flat things are not tappable.
3. **The mascot is the player.** It walks on the race track, wears the gear you buy and cheers when you finish. It is decoration (excluded from screen readers), never the only carrier of information.
4. **Place has color.** Each race takes the color of its Turkish region, with drawn scenery for its terrain and weather.
5. **Green means bonus.** Accent green is reserved for "your gear helps here" and "done". Never decoration.
6. **Warm, never pushy.** Celebrate finishes, not taps. No fake urgency, no endless loops.

Theme follows the system (`ThemeMode.system`). Light ("sunny day": cream and plum ink) and dark ("night walk": deep plum) are both first-class and tested separately.

---

## 2. Color

### 2.1 Semantic tokens

Widgets read colors only from `Theme.of(context).colorScheme` or `GameColors.of(context)`. Raw hex values live only in `tokens.dart` (`Palette`). Contrast figures are WCAG ratios, verified.

| Token | Flutter | Light | Dark | Use |
|---|---|---|---|---|
| Primary | `colorScheme.primary` | `#FF8A1F` | `#FF8A1F` | Sunny orange. Button faces, progress fill, nav indicator, next stage. **Never for text.** |
| On primary | `colorScheme.onPrimary` | `#2E2142` | `#2E2142` | Text/icons on orange (6.3:1). White on orange fails, do not use. |
| Primary lip | `GameColors.primaryLip` | `#CC5A0C` | `#CC5A0C` | The strip under orange faces. |
| Primary container | `colorScheme.primaryContainer` | `#FFE2C2` | `#5A2A12` | Soft orange blocks: ladder header, mascot plate, info notes. |
| On primary container | `colorScheme.onPrimaryContainer` | `#8A3209` | `#FFE2C2` | 6.7 / 8.9:1. |
| Primary text | `GameColors.primaryText` | `#B83C0A` | `#FFAD5C` | Orange text and icons on surfaces (≥5.0:1 light, ≥8.0:1 dark on cards). |
| Accent (bonus) | `colorScheme.secondary` | `#3DD66B` | `#3DD66B` | Bonus pills, done nodes, progress pips. |
| On accent | `colorScheme.onSecondary` | `#2E2142` | `#2E2142` | 7.8:1. |
| Accent lip | `GameColors.secondaryLip` | `#1E9E4A` | `#1E9E4A` | Under green faces. |
| Accent container | `colorScheme.secondaryContainer` | `#D3F8DF` | `#1B4D2E` | "Açıldı" milestone pills. |
| Accent text | `GameColors.accentText` | `#137538` | `#5EE08A` | Green text on surfaces (≥5.0 / ≥8.8:1). |
| Background | `colorScheme.surface` | `#FFF5E8` cream | `#1C1730` night | Page background. |
| Foreground | `colorScheme.onSurface` | `#2E2142` plum ink | `#FFF6EC` | Primary text (13.8 / 16.2:1). |
| Card face | `colorScheme.surfaceContainerLow` | `#FFFFFF` | `#2A2342` | Raised cards, nav bar, dialogs. |
| Muted face | `colorScheme.surfaceContainerHigh` | `#FFEEDA` peach | `#352D52` | Chips, locked stage cards, neutral buttons. |
| Muted foreground | `colorScheme.onSurfaceVariant` | `#6A5B7B` | `#C8BEDF` | Secondary text (≥5.4 / ≥7.2:1 on every face). |
| Line | `GameColors.line` (= `outlineVariant`) | `#F2DCC2` | `#3B3259` | 2 dp border of raised surfaces. Decorative. |
| Lip | `GameColors.lip` | `#E9CFAF` | `#120E21` | The strip under neutral raised surfaces. |
| Locked face / lip | `GameColors.lockedFace` / `lockedLip` | `#E6D6C3` / `#CDB89F` | `#43396A` / `#120E21` | Locked stage nodes and disabled buttons. |
| Outline | `colorScheme.outline` | `#928095` | `#8E82AD` | Meaningful boundaries (≥3.4 / 4.2:1). |
| Error | `colorScheme.error` | `#C42A1E` | `#FF8A80` | Destructive actions (≥5.3 / 6.5:1 as text). White on light error 5.7:1. |
| Danger lip | `GameColors.dangerLip` | `#8E1B12` | `#8E1B12` | Under destructive buttons. |
| Track | `GameColors.track` | `#6E6389` | `#4A4068` | The road under the race progress. |

### 2.2 Region tints (race identity)

The region tint fills the course banner (top-to-bottom gradient from tint lightened 8% to tint). Text on tints is always white, ≥4.5:1. Same values in both themes. Accessed with `regionTint(region)`.

| Region | Tint | White text |
|---|---|---|
| Marmara | `#2563EB` (Boğaz mavisi) | 5.2:1 |
| Ege | `#0F766E` (zeytin-deniz) | 5.5:1 |
| Akdeniz | `#0E7490` (turkuaz) | 5.4:1 |
| İç Anadolu | `#B45309` (bozkır okru) | 5.0:1 |
| Karadeniz | `#15803D` (yayla yeşili) | 5.0:1 |
| Doğu Anadolu | `#7C3AED` (dağ moru) | 5.7:1 |
| Güneydoğu Anadolu | `#E11D48` (nar kırmızısı) | 4.7:1 |
| Training walks | `#C2410C` | 5.2:1 |
| Neutral (starter gear) | `#5B5470` | 7.4:1 |

Gear items reuse the tint set for their art tile (`GearDef.tint`) and the mascot wears the equipped tints (shoes, headband).

### 2.3 Medals, coins, decoration

Medals and coins are **shiny discs**: radial gradient from a shine color (top-left) to the fill, a dark ring, a lip in the ring color and a star glyph. Same values in both themes.

| Item | Shine → fill | Ring / glyph | Label (always shown next to it) |
|---|---|---|---|
| Altın | `#FDE68A` → `#FBBF24` | `#92400E` / `#78350F` | "Altın madalya" |
| Gümüş | `#F1F5F9` → `#CBD5E1` | `#475569` / `#1E293B` | "Gümüş madalya" |
| Bronz | `#F2C39B` → `#D4915D` | `#7C2D12` / `#431407` | "Bronz madalya" |
| Coin | `#FCD34D` → `#F59E0B` | `#B45309` / `#78350F` | number next to it |

Decoration-only colors (never behind text): sun `#FFC93C`, blush `#FF8FA3`, sky `#4CC3F5`, mascot body `#FF8A1F` with glow `#FFA94D` and shade `#CC5A0C`.

### 2.4 Color rules

- Orange `primary` is a fill color. For orange text or icons on a surface use `GameColors.primaryText`.
- Green means bonus, success or "done". Region tints are identity only. Do not mix the roles.
- Never let color carry meaning alone: stage nodes change icon, medals have a label, conditions have an icon and a label, bonuses have a number.
- Gradients: banners (tint), discs (shine), mascot and stage nodes (soft top-left light). Never on text.
- Banner scenery stays in its bottom strip, below the text, so it never lowers text contrast.
- New colors go into `Palette` and a semantic role first. Never `Color(0xFF...)` in a widget.

---

## 3. Typography

| Role | Family | Use |
|---|---|---|
| Display | **Baloo 2** (600, 700, 800) | Bubbly and round: numbers that matter (km, steps, coins), course and screen titles, buttons. |
| Body | **Nunito** (400, 600, 700, 800) | Rounded terminals: everything else. Body copy uses 600 so it reads as friendly, not thin. |

Fonts are bundled in `assets/fonts/` (SIL OFL, `assets/fonts/OFL.txt`). Baloo 2 is subset to Latin + Latin Extended (Turkish set ç ğ ı İ ö ş ü, ₺) with tabular figures kept. Never load fonts from the network at runtime. Fredoka, Lilita One and other playful fonts were rejected because they lack ğ, ş or İ — check Turkish coverage before adding any font.

### 3.1 Scale (Flutter `TextTheme`)

Display styles use `leadingDistribution: even` so Baloo's tall ascenders stay centered.

| Role | Family / weight | Size / line height | Use |
|---|---|---|---|
| `displayLarge` | Baloo 800 | 56 / 1.0 | Hero distance on the race screen |
| `displayMedium` | Baloo 800 | 44 / 1.05 | Celebration numbers |
| `displaySmall` | Baloo 800 | 36 / 1.1 | Big stats |
| `headlineLarge` | Baloo 800 | 32 / 1.15 | Course name on banners (detail) |
| `headlineMedium` | Baloo 800 | 28 / 1.2 | Screen titles (AppBar) |
| `headlineSmall` | Baloo 700 | 24 / 1.2 | Course name on cards, dialog titles, today's steps |
| `titleLarge` | Baloo 700 | 21 / 1.25 | Section headers, stage names, card numbers |
| `titleMedium` | Nunito 800 | 16 / 1.4 | List titles, gear names |
| `titleSmall` | Nunito 800 | 14 / 1.4 | Small titles |
| `bodyLarge` | Nunito 600 | 16 / 1.5 | Main body copy |
| `bodyMedium` | Nunito 600 | 14 / 1.45 | Secondary copy |
| `bodySmall` | Nunito 600 | 12 / 1.4 | Captions only. Nothing smaller than 12. |
| `labelLarge` | Nunito 800 | 15 / 1.2 | Text buttons, status lines |
| `labelMedium` | Nunito 800 | 13 / 1.2 | Chips, pills |
| `labelSmall` | Nunito 800 | 12 / 1.2, +0.6 tracking | Overlines ("KADEME 3", region name) |
| `buttonTextStyle` | Baloo 700 | 18 / 1.1 | Chunky buttons (`app_theme.dart`) |

### 3.2 Rules

- Read styles from `Theme.of(context).textTheme`. Adjust with `copyWith`, never build a fresh `TextStyle(fontSize: …)` (the only exception is `buttonTextStyle`, defined once in the theme).
- Numbers that change (steps, km, coins, countdowns) use tabular figures: `tabular(style)`.
- Respect the system text size. Never fix the height of a box that contains text; let it grow. Test at 200%.
- Overlines may be uppercase. **Never call `toUpperCase()` on Turkish text** — it turns `i` into `I` instead of `İ`. Use `trUpper()` from `format.dart`.

---

## 4. Spacing, shape, depth

| Token (`AppSpace`) | Value | Use |
|---|---|---|
| `s4` | 4 | Icon-to-label, tight pairs |
| `s8` | 8 | Gaps inside a component, chip spacing |
| `s12` | 12 | Gaps between related rows, list item spacing, card padding (small cards) |
| `s16` | 16 | Card padding, phone page gutter |
| `s24` | 24 | Between sections, tablet gutter |
| `s32` | 32 | Large section breaks |
| `s48` | 48 | Breathing room |

All spacing is on the 4/8 grid. No other values.

| Token (`AppRadius`) | Value | Use |
|---|---|---|
| `sm` | 8 | Small tiles |
| `md` | 16 | Buttons, segmented control, snackbars |
| `lg` | 20 | Cards, stat tiles, notes |
| `xl` | 28 | Course banners, dialogs |
| `pill` | 999 | Pills, chips, HUD, road |

Gear art tiles use radius = 30% of their size. Everything is round; no sharp corners.

**Depth (`AppDepth`) — the clay look.** A raised surface is a face with a 2 dp border (`kClayBorder`, `GameColors.line`) sitting on a lip: a hard shadow with no blur, offset straight down, in the lip color. Pressing moves the face down by the lip height (`AppMotion.press`).

| Token | Lip | Use |
|---|---|---|
| `chip` | 2 | Chips, bonus pill (3 for the HUD pill and small gear tiles) |
| `card` | 4 | Cards, stat tiles, big gear tiles, stage nodes (8% of size) |
| `button` | 5 | Chunky buttons |

Lips add their height to the layout (margin), so nothing overlaps. No blurred drop shadows anywhere except Material's own on dialogs and snackbars.

Icon sizes (`AppIconSize`): `sm` 16 (inside chips), `md` 24 (default), `lg` 32, `xl` 48.

---

## 5. Iconography

- **Material Icons, Rounded family only** (`Icons.*_rounded`), bundled with Flutter. Outlined variants (`*_outlined`) only for unselected navigation destinations.
- **No emoji as icons.** Not in buttons, chips, tabs or titles. Custom drawings (mascot, sneaker, scenery) are `CustomPainter`s.
- Icons next to a text label are decorative: wrap the pair in one `Semantics` label or use `ExcludeSemantics` on the icon. Icon-only buttons must have a `tooltip` (it becomes the accessible name).
- Small icons inside a soft orange circle (`IconBubble`) label stat tiles and notes.

| Meaning | Icon |
|---|---|
| Nav: Yarış (active race) | `directions_run_rounded` |
| Nav: Maratonlar | `flag_rounded` / `outlined_flag_rounded` |
| Nav: Mağaza | `storefront_rounded` / `storefront_outlined` |
| Nav: Madalyalar | `military_tech_rounded` / `military_tech_outlined` |
| Güneşli | `wb_sunny_rounded` |
| Sıcak | `thermostat_rounded` |
| Yağmurlu | `water_drop_rounded` |
| Rüzgârlı | `air_rounded` |
| Soğuk | `ac_unit_rounded` |
| Asfalt | `add_road_rounded` |
| Patika | `forest_rounded` |
| Arnavut kaldırımı | `grid_view_rounded` |
| Kum | `beach_access_rounded` |
| Dağ | `landscape_rounded` |
| Ayakkabı | `directions_run_rounded` (segmented control); drawn sneaker on gear tiles |
| Eşofman takımı | `checkroom_rounded` |
| Time left | `schedule_rounded` |
| Distance | `straighten_rounded` |
| Steps | `directions_walk_rounded` |
| Bonus | `bolt_rounded` |
| Locked | `lock_rounded`; unlocked milestone `lock_open_rounded` |
| Milestone reward | `emoji_events_rounded` |
| Did not finish | `flag_outlined` |

---

## 6. Motion

Motion explains change and makes the game feel alive; it never loops forever.

| Token (`AppMotion`) | Duration | Curve | Use |
|---|---|---|---|
| `press` | 80 ms | `easeOutCubic` | Face sinking onto its lip |
| `fast` | 150 ms | `easeOutCubic` | Chips, toggles, selection |
| `base` | 250 ms | `easeOutCubic` | Content swaps, tab content |
| `slow` | 450 ms | `easeOutCubic` | Progress fill after new steps |
| `stride` | 900 ms | linear | One mascot walk/cheer cycle |
| `celebrate` | 900 ms | `easeOutBack` | Reward reveal (medal or cheering mascot) and its rays |

- **The mascot moves in short bursts:** 3 cycles, then rests. It walks again when the race progress changes (`playKey`) and cheers again when the outfit changes. No endless loops — they drain batteries and break `pumpAndSettle` in tests.
- Exits are faster than entries (~70% of the entry duration, `easeInCubic`).
- **Reduced motion:** wrap durations with `AppMotion.of(context, d)`; `AppMotion.reduced(context)` stops the mascot. The final state shows immediately.
- Never animate layout size of text containers; animate transforms, margins of the clay lip, or the progress value.
- Haptics: `lightImpact` on chunky buttons, `mediumImpact` on a finish.

---

## 7. Layout and navigation

- **Bottom `NavigationBar` with exactly 4 destinations**: Yarış · Maratonlar · Mağaza · Madalyalar. Labels always visible. Orange pill indicator with an ink icon. A 2 dp line separates it from the page. Tab state is kept (`IndexedStack`).
- App bars: big Baloo title on the left, the coin balance as a raised HUD pill on the right.
- Detail screens (marathon, training stage) are pushed with typed constructor arguments, have a back button and a sticky chunky CTA at the bottom.
- Page gutter 16 on phones, 24 when width ≥ 600. Content max width 600, centered on tablets/desktop.
- Respect safe areas. Sticky bottom CTAs sit inside `SafeArea` and lists get bottom padding so nothing hides behind them.
- Touch targets ≥ 48×48 dp. Spacing between tappable items ≥ 8.
- Pull to refresh on screens that show step-driven numbers (syncs steps).
- One primary (orange) chunky button per screen or card. Others are neutral, disabled or text buttons.

---

## 8. Components

All live in `lib/ui/widgets/`. Reuse them; extend them before creating look-alikes.

| Component | Spec |
|---|---|
| **ClayCard** (`clay.dart`) | The base raised surface: face (default card face), 2 dp line, lip `card` (4), radius `lg`. With `onTap` the whole card is one target and sinks when pressed. Clips its child (banners inside cards). |
| **GameButton** (`clay.dart`) | Chunky button, min height 52 + 5 lip, radius `md`, `buttonTextStyle`, optional leading icon. Tones: `primary` (orange/ink), `success` (green/ink), `danger` (error/onError), `neutral` (muted face, line border). Disabled: flat beige `lockedFace` with muted text, `onPressed: null`. Light haptic on press. |
| **HudPill** (`clay.dart`) | Small raised pill for the app bar. `CoinBalance` uses it. |
| **Mascot** (`mascot.dart`) | Original round orange walker with a headband, blush and sneakers (`CustomPainter`). Poses: `idle`, `walk`, `cheer`. `MascotLook.of(game)` colors the sneakers and headband with the equipped gear's tints. Always `ExcludeSemantics`. Sizes: 64 on the track, 84 in the ladder header, 96 in the wardrobe, 112–120 in empty states and celebrations. |
| **CourseBanner** | Tint gradient block, radius `xl` (zero inside a card). Overline: region or "HAZIRLIK" via `trUpper`, `labelSmall`, white. Name: `headlineSmall` (card) / `headlineLarge` (detail), white. City line with a place icon. Tag pill top-right (`KISA` / `ORTA` / `ULTRA` / `KADEME 3`), dark translucent with a white 35% border. Bottom strip (44 / 56 dp) of scenery: terrain silhouettes (hills + trees for trail, peaks with snow for mountain, dunes for sand, rooftops with a dome and tower for cobblestone, a dashed road for asphalt) in white 14–24%, and the weather drawn at the right (yellow sun, bigger for hot; cloud with rain or snow; wind gusts). Locked: black 35% scrim and a `KİLİTLİ` pill with a lock. |
| **MarathonCard** | `ClayCard` (tappable) with the banner on top, then distance (`titleLarge`, tabular) + condition chips, then a status row (time left / joined + % / medal / time up / opens Monday / "Kademe N ile açılır") and the max coin reward. |
| **RaceTrack** | A 20 dp road in `GameColors.track` with white center dashes ahead, a checkered finish and an orange fill with a soft highlight. The mascot (64) walks on it at the current position. Animates with `AppMotion.slow`. Always paired with a text percentage (`%56 tamamlandı`). Semantics: "Yüzde 56 tamamlandı". |
| **TrainingHeader** | `ClayCard` in `primaryContainer` with the walking mascot, "Hazırlık" (`headlineSmall`), one line of help and six progress pips (green filled when done) with `done/6`. Shown above the ladder until it is complete. |
| **TrainingPath / StageNode** | One row per stage: a 52 dp raised round node on the left and a tappable `ClayCard` on the right; footprints walk down between nodes (green after a finished stage). Node states: **done** green + check; **available** orange + tier number + soft orange glow; **running** orange + walking icon; **locked** beige + lock. Card: overline `KADEME N`, name (`titleLarge`), "km · hava · zemin", optional milestone pill ("Kısa yarışlar açılır" with a trophy, or "… açıldı" in green with an open lock), trailing status ("Tamamlandı" / `%42` / orange "Sırada" pill + coin reward / "Kilitli"). The current stage's card has an orange border and lip; locked cards use the muted face. |
| **StageRewards** | `+coin` in `headlineSmall` and one green line per unlock with an open lock icon. |
| **ConditionChip** | Muted pill with a 2 dp line, icon (`sm`) + label (`labelMedium`). When gear gives a bonus: `accentText` border and a trailing `+%25` in `accentText`. |
| **BonusPill** | Raised green pill (`chip` lip), `bolt_rounded` + `+%25` in `onSecondary`. Zero bonus: muted pill "Bonus yok". |
| **CoinAmount** | Shiny coin disc (18–28 dp) + tabular Baloo number (default 18). Positive rewards prefixed `+`. |
| **MedalBadge** | Shiny disc in tier colors, ring, lip, star glyph. Sizes 36 / 44 / 96. Always with a visible tier label or a `Semantics` label "Altın madalya". |
| **GearArt** | Raised tile in the item's tint (gradient, lip in the tint darkened 35%), radius 30%. Shoes show a drawn white sneaker, outfits a hanger icon. |
| **GearCard** | `ClayCard`: GearArt (56) + name (`titleMedium`) + blurb + bonus chips; full-width action: `Giyili` (disabled, check icon) / `Giy` (neutral) / `Satın al` + coin price (primary; when short it is disabled with "N coin daha gerekiyor" below). |
| **Wardrobe** (shop) | `ClayCard` with the cheering mascot (96) in the equipped gear and the equipped item names with small gear tiles. |
| **StatTile** | `ClayCard` with an `IconBubble`, value in `titleLarge` tabular, label in `bodySmall` muted. |
| **TodayStrip** (race tab) | `ClayCard`: `IconBubble` (40), "Bugün" with the date below, today's counted steps in `headlineSmall` tabular + "adım". When the daily cap is full, a `primaryContainer` note with `bedtime_rounded`: "Günlük 50.000 adım sınırı doldu. Yeni adımların yarın sayılır." — new steps must never silently do nothing. |
| **SectionHeader** | `titleLarge` + optional `bodyMedium` muted subtitle, 24 above / 12 below. |
| **EmptyState** | Mascot (112, walking) on a 144 dp `primaryContainer` plate, `headlineSmall` title, one-sentence `bodyLarge` body, one primary `GameButton` with an icon. |
| **Dialogs** | Radius `xl`, 2 dp line. Max one primary action (`GameButton`); cancel is a text button; destructive confirm uses the `danger` tone and names the consequence ("İlerlemen silinir"). |
| **Result dialog** | Finish: orange sun-ray burst rotating in behind a 96 dp medal (scale-in, `celebrate`), title "Bitiş çizgisi!", race name, tier, `+coin`, button "Harika!". Stage done: the cheering mascot in the player's gear instead of the medal, "Kademe tamamlandı!", coins and unlock lines in green, button "Devam". Time up: `timer_off_rounded`, neutral tone, distance covered. |

---

## 9. Copy and Turkish locale

**Voice:** friendly coach and playful buddy, second person singular (*sen*), short sentences, active verbs. A little exclamation is welcome on wins ("Harika!", "Hazırlığa devam!"); never shame ("Süre doldu", not "Başaramadın").

**Glossary** (use these words, nothing else):

| Concept | Turkish |
|---|---|
| Marathon event | Maraton (generic race: Yarış) |
| Training ladder / one step of it | Hazırlık / Kademe |
| Next stage to do | Sırada |
| Locked | Kilitli ("Kademe 5 ile açılır") |
| Start a training walk / leave it | Başla / Yürüyüşü bırak |
| Course | Parkur |
| Join / withdraw | Katıl / Yarıştan çekil |
| Active race | Aktif yarış |
| Finish | Bitir / Bitiş çizgisi |
| Time up | Süre doldu |
| Medal: gold / silver / bronze | Altın / Gümüş / Bronz madalya |
| Coin | Coin |
| Shoes / tracksuit set | Ayakkabı / Eşofman takımı |
| The mascot wearing your gear | Karakterin |
| Weather / terrain | Hava / Zemin |
| Buy / wear / worn | Satın al / Giy / Giyili |
| Bonus | Bonus |
| Steps | Adım |

**Formats** (all in `format.dart`):

| What | Format | Helper |
|---|---|---|
| Integers | `12.345` (dot thousands) | `groupThousands` |
| Distance | `42,2 km` (comma decimal) | `formatKm` |
| Percent | `%25`, bonus `+%25` (sign before the number) | `percent`, `bonusPercent` |
| Dates | `13 Kasım`, ranges `9–15 Kasım`, `30 Ekim – 5 Kasım` | `dayMonth`, `dateRange` |
| Time left | `3 gün kaldı`, `Son gün` | `timeLeftLabel` |

**Grammar rule:** never glue a suffix onto a dynamic name (`Boğaz Maratonu'nu`) — vowel harmony makes it wrong for other names. Put the name in a title or subject position instead ("Boğaz Maratonu tamamlandı").

**Naming policy for races and gear (legal):** no real event names, logos or sponsor brands (e.g. İstanbul Maratonu, Runatolia, Cappadocia Ultra-Trail, Likya Yolu Ultra) and no sportswear brands or look-alike logos (no swooshes or stripes on the drawn sneaker). Use geography plus a descriptive word: *Boğaz Maratonu*, *Peri Bacaları Ultra*, *Surlar 10K*. City and region names are fine. The mascot is original; do not restyle it after another game's or brand's character.

---

## 10. Accessibility

- Text contrast ≥ 4.5:1, large text and meaningful non-text UI ≥ 3:1, in **both** themes (Section 2 lists verified pairs). Disabled controls are exempt but stay readable.
- Touch targets ≥ 48 dp. Every control has an accessible name; icon-only buttons have a `tooltip`.
- Screen reader order matches visual order. Group related values in `MergeSemantics` (e.g. a stage card reads as one item).
- Color never carries meaning alone. The mascot and scenery are decorative and excluded from semantics.
- Reduced motion and 200% text size work without clipping.
- Pull to refresh always has a button alternative where it matters (the race screen has a sync action).

---

## 11. Anti-patterns (do not do)

- Flat, gray, spreadsheet-like screens; missing progress feedback.
- Tappable things without a lip, or lips on things that are not tappable (except decoration like coins and gear tiles).
- Blurred drop shadows, glassmorphism, neon — they fight the clay look.
- Emoji as icons; mixing icon families or filled/outlined at the same level.
- Orange text on light backgrounds (`primary` as text) — use `primaryText`. White text on orange.
- Fonts without the full Turkish set; `toUpperCase()` on Turkish strings; suffixes glued onto dynamic names.
- Raw hex colors, ad-hoc font sizes, spacing off the 4/8 grid.
- More than one primary button per screen or card; destructive actions without confirm.
- Endless animations (mascot, pulses), confetti storms, fake urgency, shaming copy.
- Real event names/logos, sportswear brands, or characters copied from other games.

---

## 12. Pre-delivery checklist (Flutter)

- [ ] Used `ui-ux-pro-max` for the new screen/component and followed this file (and any `pages/` override).
- [ ] Colors come from `colorScheme` / `GameColors`; text from `textTheme`; spacing from `AppSpace`; radius from `AppRadius`; depth from `AppDepth`.
- [ ] Raised surfaces use `ClayCard` / `GameButton` rather than new look-alikes.
- [ ] Checked light **and** dark mode separately.
- [ ] Touch targets ≥ 48 dp; pressed feedback visible (face sinks); disabled states non-interactive.
- [ ] Safe areas respected; nothing hidden behind the nav bar or sticky CTA.
- [ ] Works at 360 dp width, in landscape and at 200% text size.
- [ ] `AppMotion.of` used for every animation; no endless loops (widget tests with `pumpAndSettle` must settle).
- [ ] Icons: Material Rounded, consistent sizes, labels/tooltips present; mascot and scenery excluded from semantics.
- [ ] Turkish copy follows the glossary and formats; no `toUpperCase()`; no dynamic suffixes.
- [ ] Numbers that change use tabular figures.
