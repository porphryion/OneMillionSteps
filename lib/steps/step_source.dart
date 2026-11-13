import '../game/economy.dart';

/// Where real steps come from. The game only trusts what this reports.
abstract class StepSource {
  /// Recorded step totals per local day ("yyyy-mm-dd"), counting only steps
  /// taken at or after [since]. Implementations must exclude hand-typed steps.
  Future<Map<String, int>> dailyTotalsSince(DateTime since);
}

/// Development stand-in until Health Connect is wired up.
/// Steps are added by hand from a debug button and kept in memory only.
class FakeStepSource implements StepSource {
  FakeStepSource({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final Map<String, int> _totals = {};

  void addSteps(int steps, {DateTime? at}) {
    final key = dayKey(at ?? _clock());
    _totals[key] = (_totals[key] ?? 0) + steps;
  }

  @override
  Future<Map<String, int>> dailyTotalsSince(DateTime since) async =>
      Map.of(_totals);
}
