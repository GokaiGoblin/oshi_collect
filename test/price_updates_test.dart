import 'package:flutter_test/flutter_test.dart';
import 'package:holo_tcg_tracker/db/price_updates.dart';
import 'package:holo_tcg_tracker/models/card_model.dart';

/// A valid file: header lines plus [rows] cards, card 1 priced 680, card 2 blank.
String _file({int rows = 2500, String date = '2026-10-08', String header = 'card_id,price_jpy'}) {
  final b = StringBuffer('updated,$date\n$header\n1,680\n2,\n');
  for (var id = 3; id <= rows; id++) {
    b.writeln('$id,100');
  }
  return b.toString();
}

CardModel _deckCard(String deckName) => CardModel(
      cardId: '2731',
      setCode: 'hSD02',
      nameJp: '百鬼あやめ',
      nameEn: 'Nakiri Ayame',
      cardNumber: 'hSD02-001',
      rarity: 'OC',
      isFoil: false,
      isSigned: false,
      isReprint: false,
      priceJpy: null,
      setType: 'starter',
      setNameEn: deckName,
    );

void main() {
  test('a valid price file is read, blank meaning "no price"', () {
    final f = PriceUpdates.parse(_file())!;
    expect(f.updatedOn, DateTime(2026, 10, 8));
    expect(f.prices[1], 680);
    expect(f.prices.containsKey(2), isTrue);
    expect(f.prices[2], isNull);
    expect(f.prices.length, 2500);
  });

  test('Windows line endings are fine', () {
    expect(PriceUpdates.parse(_file().replaceAll('\n', '\r\n')), isNotNull);
  });

  test('a file with too few cards is ignored (half-uploaded)', () {
    expect(PriceUpdates.parse(_file(rows: 50)), isNull);
  });

  test('a wrong header or missing date is ignored', () {
    expect(PriceUpdates.parse(_file(header: 'id,price')), isNull);
    expect(PriceUpdates.parse(_file().replaceFirst('updated,2026-10-08', 'hello')), isNull);
  });

  test('a zero, negative or non-number price rejects the whole file', () {
    expect(PriceUpdates.parse(_file().replaceFirst('1,680', '1,0')), isNull);
    expect(PriceUpdates.parse(_file().replaceFirst('1,680', '1,-5')), isNull);
    expect(PriceUpdates.parse(_file().replaceFirst('1,680', '1,abc')), isNull);
  });

  test('a duplicated card id rejects the whole file', () {
    expect(PriceUpdates.parse(_file().replaceFirst('2,\n', '1,\n')), isNull);
  });

  test('deck image folder drops the Starter:/Live: prefix', () {
    expect(_deckCard('Starter: Nakiri Ayame').imageUrl,
        'https://standbyinteractive.com/cards/Deck/hSD02-NakiriAyame/hSD02-hSD02-001-OC.png');
    expect(_deckCard('Live: Shirakami Fubuki').imageUrl,
        'https://standbyinteractive.com/cards/Deck/hSD02-ShirakamiFubuki/hSD02-hSD02-001-OC.png');
    expect(_deckCard('Starter: Tokino Sora & AZKi').imageUrl,
        'https://standbyinteractive.com/cards/Deck/hSD02-TokinoSora&AZKi/hSD02-hSD02-001-OC.png');
  });
}
