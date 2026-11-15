import 'package:flutter_test/flutter_test.dart';
import 'package:holo_tcg_tracker/models/card_model.dart';
import 'package:holo_tcg_tracker/utils/currency_utils.dart';

CardModel _promo({String? variant, String setCode = 'PR-super-pr-pack-vol-5', String rarity = 'P'}) => CardModel(
      cardId: '2390',
      setCode: setCode,
      nameJp: 'ふつうのパソコン',
      nameEn: 'Normal PC',
      cardNumber: 'hBP01-104',
      rarity: rarity,
      isFoil: false,
      isSigned: false,
      isReprint: true,
      priceJpy: null,
      imageVariant: variant,
      setType: 'promo',
    );

void main() {
  test('yen prices are shown with commas and no decimals', () {
    expect(formatPrice(39800, 'JPY', {'JPY': 1.0}), '¥39,800');
  });

  test('other currencies convert from yen', () {
    expect(formatPrice(1000, 'USD', {'JPY': 1.0, 'USD': 0.00633}), '\$6.33');
  });

  test('without a downloaded rate the price stays in yen', () {
    expect(formatPrice(1000, 'GBP', {'JPY': 1.0}), '¥1,000');
  });

  test('an unknown price shows a dash, never zero', () {
    expect(formatPrice(null, 'JPY', {'JPY': 1.0}), '—');
  });

  test('promo image URL uses the card number and version suffix', () {
    expect(_promo().imageUrl, 'https://standbyinteractive.com/cards/Promo/hBP01-104-P.png');
    expect(_promo(variant: '02').imageUrl,
        'https://standbyinteractive.com/cards/Promo/hBP01-104-P-02.png');
  });

  test('a promo set with an official code loads from its own folder, code first', () {
    expect(_promo(setCode: 'hPC01', rarity: 'SR', variant: '08').imageUrl,
        'https://standbyinteractive.com/cards/Promo/hPC01/hPC01-hBP01-104-SR-08.png');
    expect(_promo(setCode: 'hWF01').imageUrl,
        'https://standbyinteractive.com/cards/Promo/hWF01/hWF01-hBP01-104-P.png');
  });
}
