import '../models/card_model.dart';
import '../models/enums.dart';

/// Normalizes a search query to tolerate missing leading zeros in card numbers.
///
/// Card numbers follow the format {prefix}{2digits}-{3digits}, e.g. hBP06-010.
/// This pads any `digits-digits` substring in the query so that:
///   - the segment before the hyphen is at least 2 digits
///   - the segment after the hyphen is at least 3 digits
///
/// Segments that already meet or exceed the expected length are left alone,
/// so "06-010" → "06-010" (no change) and "6-10" → "06-010".
String normalizeCardNumberQuery(String query) {
  return query.replaceAllMapped(
    RegExp(r'(\d+)-(\d+)'),
    (match) {
      var pre = match.group(1)!;
      var post = match.group(2)!;
      if (pre.length < 2) pre = pre.padLeft(2, '0');
      if (post.length < 3) post = post.padLeft(3, '0');
      return '$pre-$post';
    },
  );
}

/// Re-orders [cards] by price within each set, keeping the sets in the order
/// they arrived. Cards with no price go last either way. [ValueSort.cardNumber]
/// leaves the list as it is (it already arrives in card-number order).
List<CardModel> sortByValueWithinSets(List<CardModel> cards, ValueSort sort) {
  if (sort == ValueSort.cardNumber) return cards;
  final setOrder = <String, int>{};
  for (final c in cards) {
    setOrder.putIfAbsent(c.setCode, () => setOrder.length);
  }
  final position = {for (var i = 0; i < cards.length; i++) cards[i]: i};
  final sorted = List.of(cards);
  sorted.sort((a, b) {
    final bySet = setOrder[a.setCode]!.compareTo(setOrder[b.setCode]!);
    if (bySet != 0) return bySet;
    final pa = a.priceJpy, pb = b.priceJpy;
    if (pa == null || pb == null) {
      if (pa == null && pb == null) return position[a]!.compareTo(position[b]!);
      return pa == null ? 1 : -1;
    }
    final byPrice = sort == ValueSort.valueHighToLow ? pb.compareTo(pa) : pa.compareTo(pb);
    // Equal prices keep card-number order.
    return byPrice != 0 ? byPrice : position[a]!.compareTo(position[b]!);
  });
  return sorted;
}
