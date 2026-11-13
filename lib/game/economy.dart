import 'config.dart';
import 'models.dart';

/// Pure formulas. No state, no clocks.

/// Total bonus percentage the given gear gives on [course].
int bonusPct(Iterable<GearDef> gear, Course course) =>
    gear.fold(0, (sum, g) => sum + g.bonusFor(course));

/// Race distance one step covers with [bonus] percent.
double metersPerStep(int bonus) => Tuning.metersPerStep * (1 + bonus / 100);

/// Steps needed to cover [meters] with [bonus] percent.
int stepsFor(double meters, int bonus) =>
    meters <= 0 ? 0 : (meters / metersPerStep(bonus)).ceil();

/// Steps a course takes without any gear bonus.
int baseSteps(Course c) => stepsFor(c.meters, 0);

/// Finish within this many calendar days (join day = day 1) for gold.
int goldDays(Course c) => (baseSteps(c) / Tuning.goldStepsPerDay).ceil();

/// Finish within this many calendar days for silver.
int silverDays(Course c) => (baseSteps(c) / Tuning.silverStepsPerDay).ceil();

Medal medalFor(Course c, int daysUsed) {
  if (daysUsed <= goldDays(c)) return Medal.gold;
  if (daysUsed <= silverDays(c)) return Medal.silver;
  return Medal.bronze;
}

int rewardCoins(Course c, Medal m) =>
    (c.km * Tuning.coinsPerKm * m.coinFactor).round();

int trainingReward(Course c) => (c.km * Tuning.trainingCoinsPerKm).round();

/// Steps from a day's total that count, after the daily cap.
int countableDailySteps(int dayTotal) => dayTotal.clamp(0, Tuning.dailyStepCap);

/// "yyyy-mm-dd" for local time [t]. Sorts chronologically as a string.
String dayKey(DateTime t) =>
    '${t.year.toString().padLeft(4, '0')}-'
    '${t.month.toString().padLeft(2, '0')}-'
    '${t.day.toString().padLeft(2, '0')}';

/// Whole calendar days from day [from] to day [to] (both "yyyy-mm-dd").
int daysBetween(String from, String to) {
  DateTime parse(String k) {
    final p = k.split('-').map(int.parse).toList();
    return DateTime.utc(p[0], p[1], p[2]);
  }

  return parse(to).difference(parse(from)).inDays;
}

/// Calendar days left to run, counting today, before [closesAt] (midnight).
int daysLeft(DateTime now, DateTime closesAt) {
  if (!now.isBefore(closesAt)) return 0;
  return daysBetween(dayKey(now), dayKey(closesAt));
}
