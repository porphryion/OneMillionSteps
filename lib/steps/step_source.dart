import '../game/economy.dart';

/// Where real steps come from. The game only trusts what this reports.
abstract class StepSource {
  /// Recorded step totals per local day ("yyyy-mm-dd"), counting only steps
  /// taken at or after [since]. Implementations must exclude hand-typed steps.
  Future<Map<String, int>> dailyTotalsSince(DateTime since);
}

/// Development stand-in until Health Connect / Apple Health are wired up.
/// Steps are added by hand from a debug button.
class FakeStepSource implements StepSource {
  FakeStepSource({
    DateTime Function()? clock,
    Map<String, int>? initial,
    this.onChanged,
  }) : _clock = clock ?? DateTime.now,
       _totals = {...?initial};

  final DateTime Function() _clock;
  final Map<String, int> _totals;

  /// Called with all totals after every change, so they can be persisted.
  final void Function(Map<String, int> totals)? onChanged;

  void addSteps(int steps, {DateTime? at}) {
    final key = dayKey(at ?? _clock());
    _totals[key] = (_totals[key] ?? 0) + steps;
    onChanged?.call(Map.of(_totals));
  }

  @override
  Future<Map<String, int>> dailyTotalsSince(DateTime since) async =>
      Map.of(_totals);
}
