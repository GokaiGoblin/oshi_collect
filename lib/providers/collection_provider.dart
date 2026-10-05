import 'package:flutter/material.dart';
import '../db/user_db.dart';
import '../models/owned_card_model.dart';

class CollectionProvider extends ChangeNotifier {
  final UserDb _db;

  CollectionProvider(this._db);

  Map<String, OwnedCardModel> _records = {};

  Map<String, OwnedCardModel> get records => Map.unmodifiable(_records);

  bool isClaimed(String cardId) => _records[cardId]?.claimed ?? false;

  // isOwned = isClaimed — used by filter sheets and Portfolio unowned overlay.
  bool isOwned(String cardId) => isClaimed(cardId);

  int duplicateCount(String cardId) => _records[cardId]?.duplicates ?? 0;

  Future<void> resetAll() async {
    await _db.resetAll();
    _records = {};
    notifyListeners();
  }

  Future<void> loadAll() async {
    final records = await _db.getAllOwned();
    _records = {for (final r in records) r.cardId: r};
    notifyListeners();
  }

  Future<void> claim(String cardId) async {
    await _db.setClaimed(cardId, true);
    _records[cardId] = OwnedCardModel(
      cardId: cardId,
      claimed: true,
      duplicates: _records[cardId]?.duplicates ?? 0,
    );
    notifyListeners();
  }

  Future<void> unclaim(String cardId) async {
    await _db.setClaimed(cardId, false);
    final dupes = _records[cardId]?.duplicates ?? 0;
    if (dupes > 0) {
      _records[cardId] = OwnedCardModel(
        cardId: cardId,
        claimed: false,
        duplicates: dupes,
      );
    } else {
      _records.remove(cardId);
    }
    notifyListeners();
  }

  Future<void> incrementDuplicates(String cardId) async {
    if (!isClaimed(cardId)) return;
    final next = duplicateCount(cardId) + 1;
    await _db.setDuplicates(cardId, next);
    _records[cardId] = OwnedCardModel(
      cardId: cardId,
      claimed: true,
      duplicates: next,
    );
    notifyListeners();
  }

  /// Applies a batch of import rows to the DB, then reloads from DB so the
  /// in-memory state and UI reflect the full merged result immediately.
  Future<void> batchImport(List<OwnedCardModel> rows) async {
    for (final row in rows) {
      await _db.upsertRecord(row.cardId, row.claimed, row.duplicates);
    }
    await loadAll();
  }

  Future<void> decrementDuplicates(String cardId) async {
    final current = duplicateCount(cardId);
    if (current <= 0) return;
    final next = current - 1;
    await _db.setDuplicates(cardId, next);
    _records[cardId] = OwnedCardModel(
      cardId: cardId,
      claimed: _records[cardId]?.claimed ?? false,
      duplicates: next,
    );
    notifyListeners();
  }
}
