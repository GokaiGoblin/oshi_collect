/// Formats a price for display.
///
/// Prices are stored in Japanese yen (the market they come from). [rates] holds
/// how much of each currency one yen buys (JPY itself is always 1.0). If the
/// rate for [currencyCode] hasn't been downloaded yet, the price is shown in
/// yen rather than converted with a made-up rate.
///
/// A null [jpyAmount] means no price is known for the card.
String formatPrice(
  double? jpyAmount,
  String currencyCode,
  Map<String, double> rates,
) {
  if (jpyAmount == null) return '—';

  final rate = rates[currencyCode];
  if (currencyCode == 'JPY' || rate == null) {
    return '¥${_commaSeparate(jpyAmount.round())}';
  }

  final converted = jpyAmount * rate;
  switch (currencyCode) {
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
      return '\$${converted.toStringAsFixed(2)}';
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
