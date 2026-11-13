/// Game time with a whole-day offset, so a developer can jump ahead and test
/// multi-day races (medal tiers, the daily step cap, the weekly close).
/// Release builds keep the offset at zero.
class DebugClock {
  DebugClock({this._dayOffset = 0, this.onChanged});

  int _dayOffset;

  /// Called with the new offset after every jump, so it can be persisted.
  final void Function(int dayOffset)? onChanged;

  int get dayOffset => _dayOffset;

  /// The real time, [dayOffset] calendar days later.
  DateTime now() {
    final t = DateTime.now();
    return DateTime(
      t.year,
      t.month,
      t.day + _dayOffset,
      t.hour,
      t.minute,
      t.second,
      t.millisecond,
      t.microsecond,
    );
  }

  void nextDay() {
    _dayOffset++;
    onChanged?.call(_dayOffset);
  }
}
