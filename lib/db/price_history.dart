import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// Which way a price (or a total value) moved since the previous weekly update.
enum Trend { up, down, flat }

/// Week-by-week card prices, downloaded from R2. Powers the portfolio value
/// chart and the up/down triangles next to prices.
///
/// The file (made by tool/export_prices.py, one block per weekly update) only
/// lists prices that CHANGED:
///
///     date,card_id,price_jpy
///     2026-10-08,1,680          <- the first date lists every priced card
///     2026-10-11,4,19800        <- later dates list just the changes
///     2026-10-11,1051,          <- blank = the card lost its price
///
/// Like [PriceUpdates], it's downloaded once per launch, a saved copy is used
/// when the phone is offline, and a file that fails any check is ignored.
class PriceHistory extends ChangeNotifier {
  static const _url = 'https://standbyinteractive.com/data/price_history.csv';
  static const _cacheFileName = 'price_history_cache.csv';

  // The first update must list (nearly) every card, as in prices.csv.
  static const _minFirstRows = 2000;

  PriceHistoryData _data;
  Future<void>? _cacheLoad;

  /// [initial] is only for tests; the app starts empty and loads the file.
  PriceHistory({PriceHistoryData? initial}) : _data = initial ?? PriceHistoryData.empty;

  PriceHistoryData get data => _data;

  /// Loads the saved copy (once).
  Future<void> loadCached() => _cacheLoad ??= _loadCached();

  Future<void> _loadCached() async {
    try {
      final file = await _cacheFile();
      if (!await file.exists()) return;
      final parsed = parse(await file.readAsString());
      if (parsed != null) _apply(parsed);
    } catch (e) {
      debugPrint('PriceHistory: could not read saved history: $e');
    }
  }

  /// Downloads the latest history from R2. Quietly does nothing if the phone
  /// is offline or the file fails the checks in [parse].
  Future<bool> refresh() async {
    await loadCached();
    try {
      // Same hourly cache-buster as prices.csv (see PriceUpdates.refresh).
      final hour = DateTime.now().millisecondsSinceEpoch ~/ 3600000;
      final response = await http
          .get(Uri.parse('$_url?v=$hour'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return false;

      final text = response.body;
      final parsed = parse(text);
      if (parsed == null) return false;
      if (parsed.dates.length == _data.dates.length &&
          parsed.rowCount == _data.rowCount) {
        return false; // same file we already have
      }
      await (await _cacheFile()).writeAsString(text, flush: true);
      _apply(parsed);
      return true;
    } catch (e) {
      debugPrint('PriceHistory: refresh failed: $e');
      return false;
    }
  }

  void _apply(PriceHistoryData parsed) {
    _data = parsed;
    notifyListeners();
  }

  Future<File> _cacheFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(join(dir.path, _cacheFileName));
  }

  /// Checks and reads a history file. Returns null (file ignored) if anything
  /// looks wrong — all-or-nothing, like [PriceUpdates.parse].
  @visibleForTesting
  static PriceHistoryData? parse(String text) {
    final lines = text
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.length < 2 || lines.first != 'date,card_id,price_jpy') return null;

    final dates = <DateTime>[];
    final changes = <int, List<PriceChangeEntry>>{};
    final seenOnDate = <int>{};
    String? lastDateText;
    var firstDateRows = 0;

    for (final line in lines.skip(1)) {
      final parts = line.split(',');
      if (parts.length != 3) return null;

      if (parts[0] != lastDateText) {
        // Dates must only ever move forward.
        if (lastDateText != null && parts[0].compareTo(lastDateText) <= 0) return null;
        if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(parts[0])) return null;
        final date = DateTime.tryParse(parts[0]);
        if (date == null) return null;
        dates.add(date);
        lastDateText = parts[0];
        seenOnDate.clear();
      }

      final id = int.tryParse(parts[1]);
      if (id == null || !seenOnDate.add(id)) return null;

      double? price;
      if (parts[2].isNotEmpty) {
        price = double.tryParse(parts[2]);
        if (price == null || price <= 0) return null; // never 0 — blank means "no price"
      }
      changes.putIfAbsent(id, () => []).add(PriceChangeEntry(dates.length - 1, price));
      if (dates.length == 1) firstDateRows++;
    }

    if (firstDateRows < _minFirstRows) return null;
    return PriceHistoryData(dates, changes, lines.length - 1);
  }
}

/// One recorded price: from update number [dateIndex] onwards, the card cost
/// [price] (null = no price).
class PriceChangeEntry {
  final int dateIndex;
  final double? price;
  const PriceChangeEntry(this.dateIndex, this.price);
}

/// A total value on one update date.
class ValuePoint {
  final DateTime date;
  final double value;
  const ValuePoint(this.date, this.value);
}

/// A parsed price history, plus the sums the screens need.
class PriceHistoryData {
  /// Every weekly update date, oldest first.
  final List<DateTime> dates;

  /// card_id -> its recorded prices, oldest first.
  final Map<int, List<PriceChangeEntry>> _changes;

  /// Number of data rows in the file (used to spot an unchanged download).
  final int rowCount;

  PriceHistoryData(this.dates, this._changes, this.rowCount);

  static final empty = PriceHistoryData(const [], const {}, 0);

  /// True once there are two updates to compare — before that there's
  /// nothing to draw a chart or a triangle from.
  bool get hasTrend => dates.length >= 2;

  DateTime? get latestDate => dates.isEmpty ? null : dates.last;
  DateTime? get previousDate => dates.length < 2 ? null : dates[dates.length - 2];

  /// The card's price as of update number [dateIndex] (null = no price).
  double? priceOn(int cardId, int dateIndex) {
    final list = _changes[cardId];
    if (list == null) return null;
    double? price;
    for (final c in list) {
      if (c.dateIndex > dateIndex) break;
      price = c.price;
    }
    return price;
  }

  /// How the card's price moved between the last two updates, or null when
  /// that can't be said (no history yet, or no price at one of the two dates).
  Trend? trendFor(String cardId) {
    final change = changeFor(cardId);
    if (change == null) return null;
    return trendOf(change);
  }

  /// Price at the latest update minus price at the one before, or null when
  /// either price is unknown.
  double? changeFor(String cardId) {
    if (!hasTrend) return null;
    final id = int.tryParse(cardId);
    if (id == null) return null;
    final now = priceOn(id, dates.length - 1);
    final before = priceOn(id, dates.length - 2);
    if (now == null || before == null) return null;
    return now - before;
  }

  /// Total value of [holdings] (card_id -> number of copies) on every update
  /// date, oldest first. Unpriced cards count as nothing, like elsewhere.
  List<ValuePoint> valueSeries(Map<String, int> holdings) {
    final totals = List<double>.filled(dates.length, 0);
    holdings.forEach((cardId, qty) {
      if (qty <= 0) return;
      final list = _changes[int.tryParse(cardId)];
      if (list == null) return;
      var next = 0;
      double? price;
      for (var d = 0; d < dates.length; d++) {
        while (next < list.length && list[next].dateIndex <= d) {
          price = list[next++].price;
        }
        if (price != null) totals[d] += price * qty;
      }
    });
    return [for (var d = 0; d < dates.length; d++) ValuePoint(dates[d], totals[d])];
  }

  /// Change in total value of [holdings] between the last two updates, or null
  /// before there are two updates.
  double? valueChange(Map<String, int> holdings) {
    if (!hasTrend) return null;
    final series = valueSeries(holdings);
    return series.last.value - series[series.length - 2].value;
  }
}

/// Up, down or flat for a price difference. Differences under ¥1 are treated
/// as no change (rounding in the other currencies could otherwise show one).
Trend trendOf(double change) {
  if (change >= 1) return Trend.up;
  if (change <= -1) return Trend.down;
  return Trend.flat;
}
