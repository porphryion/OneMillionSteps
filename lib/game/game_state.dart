import 'catalog.dart';
import 'economy.dart';
import 'models.dart';

/// The race or training walk the player is on now. Only one at a time.
class ActiveRace {
  ActiveRace({
    required this.courseId,
    required this.week,
    required this.joinedAt,
    this.steps = 0,
    this.meters = 0,
  });

  final String courseId;

  /// Schedule week of a weekly race; null for a training walk.
  final int? week;
  final DateTime joinedAt;

  bool get isTraining => week == null;

  /// Steps that went into this race.
  int steps;

  /// Race distance covered, gear bonuses included.
  double meters;

  String get joinedDay => dayKey(joinedAt);

  Map<String, dynamic> toJson() => {
    'courseId': courseId,
    'week': week,
    'joinedAt': joinedAt.toIso8601String(),
    'steps': steps,
    'meters': meters,
  };

  factory ActiveRace.fromJson(Map<String, dynamic> j) => ActiveRace(
    courseId: j['courseId'] as String,
    week: (j['week'] as num?)?.toInt(),
    joinedAt: DateTime.parse(j['joinedAt'] as String),
    steps: (j['steps'] as num?)?.toInt() ?? 0,
    meters: (j['meters'] as num?)?.toDouble() ?? 0,
  );
}

enum RaceOutcome { finished, timeUp, withdrew }

/// How a race ended. Kept forever as the medal history.
class RaceResult {
  const RaceResult({
    required this.courseId,
    required this.week,
    required this.outcome,
    required this.endedAt,
    required this.meters,
    this.medal,
    this.coins = 0,
    this.daysUsed = 0,
  });

  final String courseId;

  /// Null for a training walk.
  final int? week;
  final RaceOutcome outcome;
  final DateTime endedAt;

  /// Distance covered when the race ended.
  final double meters;

  /// Set only when a weekly race finished.
  final Medal? medal;
  final int coins;

  /// Calendar days from joining to finishing, join day counted as 1.
  final int daysUsed;

  Course get course => courseById[courseId]!;
  bool get isTraining => week == null;

  Map<String, dynamic> toJson() => {
    'courseId': courseId,
    'week': week,
    'outcome': outcome.name,
    'endedAt': endedAt.toIso8601String(),
    'meters': meters,
    'medal': medal?.name,
    'coins': coins,
    'daysUsed': daysUsed,
  };

  factory RaceResult.fromJson(Map<String, dynamic> j) {
    final medal = j['medal'] as String?;
    return RaceResult(
      courseId: j['courseId'] as String,
      week: (j['week'] as num?)?.toInt(),
      outcome: RaceOutcome.values.byName(j['outcome'] as String),
      endedAt: DateTime.parse(j['endedAt'] as String),
      meters: (j['meters'] as num?)?.toDouble() ?? 0,
      medal: medal == null ? null : Medal.values.byName(medal),
      coins: (j['coins'] as num?)?.toInt() ?? 0,
      daysUsed: (j['daysUsed'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Everything that is saved between sessions.
class GameState {
  GameState({
    required this.installedAt,
    this.coins = 0,
    this.lifetimeSteps = 0,
    Map<String, int>? countedByDay,
    this.activeRace,
    List<RaceResult>? results,
    Set<String>? ownedGear,
    Map<GearSlot, String>? equipped,
  }) : countedByDay = countedByDay ?? {},
       results = results ?? [],
       ownedGear = ownedGear ?? {starterShoesId, starterOutfitId},
       equipped =
           equipped ??
           {GearSlot.shoes: starterShoesId, GearSlot.outfit: starterOutfitId};

  factory GameState.fresh(DateTime now, {int coins = 0}) =>
      GameState(installedAt: now, coins: coins);

  /// Save format. Older saves (the idle-game prototype) are discarded.
  static const int version = 2;

  /// Steps are only counted from this moment on.
  final DateTime installedAt;

  int coins;

  /// All counted real steps, for stats. Never bought or multiplied.
  int lifetimeSteps;

  /// Steps already counted per day ("yyyy-mm-dd"), after the daily cap.
  final Map<String, int> countedByDay;

  ActiveRace? activeRace;
  final List<RaceResult> results;
  final Set<String> ownedGear;
  final Map<GearSlot, String> equipped;

  Map<String, dynamic> toJson() => {
    'v': version,
    'installedAt': installedAt.toIso8601String(),
    'coins': coins,
    'lifetimeSteps': lifetimeSteps,
    'countedByDay': countedByDay,
    'activeRace': activeRace?.toJson(),
    'results': [for (final r in results) r.toJson()],
    'ownedGear': ownedGear.toList(),
    'equipped': {for (final e in equipped.entries) e.key.name: e.value},
  };

  /// Returns null for saves from another version. Drops races and gear that
  /// are no longer in the catalog.
  static GameState? fromJson(Map<String, dynamic> j) {
    if (j['v'] != version) return null;

    final race = j['activeRace'] == null
        ? null
        : ActiveRace.fromJson(j['activeRace'] as Map<String, dynamic>);
    final owned = {
      starterShoesId,
      starterOutfitId,
      for (final id in (j['ownedGear'] as List? ?? const []))
        if (gearById.containsKey(id)) id as String,
    };
    final equipped = {
      GearSlot.shoes: starterShoesId,
      GearSlot.outfit: starterOutfitId,
    };
    ((j['equipped'] as Map?) ?? const {}).forEach((slot, id) {
      final s = GearSlot.values.asNameMap()[slot];
      final g = gearById[id];
      if (s != null && g != null && g.slot == s && owned.contains(g.id)) {
        equipped[s] = g.id;
      }
    });

    return GameState(
      installedAt: DateTime.parse(j['installedAt'] as String),
      coins: (j['coins'] as num?)?.toInt() ?? 0,
      lifetimeSteps: (j['lifetimeSteps'] as num?)?.toInt() ?? 0,
      countedByDay: ((j['countedByDay'] as Map?) ?? const {}).map(
        (k, v) => MapEntry(k as String, (v as num).toInt()),
      ),
      activeRace: race != null && courseById.containsKey(race.courseId)
          ? race
          : null,
      results: [
        for (final r in (j['results'] as List? ?? const []))
          RaceResult.fromJson(r as Map<String, dynamic>),
      ].where((r) => courseById.containsKey(r.courseId)).toList(),
      ownedGear: owned,
      equipped: equipped,
    );
  }
}
