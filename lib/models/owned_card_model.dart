class OwnedCardModel {
  final String cardId;
  final bool claimed;
  final int duplicates;

  const OwnedCardModel({
    required this.cardId,
    this.claimed = false,
    this.duplicates = 0,
  });

  factory OwnedCardModel.fromMap(Map<String, dynamic> map) => OwnedCardModel(
        cardId: map['card_id'] as String,
        claimed: (map['claimed'] as int) == 1,
        duplicates: map['duplicates'] as int,
      );

  Map<String, dynamic> toMap() => {
        'card_id': cardId,
        'claimed': claimed ? 1 : 0,
        'duplicates': duplicates,
      };
}
