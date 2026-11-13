import 'package:flutter/foundation.dart';

import '../steps/step_source.dart';
import 'catalog.dart';
import 'config.dart';
import 'economy.dart' as eco;
import 'game_state.dart';
import 'game_store.dart';
import 'models.dart';
import 'schedule.dart';

class SyncResult {
  const SyncResult({this.newSteps = 0, this.raceSteps = 0, this.ended});

  /// Steps counted in this sync.
  final int newSteps;

  /// Of those, the steps that went into the active race or walk.
  final int raceSteps;

  /// Set when the active race or walk finished (or ran out of time).
  final RaceResult? ended;
}

/// Where a week's race stands for this player.
enum EventStatus { locked, upcoming, open, running, finished, missed, closed }

/// Where a training stage stands for this player.
enum StageStatus { locked, available, running, done }

enum JoinError { raceInProgress, notOpen, alreadyRun, locked }

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

  final List<RaceResult> _unseen = [];

  DateTime get now => _clock();
  int get currentWeek => weekIndexOf(now);
  List<MarathonEvent> get thisWeek => lineup(currentWeek);
  List<MarathonEvent> get nextWeek => lineup(currentWeek + 1);

  int get todaySteps => _state.countedByDay[eco.dayKey(now)] ?? 0;

  /// Today's steps hit the daily cap; more steps count again tomorrow.
  bool get dailyCapReached => todaySteps >= Tuning.dailyStepCap;

  // ---- Active race or walk ----

  ActiveRace? get race => _state.activeRace;

  /// Course of the active race or training walk.
  Course? get activeCourse {
    final r = race;
    return r == null ? null : courseById[r.courseId];
  }

  /// The active weekly race, or null (also null during a training walk).
  MarathonEvent? get raceEvent {
    final r = race;
    if (r == null || r.week == null) return null;
    return MarathonEvent(courseById[r.courseId]!, r.week!);
  }

  /// The active training stage, or null.
  TrainingStage? get activeStage {
    final r = race;
    return r == null || !r.isTraining ? null : stageByCourseId[r.courseId];
  }

  /// 0..1 share of the active course covered.
  double get raceProgress {
    final c = activeCourse;
    if (c == null) return 0;
    return (race!.meters / c.meters).clamp(0.0, 1.0);
  }

  /// Steps still needed to finish the active course with the current gear.
  int get stepsToFinish {
    final c = activeCourse;
    if (c == null) return 0;
    return eco.stepsFor(c.meters - race!.meters, bonusFor(c));
  }

  /// Day of the active race or walk, join day being day 1.
  int get raceDay =>
      race == null ? 0 : eco.daysBetween(race!.joinedDay, eco.dayKey(now)) + 1;

  // ---- Training ladder ----

  bool isStageDone(TrainingStage s) => _state.results.any(
    (r) => r.courseId == s.course.id && r.outcome == RaceOutcome.finished,
  );

  int get stagesDone => trainingStages.where(isStageDone).length;
  bool get trainingComplete => stagesDone == trainingStages.length;

  /// First stage not done yet, or null when the ladder is complete.
  TrainingStage? get nextStage =>
      trainingStages.where((s) => !isStageDone(s)).firstOrNull;

  StageStatus statusOfStage(TrainingStage s) {
    if (isStageDone(s)) return StageStatus.done;
    if (race?.courseId == s.course.id) return StageStatus.running;
    final previous = s.tier == 1 ? null : trainingStages[s.tier - 2];
    if (previous != null && !isStageDone(previous)) return StageStatus.locked;
    return StageStatus.available;
  }

  /// Whether weekly races of [length] can be joined.
  bool isLengthUnlocked(RaceLength length) {
    final gate = stageUnlocking(length);
    return gate == null || isStageDone(gate);
  }

  // ---- Weekly events ----

  RaceResult? resultFor(MarathonEvent e) => _state.results
      .where((r) => r.courseId == e.course.id && r.week == e.week)
      .lastOrNull;

  EventStatus statusOf(MarathonEvent e) {
    final r = race;
    if (r != null && r.courseId == e.course.id && r.week == e.week) {
      return EventStatus.running;
    }
    final result = resultFor(e);
    if (result != null) {
      return result.outcome == RaceOutcome.finished
          ? EventStatus.finished
          : EventStatus.missed;
    }
    if (!now.isBefore(e.closesAt)) return EventStatus.closed;
    if (!isLengthUnlocked(e.course.length)) return EventStatus.locked;
    if (now.isBefore(e.opensAt)) return EventStatus.upcoming;
    return EventStatus.open;
  }

  int daysLeft(MarathonEvent e) => eco.daysLeft(now, e.closesAt);

  /// Steps per day needed to finish [e] in time, from scratch or from the
  /// current progress if it is the active race.
  int stepsPerDayNeeded(MarathonEvent e) {
    final days = daysLeft(e);
    if (days == 0) return 0;
    final running = statusOf(e) == EventStatus.running;
    final steps = running
        ? stepsToFinish
        : eco.stepsFor(e.course.meters, bonusFor(e.course));
    return (steps / days).ceil();
  }

  // ---- Gear ----

  GearDef equippedIn(GearSlot slot) => gearById[_state.equipped[slot]]!;
  Iterable<GearDef> get equippedGear => GearSlot.values.map(equippedIn);
  bool owns(GearDef g) => _state.ownedGear.contains(g.id);
  bool isEquipped(GearDef g) => _state.equipped[g.slot] == g.id;
  bool canAfford(GearDef g) => _state.coins >= g.price;

  /// Combined bonus percentage of the equipped gear on [c].
  int bonusFor(Course c) => eco.bonusPct(equippedGear, c);

  /// Equipped gear's bonus on [c], split by where it comes from.
  ({int base, int weather, int terrain}) bonusParts(Course c) {
    var base = 0, weather = 0, terrain = 0;
    for (final g in equippedGear) {
      base += g.basePct;
      weather += g.weatherPct[c.weather] ?? 0;
      terrain += g.terrainPct[c.terrain] ?? 0;
    }
    return (base: base, weather: weather, terrain: terrain);
  }

  /// Bonus on [c] if [g] replaced the item in its slot.
  int bonusWith(GearDef g, Course c) => eco.bonusPct([
    for (final s in GearSlot.values) s == g.slot ? g : equippedIn(s),
  ], c);

  // ---- Lifecycle ----

  /// Loads the save (or starts fresh), then counts new steps.
  Future<void> load() async {
    _state =
        await _store.load() ??
        GameState.fresh(now, coins: Tuning.startingCoins);
    await syncSteps();
    await save();
  }

  Future<void> save() => _store.save(_state);

  /// Results the player has not been shown yet (finish or time up).
  List<RaceResult> takeUnseenResults() {
    final out = List.of(_unseen);
    _unseen.clear();
    return out;
  }

  /// Pulls new steps from the step source into the active race or walk, then
  /// closes a weekly race whose week is over. Safe to call any time.
  Future<SyncResult> syncSteps() async {
    final totals = await _steps.dailyTotalsSince(_state.installedAt);
    final days = totals.keys.toList()..sort();
    var added = 0;
    var raceSteps = 0;
    RaceResult? ended;

    for (final day in days) {
      final counted = eco.countableDailySteps(totals[day]!);
      final already = _state.countedByDay[day] ?? 0;
      if (counted <= already) continue;
      final delta = counted - already;
      _state.countedByDay[day] = counted;
      added += delta;

      final r = _state.activeRace;
      if (r == null || day.compareTo(r.joinedDay) < 0) continue;
      // Weekly races only count steps until they close.
      final event = raceEvent;
      if (event != null && day.compareTo(eco.dayKey(event.closesAt)) >= 0) {
        continue;
      }
      final course = activeCourse!;
      raceSteps += delta;
      r.steps += delta;
      r.meters += delta * eco.metersPerStep(bonusFor(course));
      if (r.meters >= course.meters) {
        ended = _end(r, RaceOutcome.finished, finishDay: day);
      }
    }
    _state.lifetimeSteps += added;
    ended ??= _expireIfClosed();

    if (added > 0 || ended != null) {
      notifyListeners();
      _save();
    }
    return SyncResult(newSteps: added, raceSteps: raceSteps, ended: ended);
  }

  /// Call after the clock jumps ahead (debug day skip): counts steps,
  /// closes races whose week is over and refreshes everything tied to today.
  Future<SyncResult> clockChanged() async {
    final result = await syncSteps();
    notifyListeners();
    return result;
  }

  // ---- Actions ----

  /// Starts [e] as the active race. Steps already taken today do not count.
  Future<JoinError?> join(MarathonEvent e) async {
    await syncSteps();
    if (_state.activeRace != null) return JoinError.raceInProgress;
    if (!e.isOpenAt(now)) return JoinError.notOpen;
    if (resultFor(e) != null) return JoinError.alreadyRun;
    if (!isLengthUnlocked(e.course.length)) return JoinError.locked;
    _start(e.course, week: e.week);
    return null;
  }

  /// Starts training stage [s]. Earlier stages must be done first.
  Future<JoinError?> startTraining(TrainingStage s) async {
    await syncSteps();
    if (_state.activeRace != null) return JoinError.raceInProgress;
    switch (statusOfStage(s)) {
      case StageStatus.done:
        return JoinError.alreadyRun;
      case StageStatus.locked:
        return JoinError.locked;
      case StageStatus.available:
      case StageStatus.running:
        break;
    }
    _start(s.course);
    return null;
  }

  /// Gives up the active race or walk; its progress is lost. A weekly race
  /// cannot be rejoined that week. A training walk can be restarted any time.
  RaceResult? withdraw() {
    final r = _state.activeRace;
    if (r == null) return null;
    RaceResult? result;
    if (r.isTraining) {
      _state.activeRace = null;
    } else {
      result = _end(r, RaceOutcome.withdrew, announce: false);
    }
    notifyListeners();
    _save();
    return result;
  }

  /// Buys and puts on [g].
  bool buy(GearDef g) {
    if (owns(g) || !canAfford(g)) return false;
    _state.coins -= g.price;
    _state.ownedGear.add(g.id);
    _state.equipped[g.slot] = g.id;
    notifyListeners();
    _save();
    return true;
  }

  bool equip(GearDef g) {
    if (!owns(g)) return false;
    if (isEquipped(g)) return true;
    _state.equipped[g.slot] = g.id;
    notifyListeners();
    _save();
    return true;
  }

  void _start(Course c, {int? week}) {
    _state.activeRace = ActiveRace(courseId: c.id, week: week, joinedAt: now);
    notifyListeners();
    _save();
  }

  RaceResult? _expireIfClosed() {
    final r = _state.activeRace;
    final event = raceEvent;
    if (r == null || event == null || now.isBefore(event.closesAt)) {
      return null;
    }
    return _end(r, RaceOutcome.timeUp);
  }

  RaceResult _end(
    ActiveRace r,
    RaceOutcome outcome, {
    String? finishDay,
    bool announce = true,
  }) {
    final course = courseById[r.courseId]!;
    Medal? medal;
    var coins = 0;
    var daysUsed = eco.daysBetween(r.joinedDay, eco.dayKey(now)) + 1;
    if (outcome == RaceOutcome.finished) {
      daysUsed = eco.daysBetween(r.joinedDay, finishDay!) + 1;
      if (r.isTraining) {
        coins = eco.trainingReward(course);
      } else {
        medal = eco.medalFor(course, daysUsed);
        coins = eco.rewardCoins(course, medal);
      }
      _state.coins += coins;
    }
    final result = RaceResult(
      courseId: r.courseId,
      week: r.week,
      outcome: outcome,
      endedAt: now,
      meters: r.meters.clamp(0, course.meters).toDouble(),
      medal: medal,
      coins: coins,
      daysUsed: daysUsed,
    );
    _state.results.add(result);
    _state.activeRace = null;
    if (announce) _unseen.add(result);
    return result;
  }

  void _save() => _store.save(_state);
}
