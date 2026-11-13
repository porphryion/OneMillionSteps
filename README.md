# 1 Million Steps

A mobile idle game where real walking is the resource. Walk, open the app, turn your steps into coins, spend them on upgrades and helpers that keep earning while you're away. The goal is **1,000,000 lifetime steps**, about 134 days at 7,500 a day. Lifetime steps can never be bought, multiplied or reset.

Built with Flutter. Targets Android and iOS; Windows desktop is used for quick testing.

## Status

Early development. Playable core loop; steps come from a debug button for now.

**Done**
- Lifetime step progress toward 1,000,000
- Collect steps as coins (1 coin per step, +1 per shoe level)
- Shoe upgrades (100 coins, +60% per level)
- Six helpers that earn per minute and unlock at step milestones
- Away income for up to 8 hours
- Daily cap of 50,000 counted steps
- Coin bonus at 25k, 75k, 125k ... steps
- Local save

**Next**
- Real steps from Health Connect (Android) and Apple Health (iOS)
- Streak, boost and prestige (Soles)
- Daily goal, stats screen and reminders
- Finish card, rewarded ads and supporter pack

## Run

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install).

```
flutter pub get
flutter run -d windows     # or pick an Android emulator / device
flutter test
```

In debug builds, the **+1,000 steps (debug)** button simulates walking.

## Project layout

```
lib/
  game/     rules and state: balance numbers (config.dart), formulas, controller, save
  steps/    step sources (fake for now, health data next)
  ui/       screens and formatting
test/       unit and widget tests
```

All balance numbers live in `lib/game/config.dart`.
