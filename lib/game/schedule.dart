import 'catalog.dart';
import 'config.dart';
import 'models.dart';

/// One race in one week. Opens Monday 00:00 local, closes the next Monday.
class MarathonEvent {
  const MarathonEvent(this.course, this.week);

  final Course course;
  final int week;

  String get id => '${course.id}@$week';
  DateTime get opensAt => weekStart(week);
  DateTime get closesAt => weekStart(week + 1);

  bool isOpenAt(DateTime t) => !t.isBefore(opensAt) && t.isBefore(closesAt);

  @override
  bool operator ==(Object other) => other is MarathonEvent && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Index of the schedule week containing local time [t].
int weekIndexOf(DateTime t) {
  final days = DateTime.utc(t.year, t.month, t.day)
      .difference(
        DateTime.utc(Tuning.epochYear, Tuning.epochMonth, Tuning.epochDay),
      )
      .inDays;
  return (days / 7).floor();
}

/// Local midnight on the Monday that starts [week].
DateTime weekStart(int week) =>
    DateTime(Tuning.epochYear, Tuning.epochMonth, Tuning.epochDay + 7 * week);

/// The races that open in [week]: one from each pool, rotating weekly.
List<MarathonEvent> lineup(int week) => [
  for (final pool in coursePools) MarathonEvent(pool[week % pool.length], week),
];
