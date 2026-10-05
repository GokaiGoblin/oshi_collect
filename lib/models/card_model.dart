class CardModel {
  final String cardId;
  final String setCode;
  final String nameJp;
  final String? nameEn;
  final String cardNumber;
  final String rarity;
  final bool isFoil;
  final bool isSigned;
  final bool isReprint;
  final double priceUsd;
  final String? archetype;
  // For S-rarity cards: the rarity of the sibling that shares the same artwork
  // (C or U). Precomputed in the DB so the image URL resolves in one request.
  // NULL for all non-S cards.
  final String? artworkRarity;

  // Populated from the sets table JOIN. Used to construct the correct R2 path.
  final String? setType;    // 'booster' | 'starter' | 'starter_deck' | 'promo'
  final String? setNameEn;  // e.g. 'Blooming Radiance' — spaces stripped for folder name

  const CardModel({
    required this.cardId,
    required this.setCode,
    required this.nameJp,
    required this.nameEn,
    required this.cardNumber,
    required this.rarity,
    required this.isFoil,
    required this.isSigned,
    required this.isReprint,
    required this.priceUsd,
    this.archetype,
    this.artworkRarity,
    this.setType,
    this.setNameEn,
  });

  factory CardModel.fromMap(Map<String, dynamic> map) => CardModel(
        cardId: map['card_id'].toString(),
        setCode: map['set_code'] as String,
        nameJp: map['name_jp'] as String,
        nameEn: map['name_en'] as String?,
        cardNumber: map['card_number'] as String,
        rarity: map['rarity'] as String,
        isFoil: (map['is_foil'] as int) == 1,
        isSigned: (map['is_signed'] as int) == 1,
        isReprint: (map['is_reprint'] as int) == 1,
        priceUsd: (map['price_usd'] as num).toDouble(),
        archetype: map['archetype'] as String?,
        artworkRarity: map['artwork_rarity'] as String?,
        setType: map['set_type'] as String?,
        setNameEn: map['set_name_en'] as String?,
      );

  // Constructs the R2 image URL based on set_type and set name folder.
  // Uses artworkRarity for S cards so the URL resolves to the correct sibling
  // image (C or U) in a single request — no fallback chain needed.
  String get imageUrl {
    final effectiveRarity = artworkRarity ?? rarity;
    final filename = '$setCode-$cardNumber-$effectiveRarity.png';
    final folderName = (setNameEn ?? '').replaceAll(' ', '');
    const base = 'https://standbyinteractive.com/cards';

    switch (setType) {
      case 'starter':
      case 'starter_deck':
        return '$base/Deck/$setCode-$folderName/$filename';
      case 'promo':
        return '$base/Promo/$filename';
      case 'booster':
      default:
        return '$base/Booster/$setCode-$folderName/$filename';
    }
  }
}
