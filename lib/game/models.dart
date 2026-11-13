import 'config.dart';

/// Race weather. Gear can give a bonus for each.
enum Weather {
  sunny('Güneşli'),
  hot('Sıcak'),
  rainy('Yağmurlu'),
  windy('Rüzgârlı'),
  cold('Soğuk');

  const Weather(this.label);
  final String label;
}

/// Race surface. Gear can give a bonus for each.
enum Terrain {
  asphalt('Asfalt'),
  trail('Patika'),
  cobblestone('Arnavut kaldırımı'),
  sand('Kum'),
  mountain('Dağ');

  const Terrain(this.label);
  final String label;
}

/// Turkey's seven geographic regions. Each gives its races a color.
enum Region {
  marmara('Marmara'),
  aegean('Ege'),
  mediterranean('Akdeniz'),
  centralAnatolia('İç Anadolu'),
  blackSea('Karadeniz'),
  eastAnatolia('Doğu Anadolu'),
  southeastAnatolia('Güneydoğu Anadolu');

  const Region(this.label);
  final String label;
}

/// Weekly races come in three lengths. Training walks are the ladder that
/// unlocks them.
enum RaceLength {
  training('Hazırlık', 'Hazırlık yürüyüşleri'),
  short('Kısa', 'Kısa yarışlar'),
  medium('Orta', 'Yarı maraton ve maratonlar'),
  ultra('Ultra', 'Ultra maratonlar');

  const RaceLength(this.label, this.plural);
  final String label;

  /// Name for the whole group, e.g. in "Kısa yarışlar açılır".
  final String plural;
}

enum Medal {
  gold('Altın', Tuning.goldCoinFactor),
  silver('Gümüş', Tuning.silverCoinFactor),
  bronze('Bronz', Tuning.bronzeCoinFactor);

  const Medal(this.label, this.coinFactor);
  final String label;
  final double coinFactor;
}

enum GearSlot {
  shoes('Ayakkabı'),
  outfit('Eşofman takımı');

  const GearSlot(this.label);
  final String label;
}

/// Color family for gear art. The UI maps each to a theme color.
enum GearTint { blue, teal, cyan, ochre, green, violet, red, slate }

/// A route: a weekly race or a training walk. Static data.
class Course {
  const Course({
    required this.id,
    required this.name,
    required this.city,
    this.region,
    required this.length,
    required this.km,
    required this.weather,
    required this.terrain,
    required this.blurb,
  });

  final String id;
  final String name;

  /// Place line under the name ("İstanbul", or "Mahalle parkı" for walks).
  final String city;

  /// Null for training walks.
  final Region? region;
  final RaceLength length;
  final double km;
  final Weather weather;
  final Terrain terrain;
  final String blurb;

  double get meters => km * 1000;
}

/// One rung of the training ladder. Rungs open in order; some also open a
/// weekly race length.
class TrainingStage {
  const TrainingStage({required this.tier, required this.course, this.unlocks});

  /// 1-based position on the ladder.
  final int tier;
  final Course course;

  /// Weekly race length that opens when this stage is done.
  final RaceLength? unlocks;
}

/// Shoes or a tracksuit set. Bonuses are percentages added to stride length.
class GearDef {
  const GearDef({
    required this.id,
    required this.name,
    required this.slot,
    required this.price,
    required this.blurb,
    required this.tint,
    this.basePct = 0,
    this.weatherPct = const {},
    this.terrainPct = const {},
  });

  final String id;
  final String name;
  final GearSlot slot;
  final int price;
  final String blurb;
  final GearTint tint;

  /// Applies on every course.
  final int basePct;
  final Map<Weather, int> weatherPct;
  final Map<Terrain, int> terrainPct;

  int bonusFor(Course c) =>
      basePct + (weatherPct[c.weather] ?? 0) + (terrainPct[c.terrain] ?? 0);
}
