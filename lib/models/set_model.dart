class SetModel {
  final String code;
  final String name;        // name_en
  final String? nameJp;
  final String setType;     // e.g. 'booster'
  final String releaseDate; // ISO date string, e.g. '2024-09-20'
  final int cardCount;      // official set size from DB
  final bool isAvailable;   // false → shown as "coming soon"

  const SetModel({
    required this.code,
    required this.name,
    this.nameJp,
    required this.setType,
    required this.releaseDate,
    required this.cardCount,
    required this.isAvailable,
  });

  factory SetModel.fromMap(Map<String, dynamic> map) => SetModel(
        code: map['set_code'] as String,
        name: map['name_en'] as String,
        nameJp: map['name_jp'] as String?,
        setType: map['set_type'] as String,
        releaseDate: map['release_date'] as String,
        cardCount: map['card_count'] as int,
        isAvailable: (map['is_available'] as int) == 1,
      );
}
