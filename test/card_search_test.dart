import 'package:flutter_test/flutter_test.dart';
import 'package:holo_tcg_tracker/models/card_model.dart';

CardModel _card({String nameEn = 'Green Cheer', String? members}) => CardModel(
      cardId: '1',
      setCode: 'hBP06',
      nameJp: '緑エール',
      nameEn: nameEn,
      cardNumber: 'hY02-001',
      rarity: 'SY',
      isFoil: true,
      isSigned: false,
      isReprint: false,
      priceJpy: null,
      members: members,
    );

void main() {
  test('tagged member makes a Cheer card searchable', () {
    final cheer = _card(members: 'Juufuutei Raden');
    expect(cheer.matchesSearch('raden'), isTrue);
    expect(cheer.matchesSearch('green cheer'), isTrue);
  });

  test('any of several comma-separated members matches', () {
    final card = _card(nameEn: 'Normal PC', members: 'Sakura Miko, Hoshimachi Suisei');
    expect(card.matchesSearch('suisei'), isTrue);
    expect(card.matchesSearch('miko'), isTrue);
    expect(card.matchesSearch('pekora'), isFalse);
  });

  test('untagged card still matches on name and number only', () {
    final card = _card();
    expect(card.matchesSearch('raden'), isFalse);
    expect(card.matchesSearch('hy02-001'), isTrue);
  });
}
