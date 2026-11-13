import 'config.dart';

/// Everything that is saved between sessions.
class GameState {
  GameState({
    required this.installedAt,
    required this.lastSeen,
    this.coins = 0,
    this.lifetimeSteps = 0,
    this.pendingSteps = 0,
    this.shoeLevel = 0,
    List<int>? generatorsOwned,
    Map<String, int>? countedByDay,
    this.milestoneBonusesClaimed = 0,
  })  : generatorsOwned =
            generatorsOwned ?? List.filled(generatorDefs.length, 0),
        countedByDay = countedByDay ?? {};

  factory GameState.fresh(DateTime now) =>
      GameState(installedAt: now, lastSeen: now);

  /// Steps are only counted from this moment on.
  final DateTime installedAt;

  /// Last time generator income was paid out.
  DateTime lastSeen;

  double coins;

  /// Counted real steps. Only ever goes up; never bought, multiplied or reset.
  int lifetimeSteps;

  /// Counted steps not yet turned into coins.
  int pendingSteps;

  int shoeLevel;
  final List<int> generatorsOwned;

  /// Steps already counted per day ("yyyy-mm-dd"), after the daily cap.
  final Map<String, int> countedByDay;

  int milestoneBonusesClaimed;

  Map<String, dynamic> toJson() => {
        'v': 1,
        'installedAt': installedAt.toIso8601String(),
        'lastSeen': lastSeen.toIso8601String(),
        'coins': coins,
        'lifetimeSteps': lifetimeSteps,
        'pendingSteps': pendingSteps,
        'shoeLevel': shoeLevel,
        'generatorsOwned': generatorsOwned,
        'countedByDay': countedByDay,
        'milestoneBonusesClaimed': milestoneBonusesClaimed,
      };

  factory GameState.fromJson(Map<String, dynamic> j) {
    final owned = List<int>.filled(generatorDefs.length, 0);
    final saved = (j['generatorsOwned'] as List?) ?? const [];
    for (var i = 0; i < saved.length && i < owned.length; i++) {
      owned[i] = (saved[i] as num).toInt();
    }
    return GameState(
      installedAt: DateTime.parse(j['installedAt'] as String),
      lastSeen: DateTime.parse(j['lastSeen'] as String),
      coins: (j['coins'] as num?)?.toDouble() ?? 0,
      lifetimeSteps: (j['lifetimeSteps'] as num?)?.toInt() ?? 0,
      pendingSteps: (j['pendingSteps'] as num?)?.toInt() ?? 0,
      shoeLevel: (j['shoeLevel'] as num?)?.toInt() ?? 0,
      generatorsOwned: owned,
      countedByDay: ((j['countedByDay'] as Map?) ?? const {})
          .map((k, v) => MapEntry(k as String, (v as num).toInt())),
      milestoneBonusesClaimed:
          (j['milestoneBonusesClaimed'] as num?)?.toInt() ?? 0,
    );
  }
}
