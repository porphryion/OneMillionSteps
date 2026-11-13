# 1 Million Steps

A mobile game where real walking moves you through virtual marathons across Turkey. Every week new races open, from a 10K on Istanbul's cobblestones to an ultra through Cappadocia's valleys. Join one, walk in real life, and watch yourself move along the course. Finish to earn a medal and coins, then spend the coins on shoes and tracksuit sets that make you faster in the right weather and on the right terrain.

Built with Flutter. Targets Android and iOS, with Turkish UI. Windows desktop is used for quick testing.

## How it works

- **Training first.** New players start with a ladder of six training walks: a 2 km park walk, then 3, 5, 8, 15 and 30 km walks on different weather and terrain. They have no time limit, pay 15 coins per km and must be done in order. Finishing stage 4 unlocks short races, stage 5 half marathons and marathons, stage 6 ultras. Leaving a walk drops its progress, but you can start it again.
- **Weekly races.** Every Monday three races open: one short (10–15 km), one medium (half marathon to marathon) and one ultra (50–60 km). They close the next Monday at midnight. Races keep opening every week, but stay locked until the matching training stage is done. Names come from Turkish geography (Boğaz Maratonu, Peri Bacaları Ultra, Surlar 10K), never from real events.
- **One race at a time.** Training walks and races share one slot. Steps taken after you join count toward it. One step is 0.75 m before bonuses. Withdrawing loses your progress for that race.
- **Medals.** Finish fast for gold, a bit slower for silver, or before the race closes for bronze. Medal targets are set by distance (gold expects about 15,000 steps a day, silver about 10,000).
- **Coins.** 20 coins per km for gold, 75% of that for silver, 50% for bronze. New players start with 400.
- **Gear.** Shoes and tracksuit sets give percentage bonuses for weather (sunny, hot, rainy, windy, cold) or terrain (asphalt, trail, cobblestone, sand, mountain), and some give a bonus on every course. Bonuses from the two slots add up.
- **Fair steps.** At most 50,000 steps count per day.

## Status

Early development. Single player. Steps come from a debug button for now.

**Next**
- Real steps from Health Connect (Android) and Apple Health (iOS)
- Multiplayer: leaderboards per race
- More gear slots, streaks, reminders

## Run

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install).

```
flutter pub get
flutter run -d windows     # or pick an Android emulator / device
flutter test
```

In debug builds, the race tab has two buttons: **+5.000 adım (debug)** simulates walking and **Ertesi gün (debug)** moves the game clock one day ahead. Use the second one to get past the 50,000-steps-a-day cap or to test multi-day races (medal tiers, the weekly close). Debug steps and the day offset are saved, so a race can be tested across restarts.

## Project layout

```
design-system/
  MASTER.md   design system: colors, type, spacing, components, Turkish copy rules
lib/
  game/       rules and state: balance (config.dart), courses and gear (catalog.dart),
              weekly schedule, formulas, controller, save
  steps/      step sources (fake for now, health data next)
  ui/
    theme/    design tokens and ThemeData
    widgets/  shared components (clay cards and buttons, mascot, course banner,
              race track, training ladder, medals, coins, chips)
    screens/  the four tabs and the marathon and training detail screens
assets/fonts/ Baloo 2 and Nunito (SIL OFL)
test/         unit and widget tests
```

All balance numbers live in `lib/game/config.dart`. Races and gear live in `lib/game/catalog.dart`. Every new screen or UI component follows `design-system/MASTER.md`.
