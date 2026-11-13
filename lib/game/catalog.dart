import 'models.dart';

// Race names use geography plus a descriptive word. Real event names, logos
// and sportswear brands are off limits (see design-system/MASTER.md §9).

/// The training ladder. Always open, done in order, no time limit.
/// Stage 4 opens short races, 5 opens marathons, 6 opens ultras.
const List<TrainingStage> trainingStages = [
  TrainingStage(
    tier: 1,
    course: Course(
      id: 'hazirlik_park',
      name: 'Park Yürüyüşü',
      city: 'Mahalle parkı',
      length: RaceLength.training,
      km: 2,
      weather: Weather.sunny,
      terrain: Terrain.trail,
      blurb: 'Ilık bir başlangıç: ağaçların altında kısa bir tur.',
    ),
  ),
  TrainingStage(
    tier: 2,
    course: Course(
      id: 'hazirlik_sahil',
      name: 'Sahil Yürüyüşü',
      city: 'Sahil yolu',
      length: RaceLength.training,
      km: 3,
      weather: Weather.windy,
      terrain: Terrain.asphalt,
      blurb: 'Deniz kenarında, rüzgârı arkana alarak.',
    ),
  ),
  TrainingStage(
    tier: 3,
    course: Course(
      id: 'hazirlik_orman',
      name: 'Orman Yürüyüşü',
      city: 'Şehir ormanı',
      length: RaceLength.training,
      km: 5,
      weather: Weather.rainy,
      terrain: Terrain.trail,
      blurb: 'Islak toprak, çam kokusu ve yumuşak patikalar.',
    ),
  ),
  TrainingStage(
    tier: 4,
    unlocks: RaceLength.short,
    course: Course(
      id: 'hazirlik_tepe',
      name: 'Tepe Yürüyüşü',
      city: 'Şehrin tepeleri',
      length: RaceLength.training,
      km: 8,
      weather: Weather.cold,
      terrain: Terrain.mountain,
      blurb: 'Soğuk havada ilk ciddi yokuşlar.',
    ),
  ),
  TrainingStage(
    tier: 5,
    unlocks: RaceLength.medium,
    course: Course(
      id: 'hazirlik_sehir',
      name: 'Şehir Turu',
      city: 'Tarihi çarşı',
      length: RaceLength.training,
      km: 15,
      weather: Weather.hot,
      terrain: Terrain.cobblestone,
      blurb: 'Sıcakta taş sokaklar ve kalabalık çarşılar.',
    ),
  ),
  TrainingStage(
    tier: 6,
    unlocks: RaceLength.ultra,
    course: Course(
      id: 'hazirlik_uzun',
      name: 'Dayanıklılık Yürüyüşü',
      city: 'Uzun kumsal',
      length: RaceLength.training,
      km: 30,
      weather: Weather.sunny,
      terrain: Terrain.sand,
      blurb: 'Kumda uzun bir gün: ultraya son hazırlık.',
    ),
  ),
];

final Map<String, TrainingStage> stageByCourseId = {
  for (final s in trainingStages) s.course.id: s,
};

/// The stage that opens [length], or null if nothing gates it.
TrainingStage? stageUnlocking(RaceLength length) =>
    trainingStages.where((s) => s.unlocks == length).firstOrNull;

/// Short courses (10–15 km). One opens every week.
const List<Course> shortCourses = [
  Course(
    id: 'bodrum_10k',
    name: 'Bodrum Rüzgârı 10K',
    city: 'Muğla',
    region: Region.aegean,
    length: RaceLength.short,
    km: 10,
    weather: Weather.windy,
    terrain: Terrain.asphalt,
    blurb: 'Marina boyunca, poyraza karşı düz bir sahil yolu.',
  ),
  Course(
    id: 'konaklar_12k',
    name: 'Konaklar Arası 12K',
    city: 'Safranbolu',
    region: Region.blackSea,
    length: RaceLength.short,
    km: 12,
    weather: Weather.rainy,
    terrain: Terrain.cobblestone,
    blurb: 'Ahşap konakların arasından ıslak kaldırımlar.',
  ),
  Course(
    id: 'beyaz_kumsal_15k',
    name: 'Beyaz Kumsal 15K',
    city: 'Burdur',
    region: Region.mediterranean,
    length: RaceLength.short,
    km: 15,
    weather: Weather.sunny,
    terrain: Terrain.sand,
    blurb: 'Salda Gölü kıyısında bembeyaz kum.',
  ),
  Course(
    id: 'tas_sokaklar_15k',
    name: 'Taş Sokaklar 15K',
    city: 'Mardin',
    region: Region.southeastAnatolia,
    length: RaceLength.short,
    km: 15,
    weather: Weather.hot,
    terrain: Terrain.cobblestone,
    blurb: 'Mezopotamya ovasına bakan taş evlerin arasından.',
  ),
  Course(
    id: 'surlar_10k',
    name: 'Surlar 10K',
    city: 'İstanbul',
    region: Region.marmara,
    length: RaceLength.short,
    km: 10,
    weather: Weather.sunny,
    terrain: Terrain.cobblestone,
    blurb: 'Tarihi yarımadanın surları boyunca taş sokaklar.',
  ),
];

/// Half marathon to marathon distance. One opens every week.
const List<Course> mediumCourses = [
  Course(
    id: 'zeytin_rotasi',
    name: 'Zeytin Rotası Yarı Maratonu',
    city: 'Aydın',
    region: Region.aegean,
    length: RaceLength.medium,
    km: 21.1,
    weather: Weather.hot,
    terrain: Terrain.trail,
    blurb: 'Asırlık zeytinliklerin arasından toprak yollar.',
  ),
  Course(
    id: 'bozkir_yari',
    name: 'Bozkır Yarı Maratonu',
    city: 'Ankara',
    region: Region.centralAnatolia,
    length: RaceLength.medium,
    km: 21.1,
    weather: Weather.cold,
    terrain: Terrain.asphalt,
    blurb: 'Başkentin ayazında geniş bulvarlar.',
  ),
  Course(
    id: 'turkuaz_kiyi',
    name: 'Turkuaz Kıyı Maratonu',
    city: 'Antalya',
    region: Region.mediterranean,
    length: RaceLength.medium,
    km: 42.2,
    weather: Weather.hot,
    terrain: Terrain.asphalt,
    blurb: 'Kaş ile Kalkan arasında, denize bakan sahil yolu.',
  ),
  Course(
    id: 'firtina_vadisi',
    name: 'Fırtına Vadisi Koşusu',
    city: 'Rize',
    region: Region.blackSea,
    length: RaceLength.medium,
    km: 30,
    weather: Weather.rainy,
    terrain: Terrain.trail,
    blurb: 'Taş köprüler, çay bahçeleri ve sisli patikalar.',
  ),
  Course(
    id: 'bogaz_maratonu',
    name: 'Boğaz Maratonu',
    city: 'İstanbul',
    region: Region.marmara,
    length: RaceLength.medium,
    km: 42.2,
    weather: Weather.windy,
    terrain: Terrain.asphalt,
    blurb: 'İki kıta arasında, Boğaz kıyısı boyunca 42 kilometre.',
  ),
];

/// Ultras (50–60 km). One opens every week.
const List<Course> ultraCourses = [
  Course(
    id: 'yayla_yolu_ultra',
    name: 'Yayla Yolu Ultra',
    city: 'Artvin',
    region: Region.blackSea,
    length: RaceLength.ultra,
    km: 50,
    weather: Weather.rainy,
    terrain: Terrain.mountain,
    blurb: 'Kaçkarların eteklerinden yaylalara tırmanış.',
  ),
  Course(
    id: 'gun_dogumu_ultra',
    name: 'Gün Doğumu Ultra',
    city: 'Adıyaman',
    region: Region.southeastAnatolia,
    length: RaceLength.ultra,
    km: 50,
    weather: Weather.hot,
    terrain: Terrain.mountain,
    blurb: 'Nemrut’un dev heykellerine doğru uzun bir tırmanış.',
  ),
  Course(
    id: 'ayaz_ultra',
    name: 'Ayaz Ultra',
    city: 'Erzurum',
    region: Region.eastAnatolia,
    length: RaceLength.ultra,
    km: 50,
    weather: Weather.cold,
    terrain: Terrain.mountain,
    blurb: 'Karlı zirveler, eksi dereceler, bitmeyen yokuşlar.',
  ),
  Course(
    id: 'kumul_ultra',
    name: 'Kumul Ultra',
    city: 'Antalya',
    region: Region.mediterranean,
    length: RaceLength.ultra,
    km: 55,
    weather: Weather.hot,
    terrain: Terrain.sand,
    blurb: 'Patara kumulları ve antik kentin kalıntıları arasında.',
  ),
  Course(
    id: 'peri_bacalari_ultra',
    name: 'Peri Bacaları Ultra',
    city: 'Nevşehir',
    region: Region.centralAnatolia,
    length: RaceLength.ultra,
    km: 60,
    weather: Weather.sunny,
    terrain: Terrain.trail,
    blurb: 'Vadiler, peri bacaları ve gün doğumunda balonlar.',
  ),
];

/// One pool per weekly slot, in the order races are listed.
const List<List<Course>> coursePools = [
  shortCourses,
  mediumCourses,
  ultraCourses,
];

final Map<String, Course> courseById = {
  for (final s in trainingStages) s.course.id: s.course,
  for (final pool in coursePools)
    for (final c in pool) c.id: c,
};

const String starterShoesId = 'shoe_starter';
const String starterOutfitId = 'outfit_starter';

const List<GearDef> gearDefs = [
  // Shoes
  GearDef(
    id: starterShoesId,
    name: 'Mahalle Klasiği',
    slot: GearSlot.shoes,
    price: 0,
    blurb: 'Her şey bununla başladı.',
    tint: GearTint.slate,
  ),
  GearDef(
    id: 'shoe_asphalt',
    name: 'Asfalt Roketi',
    slot: GearSlot.shoes,
    price: 400,
    blurb: 'Düz yolda hafif ve çevik.',
    tint: GearTint.blue,
    terrainPct: {Terrain.asphalt: 20},
  ),
  GearDef(
    id: 'shoe_cobble',
    name: 'Kaldırım Ustası',
    slot: GearSlot.shoes,
    price: 450,
    blurb: 'Taş sokaklarda sağlam basış.',
    tint: GearTint.red,
    terrainPct: {Terrain.cobblestone: 25},
  ),
  GearDef(
    id: 'shoe_trail',
    name: 'Patika Pençesi',
    slot: GearSlot.shoes,
    price: 500,
    blurb: 'Toprakta ve çakılda sıkı tutunur.',
    tint: GearTint.green,
    terrainPct: {Terrain.trail: 25, Terrain.mountain: 10},
  ),
  GearDef(
    id: 'shoe_sand',
    name: 'Kum Tazısı',
    slot: GearSlot.shoes,
    price: 500,
    blurb: 'Geniş taban, kumda batmaz.',
    tint: GearTint.ochre,
    terrainPct: {Terrain.sand: 30},
  ),
  GearDef(
    id: 'shoe_rain',
    name: 'Su Geçirmez',
    slot: GearSlot.shoes,
    price: 650,
    blurb: 'Islak zeminde kuru ayaklar.',
    tint: GearTint.cyan,
    weatherPct: {Weather.rainy: 15},
    terrainPct: {Terrain.trail: 10},
  ),
  GearDef(
    id: 'shoe_mountain',
    name: 'Dağ Keçisi',
    slot: GearSlot.shoes,
    price: 900,
    blurb: 'Dik yokuşların ustası.',
    tint: GearTint.violet,
    terrainPct: {Terrain.mountain: 30, Terrain.trail: 10},
  ),
  GearDef(
    id: 'shoe_carbon',
    name: 'Karbon Plaka',
    slot: GearSlot.shoes,
    price: 2400,
    blurb: 'Her parkurda hız, asfaltta uçuş.',
    tint: GearTint.teal,
    basePct: 12,
    terrainPct: {Terrain.asphalt: 10},
  ),

  // Tracksuit sets
  GearDef(
    id: starterOutfitId,
    name: 'Okul Eşofmanı',
    slot: GearSlot.outfit,
    price: 0,
    blurb: 'Beden eğitimi dersinden kalma.',
    tint: GearTint.slate,
  ),
  GearDef(
    id: 'outfit_sun',
    name: 'Güneş Siperi',
    slot: GearSlot.outfit,
    price: 350,
    blurb: 'UV korumalı ince kumaş ve siperlik.',
    tint: GearTint.ochre,
    weatherPct: {Weather.sunny: 20},
  ),
  GearDef(
    id: 'outfit_wind',
    name: 'Poyraz Rüzgârlığı',
    slot: GearSlot.outfit,
    price: 400,
    blurb: 'Rüzgârı keser, seni yavaşlatmaz.',
    tint: GearTint.teal,
    weatherPct: {Weather.windy: 25},
  ),
  GearDef(
    id: 'outfit_rain',
    name: 'Yağmur Kalkanı',
    slot: GearSlot.outfit,
    price: 450,
    blurb: 'Islanmadan devam et.',
    tint: GearTint.blue,
    weatherPct: {Weather.rainy: 25},
  ),
  GearDef(
    id: 'outfit_heat',
    name: 'Serin Tutan',
    slot: GearSlot.outfit,
    price: 450,
    blurb: 'Nefes alan file kumaş.',
    tint: GearTint.red,
    weatherPct: {Weather.hot: 25, Weather.sunny: 10},
  ),
  GearDef(
    id: 'outfit_cold',
    name: 'Ayaz Termal',
    slot: GearSlot.outfit,
    price: 500,
    blurb: 'Eksi derecelerde sıcak tutar.',
    tint: GearTint.cyan,
    weatherPct: {Weather.cold: 25},
  ),
  GearDef(
    id: 'outfit_pro',
    name: 'Şampiyon Takımı',
    slot: GearSlot.outfit,
    price: 2200,
    blurb: 'Her havada fark yaratır.',
    tint: GearTint.violet,
    basePct: 10,
  ),
];

final Map<String, GearDef> gearById = {for (final g in gearDefs) g.id: g};

List<GearDef> gearFor(GearSlot slot) =>
    gearDefs.where((g) => g.slot == slot).toList();
