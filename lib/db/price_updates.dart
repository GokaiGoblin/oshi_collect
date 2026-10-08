import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// Live card prices, downloaded from R2 so prices can change without a new APK.
///
/// The file (made by tool/export_prices.py) looks like:
///
///     updated,2026-10-08
///     card_id,price_jpy
///     1,680
///     1051,            <- blank = no price found
///
/// Where a card's price comes from, best first:
///   1. the file just downloaded from R2,
///   2. the copy saved on the phone from the last successful download,
///   3. the price built into the APK's catalogue database.
/// A card missing from the file keeps its built-in price.
class PriceUpdates extends ChangeNotifier {
  static const _url = 'https://standbyinteractive.com/data/prices.csv';
  static const _cacheFileName = 'prices_cache.csv';

  // A real price file has a row for (nearly) every card; anything much smaller
  // is a broken or half-uploaded file and is ignored.
  static const _minRows = 2000;

  Map<int, double?> _prices = const {};
  DateTime? _updatedOn;
  Future<void>? _cacheLoad;

  /// The date printed in the price file in use, or null when the app is still
  /// using the prices built into the APK.
  DateTime? get updatedOn => _updatedOn;

  /// card_id -> price in yen (null = no price). Only cards in the file appear.
  Map<int, double?> get prices => _prices;

  /// Loads the saved copy (once). The catalogue awaits this before reading any
  /// cards, so the first screen already shows the latest saved prices.
  Future<void> loadCached() => _cacheLoad ??= _loadCached();

  Future<void> _loadCached() async {
    try {
      final file = await _cacheFile();
      if (!await file.exists()) return;
      final parsed = parse(await file.readAsString());
      if (parsed != null) _apply(parsed);
    } catch (e) {
      debugPrint('PriceUpdates: could not read saved prices: $e');
    }
  }

  /// Downloads the latest file from R2. Quietly does nothing if the phone is
  /// offline, R2 can't be reached, or the file fails the checks in [parse].
  /// Returns true when new prices were applied.
  Future<bool> refresh() async {
    await loadCached();
    try {
      // The hour number in the URL makes Cloudflare fetch a fresh copy at most
      // an hour after an upload, instead of serving a long-cached one.
      final hour = DateTime.now().millisecondsSinceEpoch ~/ 3600000;
      final response = await http
          .get(Uri.parse('$_url?v=$hour'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return false;

      final text = response.body;
      final parsed = parse(text);
      if (parsed == null) return false;
      if (_updatedOn != null && !parsed.updatedOn.isAfter(_updatedOn!) &&
          mapEquals(parsed.prices, _prices)) {
        return false; // same file we already have
      }
      await (await _cacheFile()).writeAsString(text, flush: true);
      _apply(parsed);
      return true;
    } catch (e) {
      debugPrint('PriceUpdates: refresh failed: $e');
      return false;
    }
  }

  void _apply(PriceFile parsed) {
    _prices = parsed.prices;
    _updatedOn = parsed.updatedOn;
    notifyListeners();
  }

  Future<File> _cacheFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(join(dir.path, _cacheFileName));
  }

  /// Checks and reads a price file. Returns null (file ignored) if anything
  /// looks wrong — it's all-or-nothing, so a damaged file never half-applies.
  @visibleForTesting
  static PriceFile? parse(String text) {
    final lines = text
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.length < 2) return null;

    final dateMatch = RegExp(r'^updated,(\d{4}-\d{2}-\d{2})$').firstMatch(lines[0]);
    if (dateMatch == null || lines[1] != 'card_id,price_jpy') return null;
    final updatedOn = DateTime.tryParse(dateMatch.group(1)!);
    if (updatedOn == null) return null;

    final prices = <int, double?>{};
    for (final line in lines.skip(2)) {
      final parts = line.split(',');
      if (parts.length != 2) return null;
      final id = int.tryParse(parts[0]);
      if (id == null || prices.containsKey(id)) return null;
      if (parts[1].isEmpty) {
        prices[id] = null;
        continue;
      }
      final price = double.tryParse(parts[1]);
      if (price == null || price <= 0) return null; // never 0 — blank means "no price"
      prices[id] = price;
    }
    if (prices.length < _minRows) return null;
    return PriceFile(updatedOn, prices);
  }
}

/// A price file that passed every check in [PriceUpdates.parse].
class PriceFile {
  final DateTime updatedOn;
  final Map<int, double?> prices;
  PriceFile(this.updatedOn, this.prices);
}
