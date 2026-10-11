import 'package:flutter_test/flutter_test.dart';
import 'package:holo_tcg_tracker/db/price_history.dart';
import 'package:holo_tcg_tracker/models/card_model.dart';
import 'package:holo_tcg_tracker/models/enums.dart';
import 'package:holo_tcg_tracker/utils/search_utils.dart';

/// A valid history: a full first update (card 1 = 680, cards 3+ = 100,
/// card 2 unpriced), then [later] lines appended as-is.
String _history({String later = '', int rows = 2500}) {
  final b = StringBuffer('date,card_id,price_jpy\n2026-10-08,1,680\n');
  for (var id = 3; id <= rows; id++) {
    b.writeln('2026-10-08,$id,100');
  }
  b.write(later);
  return b.toString();
}

CardModel _card(String id, String set, double? price) => CardModel(
      cardId: id,
      setCode: set,
      nameJp: 'x',
      nameEn: null,
      cardNumber: '$set-$id',
      rarity: 'C',
      isFoil: false,
      isSigned: false,
      isReprint: false,
      priceJpy: price,
    );

void main() {
  test('a valid history is read', () {
    final h = PriceHistory.parse(_history(later: '2026-10-11,1,980\n2026-10-11,3,\n'))!;
    expect(h.dates, [DateTime(2026, 10, 8), DateTime(2026, 10, 11)]);
    expect(h.priceOn(1, 0), 680);
    expect(h.priceOn(1, 1), 980);
    expect(h.priceOn(3, 1), isNull); // lost its price
    expect(h.priceOn(4, 1), 100); // unchanged carries forward
  });

  test('broken files are ignored', () {
    expect(PriceHistory.parse('nonsense'), isNull);
    expect(PriceHistory.parse(_history(rows: 100)), isNull); // first update too small
    expect(PriceHistory.parse(_history(later: '2026-10-11,1,0\n')), isNull); // 0 is never a price
    expect(PriceHistory.parse(_history(later: '2026-10-01,1,500\n')), isNull); // date went back
    expect(PriceHistory.parse(_history(later: '2026-10-11,1,5\n2026-10-11,1,6\n')), isNull); // dup
    expect(PriceHistory.parse(_history(later: '2026-10-11,1\n')), isNull);
  });

  test('trends compare the last two updates', () {
    final h = PriceHistory.parse(_history(later: '2026-10-11,1,980\n2026-10-11,4,50\n'))!;
    expect(h.trendFor('1'), Trend.up);
    expect(h.changeFor('1'), 300);
    expect(h.trendFor('4'), Trend.down);
    expect(h.trendFor('5'), Trend.flat);
    expect(h.trendFor('2'), isNull); // never priced
  });

  test('one update only: no trend yet', () {
    final h = PriceHistory.parse(_history())!;
    expect(h.hasTrend, isFalse);
    expect(h.trendFor('1'), isNull);
    expect(h.valueChange({'1': 1}), isNull);
  });

  test('value series counts copies and carries prices forward', () {
    final h = PriceHistory.parse(_history(
      later: '2026-10-11,1,980\n2026-10-18,3,\n',
    ))!;
    final s = h.valueSeries({'1': 1, '3': 2, '2': 5});
    expect([for (final p in s) p.value], [880, 1180, 980]);
    expect(h.valueChange({'1': 1, '3': 2}), -200);
  });

  test('value sort keeps cards in their sets, unpriced last', () {
    final cards = [
      _card('1', 'hBP01', 100),
      _card('2', 'hBP01', null),
      _card('3', 'hBP01', 900),
      _card('4', 'hBP02', 50),
      _card('5', 'hBP02', 5000),
    ];
    String ids(List<CardModel> l) => l.map((c) => c.cardId).join();
    expect(ids(sortByValueWithinSets(cards, ValueSort.cardNumber)), '12345');
    expect(ids(sortByValueWithinSets(cards, ValueSort.valueHighToLow)), '31254');
    expect(ids(sortByValueWithinSets(cards, ValueSort.valueLowToHigh)), '13245');
  });
}
