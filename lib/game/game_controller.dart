import 'package:flutter/foundation.dart';

import '../steps/step_source.dart';
import 'config.dart';
import 'economy.dart' as eco;
import 'game_state.dart';
import 'game_store.dart';

class SyncResult {
  const SyncResult({this.newSteps = 0, this.bonusCoins = 0});
  final int newSteps;
  final double bonusCoins;
}

/// Owns the game state and every rule that changes it.
class GameController extends ChangeNotifier {
  GameController({
    required this._store,
    required this._steps,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final GameStore _store;
  final StepSource _steps;
  final DateTime Function() _clock;

  late GameState _state;
  GameState get state => _state;

  /// Combined prestige x streak x boost bonus. All 1x until those land.
  double get multiplier => 1.0;

  double get coinsPerStep =>
      eco.coinsPerStep(_state.shoeLevel, multiplier: multiplier);
  double get incomePerMinute =>
      eco.incomePerMinute(_state.generatorsOwned, multiplier: multiplier);
  double get pendingCoins => _state.pendingSteps * coinsPerStep;
  double get nextShoeCost => eco.shoeCost(_state.shoeLevel);
  double generatorPrice(int i) =>
      eco.generatorCost(generatorDefs[i], _state.generatorsOwned[i]);
  bool isUnlocked(int i) =>
      _state.lifetimeSteps >= generatorDefs[i].unlockAt;
  double get progress =>
      (_state.lifetimeSteps / Tuning.goalSteps).clamp(0.0, 1.0);

  /// Loads the save (or starts fresh) and pays out time away.
  /// Returns the coins earned while away.
  Future<double> load() async {
    _state = await _store.load() ?? GameState.fresh(_clock());
    final earned = _accrue();
    await syncSteps();
    _save();
    return earned;
  }

  /// Call when the app comes back to the foreground.
  Future<double> resume() async {
    final earned = _accrue();
    await syncSteps();
    notifyListeners();
    _save();
    return earned;
  }

  /// Call once a second while the app is open.
  void tick() {
    if (_accrue() > 0) notifyListeners();
  }

  Future<void> save() => _store.save(_state);

  /// Pulls new steps from the step source into lifetime and pending steps.
  Future<SyncResult> syncSteps() async {
    final totals = await _steps.dailyTotalsSince(_state.installedAt);
    var added = 0;
    totals.forEach((day, total) {
      final counted = eco.countableDailySteps(total);
      final already = _state.countedByDay[day] ?? 0;
      if (counted > already) {
        added += counted - already;
        _state.countedByDay[day] = counted;
      }
    });
    if (added == 0) return const SyncResult();

    _state.lifetimeSteps += added;
    _state.pendingSteps += added;

    var bonus = 0.0;
    final reached = eco.milestoneBonusesReached(_state.lifetimeSteps);
    if (reached > _state.milestoneBonusesClaimed) {
      bonus = (reached - _state.milestoneBonusesClaimed) *
          Tuning.milestoneBonusSteps *
          coinsPerStep;
      _state.coins += bonus;
      _state.milestoneBonusesClaimed = reached;
    }
    notifyListeners();
    _save();
    return SyncResult(newSteps: added, bonusCoins: bonus);
  }

  /// Turns pending steps into coins. Returns coins gained.
  double collect() {
    final gained = pendingCoins;
    if (gained <= 0) return 0;
    _state.coins += gained;
    _state.pendingSteps = 0;
    notifyListeners();
    _save();
    return gained;
  }

  bool buyShoes() {
    final cost = nextShoeCost;
    if (_state.coins < cost) return false;
    _state.coins -= cost;
    _state.shoeLevel++;
    notifyListeners();
    _save();
    return true;
  }

  bool buyGenerator(int i) {
    if (!isUnlocked(i)) return false;
    final cost = generatorPrice(i);
    if (_state.coins < cost) return false;
    _state.coins -= cost;
    _state.generatorsOwned[i]++;
    notifyListeners();
    _save();
    return true;
  }

  /// Pays generator income for time since [GameState.lastSeen], capped.
  double _accrue() {
    final now = _clock();
    final elapsed = eco.cappedElapsed(_state.lastSeen, now, Tuning.offlineCap);
    _state.lastSeen = now;
    final earned = incomePerMinute *
        elapsed.inMicroseconds /
        Duration.microsecondsPerMinute;
    _state.coins += earned;
    return earned;
  }

  void _save() => _store.save(_state);
}
