import 'dart:math';

import 'config.dart';

/// Pure formulas from the design doc. No state, no clocks.

double shoeCost(int level) =>
    Tuning.shoeBaseCost * pow(Tuning.shoeCostGrowth, level);

double generatorCost(GeneratorDef def, int owned) =>
    def.baseCost * pow(Tuning.generatorCostGrowth, owned);

/// 1 coin per step, plus 1 per shoe level, times all bonuses.
double coinsPerStep(int shoeLevel, {double multiplier = 1}) =>
    (1 + shoeLevel) * multiplier;

double incomePerMinute(List<int> owned, {double multiplier = 1}) {
  var total = 0.0;
  for (var i = 0; i < generatorDefs.length; i++) {
    total += generatorDefs[i].perMinute * owned[i];
  }
  return total * multiplier;
}

/// Time to pay out for, between [from] and [to], never negative, at most [cap].
Duration cappedElapsed(DateTime from, DateTime to, Duration cap) {
  final d = to.difference(from);
  if (d.isNegative) return Duration.zero;
  return d > cap ? cap : d;
}

/// How many milestone coin bonuses [lifetimeSteps] has reached in total.
int milestoneBonusesReached(int lifetimeSteps) {
  if (lifetimeSteps < Tuning.milestoneBonusFirst) return 0;
  return (lifetimeSteps - Tuning.milestoneBonusFirst) ~/
          Tuning.milestoneBonusEvery +
      1;
}

/// Steps from a day's total that count, after the daily cap.
int countableDailySteps(int dayTotal) =>
    dayTotal.clamp(0, Tuning.dailyStepCap);

String dayKey(DateTime t) =>
    '${t.year.toString().padLeft(4, '0')}-'
    '${t.month.toString().padLeft(2, '0')}-'
    '${t.day.toString().padLeft(2, '0')}';
