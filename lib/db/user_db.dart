import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/owned_card_model.dart';

class UserDb {
  static const String _dbName = 'holo_user.db';
  Database? _db;

  Future<Database> get db async => _db ??= await _open();

  Future<Database> _open() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = join(docsDir.path, _dbName);
    return openDatabase(
      dbPath,
      version: 2,
      onCreate: (d, _) => d.execute('''
        CREATE TABLE owned_cards (
          card_id    TEXT PRIMARY KEY,
          claimed    INTEGER NOT NULL DEFAULT 0,
          duplicates INTEGER NOT NULL DEFAULT 0
        )
      '''),
      onUpgrade: (d, oldVersion, newVersion) async {
        if (oldVersion == 1) {
          // v1 had a single `quantity` column. Migrate to claimed + duplicates:
          //   claimed    = 1 if quantity > 0, else 0
          //   duplicates = max(0, quantity - 1)
          await d.execute('''
            CREATE TABLE owned_cards_v2 (
              card_id    TEXT PRIMARY KEY,
              claimed    INTEGER NOT NULL DEFAULT 0,
              duplicates INTEGER NOT NULL DEFAULT 0
            )
          ''');
          await d.execute('''
            INSERT INTO owned_cards_v2 (card_id, claimed, duplicates)
            SELECT
              card_id,
              CASE WHEN quantity > 0 THEN 1 ELSE 0 END,
              MAX(0, quantity - 1)
            FROM owned_cards
          ''');
          await d.execute('DROP TABLE owned_cards');
          await d.execute('ALTER TABLE owned_cards_v2 RENAME TO owned_cards');
        }
      },
    );
  }

  Future<List<OwnedCardModel>> getAllOwned() async {
    final d = await db;
    final rows = await d.query(
      'owned_cards',
      where: 'claimed = 1 OR duplicates > 0',
    );
    return rows.map(OwnedCardModel.fromMap).toList();
  }

  Future<void> setClaimed(String cardId, bool claimed) async {
    final d = await db;
    // Ensure a row exists, then update.
    await d.insert(
      'owned_cards',
      {'card_id': cardId, 'claimed': claimed ? 1 : 0, 'duplicates': 0},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    await d.update(
      'owned_cards',
      {'claimed': claimed ? 1 : 0},
      where: 'card_id = ?',
      whereArgs: [cardId],
    );
    // Remove empty rows (unclaimed with no duplicates).
    if (!claimed) {
      await d.delete(
        'owned_cards',
        where: 'card_id = ? AND claimed = 0 AND duplicates <= 0',
        whereArgs: [cardId],
      );
    }
  }

  Future<void> resetAll() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
    final docsDir = await getApplicationDocumentsDirectory();
    final dbFile = File(join(docsDir.path, _dbName));
    if (await dbFile.exists()) await dbFile.delete();
  }

  /// Upserts a single record during import. Replaces any existing row.
  /// Deletes the row if both claimed=false and duplicates≤0 (empty state).
  Future<void> upsertRecord(String cardId, bool claimed, int duplicates) async {
    final d = await db;
    if (!claimed && duplicates <= 0) {
      await d.delete('owned_cards', where: 'card_id = ?', whereArgs: [cardId]);
      return;
    }
    await d.insert(
      'owned_cards',
      {'card_id': cardId, 'claimed': claimed ? 1 : 0, 'duplicates': duplicates},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> setDuplicates(String cardId, int count) async {
    final d = await db;
    await d.insert(
      'owned_cards',
      {'card_id': cardId, 'claimed': 0, 'duplicates': count},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    await d.update(
      'owned_cards',
      {'duplicates': count},
      where: 'card_id = ?',
      whereArgs: [cardId],
    );
    // Remove empty rows.
    if (count <= 0) {
      await d.delete(
        'owned_cards',
        where: 'card_id = ? AND claimed = 0 AND duplicates <= 0',
        whereArgs: [cardId],
      );
    }
  }
}
