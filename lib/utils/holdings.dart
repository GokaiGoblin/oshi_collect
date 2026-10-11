import '../models/card_model.dart';
import '../providers/collection_provider.dart';

/// Which copies a value total counts.
enum HoldingsKind {
  /// Portfolio: one of each card owned (the collection, not the spares).
  portfolio,

  /// Inventory: every duplicate copy.
  duplicates,
}

/// card_id -> number of copies counted, for every card in [cards] that counts.
Map<String, int> holdingsFor(
  HoldingsKind kind,
  Iterable<CardModel> cards,
  CollectionProvider collection,
) {
  final holdings = <String, int>{};
  for (final card in cards) {
    final qty = kind == HoldingsKind.portfolio
        ? (collection.isOwned(card.cardId) ? 1 : 0)
        : collection.duplicateCount(card.cardId);
    if (qty > 0) holdings[card.cardId] = qty;
  }
  return holdings;
}

/// Today's total value of [holdings], using each card's current price.
double holdingsValue(Map<String, int> holdings, Iterable<CardModel> cards) {
  var total = 0.0;
  for (final card in cards) {
    final qty = holdings[card.cardId];
    if (qty != null) total += qty * card.priceOrZero;
  }
  return total;
}
