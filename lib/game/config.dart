/// All balance numbers live here so they can be tuned in one place.
/// Values marked "tunable" are not fixed by the design doc.
class Tuning {
  static const int goalSteps = 1000000;

  /// Max steps that count toward the game per calendar day.
  static const int dailyStepCap = 50000;

  /// Generators keep earning while the app is closed, up to this long.
  static const Duration offlineCap = Duration(hours: 8);

  static const double shoeBaseCost = 100;
  static const double shoeCostGrowth = 1.6;
  static const double generatorCostGrowth = 1.15;

  /// Coin bonus "every other 25,000 steps": at 25k, 75k, 125k, ...
  static const int milestoneBonusFirst = 25000;
  static const int milestoneBonusEvery = 50000;

  /// Bonus size, expressed as this many steps' worth of coins. (tunable)
  static const int milestoneBonusSteps = 2500;
}

class GeneratorDef {
  const GeneratorDef({
    required this.id,
    required this.name,
    required this.unlockAt,
    required this.baseCost,
    required this.perMinute,
  });

  final String id;
  final String name;

  /// Lifetime steps needed before this generator can be bought.
  final int unlockAt;

  /// Cost of the first one (tunable).
  final double baseCost;

  /// Coins per minute earned by each one owned (tunable).
  final double perMinute;
}

const List<GeneratorDef> generatorDefs = [
  GeneratorDef(id: 'paperboy', name: 'Paperboy', unlockAt: 0, baseCost: 50, perMinute: 1),
  GeneratorDef(id: 'dog_walker', name: 'Dog walker', unlockAt: 10000, baseCost: 1000, perMinute: 12),
  GeneratorDef(id: 'courier', name: 'Courier', unlockAt: 50000, baseCost: 15000, perMinute: 90),
  GeneratorDef(id: 'bike_shop', name: 'Bike shop', unlockAt: 150000, baseCost: 120000, perMinute: 500),
  GeneratorDef(id: 'shoe_factory', name: 'Shoe factory', unlockAt: 400000, baseCost: 1000000, perMinute: 3000),
  GeneratorDef(id: 'marathon_sponsor', name: 'Marathon sponsor', unlockAt: 700000, baseCost: 8000000, perMinute: 15000),
];
