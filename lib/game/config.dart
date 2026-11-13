/// All balance numbers live here so they can be tuned in one place.
class Tuning {
  /// Average stride. Turns steps into race distance before gear bonuses.
  static const double metersPerStep = 0.75;

  /// Max steps that count per calendar day. Guards against bad sensor data.
  static const int dailyStepCap = 50000;

  /// A new player can afford one budget item right away.
  static const int startingCoins = 400;

  /// Finish reward per kilometre of race distance, before the medal factor.
  static const int coinsPerKm = 20;

  /// Training walks pay this per kilometre on completion (no medals).
  static const int trainingCoinsPerKm = 15;

  /// Medal pace targets, in base steps per day (gear lowers the steps needed).
  /// Finishing within ceil(baseSteps / goldStepsPerDay) days earns gold, and so
  /// on. Bronze is any finish before the race closes.
  static const int goldStepsPerDay = 15000;
  static const int silverStepsPerDay = 10000;

  /// Share of the full coin reward each medal pays.
  static const double goldCoinFactor = 1.0;
  static const double silverCoinFactor = 0.75;
  static const double bronzeCoinFactor = 0.5;

  /// A Monday. Week 0 of the race schedule starts here (local time).
  static const int epochYear = 2024, epochMonth = 1, epochDay = 1;
}
