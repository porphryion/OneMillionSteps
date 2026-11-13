/// "123,456"
String groupThousands(int n) {
  final s = n.abs().toString();
  final b = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

/// Compact coin amounts: 950, 12.4K, 3.21M, 1.05B ...
String compact(double v) {
  if (v < 10000) return groupThousands(v.floor());
  const units = ['K', 'M', 'B', 'T', 'Qa', 'Qi'];
  var x = v;
  var u = -1;
  while (x >= 1000 && u < units.length - 1) {
    x /= 1000;
    u++;
  }
  final digits = x >= 100 ? 1 : 2;
  return '${x.toStringAsFixed(digits)}${units[u]}';
}
