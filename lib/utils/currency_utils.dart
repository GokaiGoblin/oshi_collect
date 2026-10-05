String formatPrice(
  double usdAmount,
  String currencyCode,
  Map<String, double> rates,
) {
  final rate = rates[currencyCode] ?? 1.0;
  final converted = usdAmount * rate;

  switch (currencyCode) {
    case 'JPY':
      final yen = converted.round();
      return '¥${_commaSeparate(yen)}';
    case 'GBP':
      return '£${converted.toStringAsFixed(2)}';
    case 'EUR':
      return '€${converted.toStringAsFixed(2)}';
    case 'AUD':
      return 'A\$${converted.toStringAsFixed(2)}';
    case 'CAD':
      return 'C\$${converted.toStringAsFixed(2)}';
    case 'USD':
    default:
      return '\$${(usdAmount * (rates['USD'] ?? 1.0)).toStringAsFixed(2)}';
  }
}

String _commaSeparate(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}
