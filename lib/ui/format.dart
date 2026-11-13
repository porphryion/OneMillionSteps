/// Turkish number, date and text formatting (design-system/MASTER.md §9).
library;

/// "123.456"
String groupThousands(int n) {
  final s = n.abs().toString();
  final b = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return b.toString();
}

/// "42,2" for 42195 m. Rounds down so a race never shows done too early.
String formatKmValue(double meters, {int decimals = 1}) {
  final scale = [1, 10, 100][decimals.clamp(0, 2)];
  final units = (meters / 1000 * scale).floor();
  final whole = groupThousands(units ~/ scale);
  if (decimals == 0) return whole;
  final frac = (units % scale).toString().padLeft(decimals, '0');
  return '$whole,$frac';
}

/// "42,2 km"
String formatKm(double meters, {int decimals = 1}) =>
    '${formatKmValue(meters, decimals: decimals)} km';

/// "%25"
String percent(num value) => '%${value.round()}';

/// "+%25"
String bonusPercent(int pct) => '+%$pct';

/// Uppercase that keeps Turkish dotted/dotless i right ("iç" -> "İÇ").
String trUpper(String s) => s.replaceAll('i', 'İ').toUpperCase();

const _months = [
  'Ocak',
  'Şubat',
  'Mart',
  'Nisan',
  'Mayıs',
  'Haziran',
  'Temmuz',
  'Ağustos',
  'Eylül',
  'Ekim',
  'Kasım',
  'Aralık',
];

/// "13 Kasım"
String dayMonth(DateTime t) => '${t.day} ${_months[t.month - 1]}';

/// "9–15 Kasım" or "30 Ekim – 5 Kasım" for [start] to [lastDay] inclusive.
String dateRange(DateTime start, DateTime lastDay) {
  if (start.month == lastDay.month && start.year == lastDay.year) {
    return '${start.day}–${dayMonth(lastDay)}';
  }
  return '${dayMonth(start)} – ${dayMonth(lastDay)}';
}

/// "3 gün kaldı", "Son gün", "Süre doldu"
String timeLeftLabel(int daysLeft) => switch (daysLeft) {
  <= 0 => 'Süre doldu',
  1 => 'Son gün',
  _ => '$daysLeft gün kaldı',
};
