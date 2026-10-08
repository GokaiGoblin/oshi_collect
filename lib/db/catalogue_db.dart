import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/card_model.dart';
import '../models/set_model.dart';
import 'price_updates.dart';

class CatalogueDb {
  /// Live prices from R2 (see price_updates.dart). They're laid over the
  /// built-in price_jpy whenever a card is read, so a price update never
  /// needs a new APK or a change to the read-only database.
  final PriceUpdates prices;

  CatalogueDb(this.prices);

  static const String _dbName = 'holo_catalogue.db';
  static const String _versionFileName = 'holo_catalogue.version';

  // Bump this number each time assets/db/holo_catalogue.db is replaced with
  // updated card data — it forces the cached copy to be refreshed on next launch.
  static const int _dbVersion = 26;

  Database? _db;

  Future<Database> get db async => _db ??= await _open();

  Future<Database> _open() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbFile = File(join(docsDir.path, _dbName));
    final versionFile = File(join(docsDir.path, _versionFileName));

    final cachedVersion = await versionFile.exists()
        ? int.tryParse(await versionFile.readAsString()) ?? 0
        : 0;

    // Copy the bundled asset DB to documents on first launch, or whenever
    // the bundled version is newer than the cached copy
    if (!await dbFile.exists() || cachedVersion < _dbVersion) {
      final bytes = await rootBundle.load('assets/db/$_dbName');
      await dbFile.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      await versionFile.writeAsString('$_dbVersion');
    }

    // Saved prices must be in place before the first card is read.
    await prices.loadCached();
    return openDatabase(dbFile.path, readOnly: true);
  }

  /// Builds a card from a database row, swapping in the live price when the
  /// downloaded price file has one for this card.
  CardModel _card(Map<String, Object?> row) {
    final id = row['card_id'] as int;
    final live = prices.prices;
    if (!live.containsKey(id)) return CardModel.fromMap(row);
    return CardModel.fromMap({...row, 'price_jpy': live[id]});
  }

  Future<List<CardModel>> getCardsBySet(String setCode) async {
    final d = await db;
    final rows = await d.rawQuery(
      'SELECT cards.*, sets.set_type AS set_type, sets.name_en AS set_name_en '
      'FROM cards INNER JOIN sets ON cards.set_code = sets.set_code '
      'WHERE cards.set_code = ? AND sets.is_available = 1 '
      'ORDER BY cards.card_number ASC',
      [setCode],
    );
    return rows.map(_card).toList();
  }

  /// Like [getCardsBySet] but applies the canonical set-detail ordering:
  ///   1. Native cards (is_reprint = 0), sorted by card_number ASC then rarity rank
  ///   2. hSD reprints, sorted by card_number ASC then rarity rank
  ///   3. hBP reprints, sorted by card_number ASC then rarity rank
  Future<List<CardModel>> getCardsBySetOrdered(String setCode) async {
    final cards = await getCardsBySet(setCode);
    cards.sort((a, b) {
      final ga = _reprintGroup(a);
      final gb = _reprintGroup(b);
      if (ga != gb) return ga.compareTo(gb);
      final numCmp = a.cardNumber.compareTo(b.cardNumber);
      if (numCmp != 0) return numCmp;
      return _rarityRank(a.rarity).compareTo(_rarityRank(b.rarity));
    });
    return cards;
  }

  static int _reprintGroup(CardModel c) {
    if (!c.isReprint) return 0;
    if (c.cardNumber.startsWith('hSD')) return 1;
    return 2;
  }

  // C=1 U=2 S=3 R=4 RR=5 SR=6 UR=7 HR=8 OC/OSR=9 OUR=10 SEC=11 SY=12 P=13
  // (OC = Oshi Common, the non-foil oshi card in starter decks)
  static int _rarityRank(String rarity) {
    const ranks = {
      'C': 1, 'U': 2, 'S': 3,
      'R': 4, 'RR': 5, 'SR': 6, 'UR': 7, 'HR': 8,
      'OC': 9, 'OSR': 9, 'OUR': 10, 'SEC': 11, 'SY': 12, 'P': 13,
    };
    return ranks[rarity] ?? 99;
  }

  Future<List<CardModel>> getAllCards() async {
    final d = await db;
    // Join with sets to order by type group (booster→starter→promo) then the
    // set's sort_order so cards arrive in the order the grid displays them.
    // Also selects set_type and set name_en for imageUrl construction.
    final rows = await d.rawQuery('''
      SELECT cards.*, sets.set_type AS set_type, sets.name_en AS set_name_en
      FROM cards
      INNER JOIN sets ON cards.set_code = sets.set_code
      WHERE sets.is_available = 1
      ORDER BY
        CASE sets.set_type
          WHEN 'booster' THEN 0
          WHEN 'starter' THEN 1
          WHEN 'promo'   THEN 2
          ELSE 3
        END ASC,
        sets.sort_order ASC,
        CASE
          WHEN cards.is_reprint = 0 THEN 0
          WHEN cards.card_number LIKE 'hSD%' THEN 1
          ELSE 2
        END ASC,
        cards.card_number ASC,
        CASE cards.rarity
          WHEN 'C'   THEN 1  WHEN 'U'   THEN 2  WHEN 'S'   THEN 3
          WHEN 'R'   THEN 4  WHEN 'RR'  THEN 5  WHEN 'SR'  THEN 6
          WHEN 'UR'  THEN 7  WHEN 'HR'  THEN 8
          WHEN 'OC'  THEN 9  WHEN 'OSR' THEN 9  WHEN 'OUR' THEN 10 WHEN 'SEC' THEN 11
          WHEN 'SY'  THEN 12 WHEN 'P'   THEN 13 ELSE 99
        END ASC
    ''');
    return rows.map(_card).toList();
  }

  Future<CardModel?> getCard(String cardId) async {
    final d = await db;
    final rows = await d.rawQuery(
      'SELECT cards.*, sets.set_type AS set_type, sets.name_en AS set_name_en '
      'FROM cards LEFT JOIN sets ON cards.set_code = sets.set_code '
      'WHERE cards.card_id = ?',
      [cardId],
    );
    return rows.isEmpty ? null : _card(rows.first);
  }

  Future<Set<String>> getAllCardIds() async {
    final d = await db;
    final rows = await d.query('cards', columns: ['card_id']);
    return {for (final r in rows) r['card_id'].toString()};
  }

  /// Every set — boosters and promo events — in display order (sort_order:
  /// boosters by release date, then promo events by name, e.g. vol.2 before vol.10).
  Future<List<SetModel>> getSets() async {
    final d = await db;
    final rows = await d.query('sets', orderBy: 'sort_order ASC');
    return rows.map(SetModel.fromMap).toList();
  }

  /// Booster sets only, in release order — for Portfolio and Inventory,
  /// which list booster sets and keep promo events out.
  Future<List<SetModel>> getBoosterSets() async {
    final d = await db;
    final rows = await d.query(
      'sets',
      where: "set_type = 'booster'",
      orderBy: 'sort_order ASC',
    );
    return rows.map(SetModel.fromMap).toList();
  }
}
