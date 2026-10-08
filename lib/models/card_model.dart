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
  // Market price in Japanese yen (Yuyutei). Null when no shop price was found —
  // never 0, so "unknown" and "worthless" stay distinguishable.
  final double? priceJpy;
  final String? archetype;
  // For S-rarity cards: the rarity of the sibling that shares the same artwork
  // (C or U). Precomputed in the DB so the image URL resolves in one request.
  // NULL for all non-S cards.
  final String? artworkRarity;
  // hololive members illustrated on or related to the card, comma-separated
  // (e.g. "Juufuutei Raden"). Lets cards whose name doesn't mention the
  // member — Cheer cards, Support items, multi-member art — show up in search.
  final String? members;
  // Promo cards only: which of several promo versions of the same card number
  // this is ("02", "03", …). Matches the image filename suffix. Null otherwise.
  final String? imageVariant;

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
    required this.priceJpy,
    this.archetype,
    this.artworkRarity,
    this.members,
    this.imageVariant,
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
        priceJpy: (map['price_jpy'] as num?)?.toDouble(),
        archetype: map['archetype'] as String?,
        artworkRarity: map['artwork_rarity'] as String?,
        members: map['members'] as String?,
        imageVariant: map['image_variant'] as String?,
        setType: map['set_type'] as String?,
        setNameEn: map['set_name_en'] as String?,
      );

  /// Price for totals and sorting: an unknown price counts as nothing.
  double get priceOrZero => priceJpy ?? 0;

  /// True if [query] (already lower-cased and normalised) appears in the JP
  /// name, EN name, card number or tagged members. Shared by every search bar.
  bool matchesSearch(String query) =>
      nameJp.toLowerCase().contains(query) ||
      (nameEn?.toLowerCase().contains(query) ?? false) ||
      cardNumber.toLowerCase().contains(query) ||
      (members?.toLowerCase().contains(query) ?? false);

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
        // Deck names read "Starter: Nakiri Ayame" / "Live: Shirakami Fubuki";
        // the image folder drops that prefix (folders can't contain ":"):
        // Deck/hSD02-NakiriAyame/hSD02-hSD02-001-OC.png
        final deckFolder = (setNameEn ?? '')
            .replaceFirst(RegExp(r'^(Starter|Live):\s*'), '')
            .replaceAll(' ', '');
        return '$base/Deck/$setCode-$deckFolder/$filename';
      case 'promo':
        // Promo images are named by card number + the card's rarity (almost
        // always P; Anniversary Celebration Set cards are SR), with a version
        // suffix when a card has several promo versions:
        // hBP01-104-P.png, hBP01-104-P-02.png, hBP03-030-SR-02.png
        final suffix = imageVariant == null ? '' : '-$imageVariant';
        return '$base/Promo/$cardNumber-$rarity$suffix.png';
      case 'booster':
      default:
        return '$base/Booster/$setCode-$folderName/$filename';
    }
  }
}
