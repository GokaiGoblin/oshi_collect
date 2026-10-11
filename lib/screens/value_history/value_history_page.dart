import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../db/price_history.dart';
import '../../models/card_model.dart';
import '../../models/set_model.dart';
import '../../providers/collection_provider.dart';
import '../../providers/preferences_provider.dart';
import '../../theme/app_colours.dart';
import '../../utils/currency_utils.dart';
import '../../utils/holdings.dart';
import '../../widgets/app_background.dart';
import '../../widgets/card_artwork_image.dart';
import '../../widgets/frosted_panel.dart';
import '../../widgets/gradient_placeholder.dart';
import '../../widgets/trend_triangle.dart';
import '../../widgets/value_chart.dart';
import '../../widgets/value_summary_panel.dart';
import '../card_profile/card_profile_page.dart';

/// Full value history, opened from the summary panel's "View history" button
/// on Portfolio (one of each card owned) or Inventory (duplicates). Back
/// returns to whichever tab opened it.
///
/// Shows: the value chart with a time-range toggle, the cards that moved most
/// at the last price update, and value by set.
class ValueHistoryPage extends StatefulWidget {
  final HoldingsKind kind;

  /// Every card in the catalogue (holdings are worked out from these).
  final List<CardModel> allCards;

  /// All sets, for the by-set names.
  final List<SetModel> sets;

  const ValueHistoryPage({
    super.key,
    required this.kind,
    required this.allCards,
    required this.sets,
  });

  @override
  State<ValueHistoryPage> createState() => _ValueHistoryPageState();
}

enum _Range { w4, m3, m6, y1, all }

class _ValueHistoryPageState extends State<ValueHistoryPage> {
  _Range _range = _Range.m3;

  static const _rangeLabels = {
    _Range.w4: '4W',
    _Range.m3: '3M',
    _Range.m6: '6M',
    _Range.y1: '1Y',
    _Range.all: 'All',
  };

  static const _rangeDays = {_Range.w4: 28, _Range.m3: 91, _Range.m6: 182, _Range.y1: 365};

  static const _rangeNames = {
    _Range.w4: 'past 4 weeks',
    _Range.m3: 'past 3 months',
    _Range.m6: 'past 6 months',
    _Range.y1: 'past year',
  };

  /// The points of [series] inside the chosen range (always at least two
  /// when the series has two, so there's a line to draw).
  List<ValuePoint> _inRange(List<ValuePoint> series) {
    final days = _rangeDays[_range];
    if (days == null || series.length < 2) return series;
    final cutoff = series.last.date.subtract(Duration(days: days));
    final start = series.indexWhere((p) => !p.date.isBefore(cutoff));
    final from = (start < 0 ? series.length - 1 : start).clamp(0, series.length - 2);
    return series.sublist(from);
  }

  @override
  Widget build(BuildContext context) {
    final collection = context.watch<CollectionProvider>();
    final history = context.watch<PriceHistory>().data;
    final holdings = holdingsFor(widget.kind, widget.allCards, collection);
    final isPortfolio = widget.kind == HoldingsKind.portfolio;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            _NavBar(tabName: isPortfolio ? 'Portfolio' : 'Inventory'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
                children: [
                  _chartPanel(context, history, holdings),
                  const SizedBox(height: 10),
                  _MoversPanel(cards: widget.allCards, holdings: holdings),
                  const SizedBox(height: 10),
                  _BySetPanel(cards: widget.allCards, holdings: holdings, sets: widget.sets),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chartPanel(BuildContext context, PriceHistoryData history, Map<String, int> holdings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? AppColours.darkPrimaryText : AppColours.lightNavWhite;
    final muted = text.withValues(alpha: 0.75);
    final prefs = context.watch<PreferencesProvider>();
    String fmt(double v) => formatPrice(v, prefs.currencyCode, prefs.fxRates);

    final isPortfolio = widget.kind == HoldingsKind.portfolio;
    final cardCount = holdings.values.fold<int>(0, (a, b) => a + b);
    final current = holdingsValue(holdings, widget.allCards);
    final points = _inRange(history.valueSeries(holdings));
    final values = [for (final p in points) p.value];

    final change = points.length >= 2 ? points.last.value - points.first.value : null;
    final rangeName = _rangeNames[_range] ??
        (points.isEmpty ? '' : 'since ${formatShortDate(points.first.date)}');

    return FrostedPanel(
      backgroundColor: isDark ? AppColours.darkCardPanel : AppColours.lightCardPanel,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${isPortfolio ? 'Portfolio value' : 'Duplicates value'} · $cardCount ${cardCount == 1 ? 'card' : 'cards'}',
            style: TextStyle(fontSize: 11, color: text),
          ),
          const SizedBox(height: 2),
          Text(
            fmt(current),
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: AppColours.gold,
              letterSpacing: -0.3,
            ),
          ),
          if (change != null) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                TrendTriangle(trend: trendOf(change), size: 10),
                const SizedBox(width: 5),
                Text(
                  '${formatPriceChange(change, prefs.currencyCode, prefs.fxRates)} '
                  '(${formatPercentChange(change, points.first.value)})',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: TrendTriangle.colourFor(context, trendOf(change)),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(child: Text(rangeName, style: TextStyle(fontSize: 12, color: muted))),
              ],
            ),
          ],
          const SizedBox(height: 12),
          if (points.length < 2)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text(
                'The chart appears after the next weekly price update.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: muted),
              ),
            )
          else ...[
            // Chart with the highest / lowest values in a strip to its right.
            SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Semantics(
                      label: 'Value chart, $rangeName',
                      child: ValueChart(values: values, height: 150, showGuides: true),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(fmt(values.reduce((a, b) => a > b ? a : b)),
                          style: TextStyle(fontSize: 9, color: muted)),
                      Text(fmt(values.reduce((a, b) => a < b ? a : b)),
                          style: TextStyle(fontSize: 9, color: muted)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(formatShortDate(points.first.date), style: TextStyle(fontSize: 9, color: muted)),
                Text(formatShortDate(points.last.date), style: TextStyle(fontSize: 9, color: muted)),
              ],
            ),
          ],
          const SizedBox(height: 12),
          _RangeToggle(
            selected: _range,
            labels: _rangeLabels,
            onChanged: (r) => setState(() => _range = r),
          ),
        ],
      ),
    );
  }
}

// --- Nav bar ----------------------------------------------------------------

class _NavBar extends StatelessWidget {
  final String tabName;
  const _NavBar({required this.tabName});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navColour = isDark ? AppColours.darkNavBar : AppColours.lightNavBar;
    final navText = isDark ? AppColours.darkSelectedNav : AppColours.lightSelectedNav;

    return Container(
      color: navColour,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Row(
            children: [
              Semantics(
                label: 'Back',
                button: true,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(child: Icon(Icons.arrow_back, size: 18, color: navText)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Value History',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: navText),
                ),
              ),
              Text(
                tabName,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: navText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Range toggle -------------------------------------------------------------

class _RangeToggle extends StatelessWidget {
  final _Range selected;
  final Map<_Range, String> labels;
  final ValueChanged<_Range> onChanged;

  const _RangeToggle({required this.selected, required this.labels, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeBg = isDark ? AppColours.darkGoldButton : AppColours.lightSkyBlue;
    final activeText = isDark ? AppColours.gold : AppColours.lightButtonText;
    final inactiveText = isDark ? AppColours.darkPrimaryText : AppColours.lightNavWhite;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0x33000000),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          for (final entry in labels.entries)
            Expanded(
              child: Semantics(
                selected: entry.key == selected,
                button: true,
                child: Material(
                  color: entry.key == selected ? activeBg : Colors.transparent,
                  shape: StadiumBorder(
                    side: isDark && entry.key == selected
                        ? const BorderSide(color: AppColours.darkButtonBorder)
                        : BorderSide.none,
                  ),
                  child: InkWell(
                    customBorder: const StadiumBorder(),
                    onTap: () => onChanged(entry.key),
                    child: SizedBox(
                      height: 32,
                      child: Center(
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: entry.key == selected ? activeText : inactiveText,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// --- Biggest movers -------------------------------------------------------------

class _MoversPanel extends StatelessWidget {
  final List<CardModel> cards;
  final Map<String, int> holdings;

  static const _maxMovers = 5;

  const _MoversPanel({required this.cards, required this.holdings});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? AppColours.darkPrimaryText : AppColours.lightNavWhite;
    final prefs = context.watch<PreferencesProvider>();
    final history = context.watch<PriceHistory>().data;

    // Biggest change in value held (price change × copies), up or down.
    final movers = <(CardModel, double)>[];
    for (final card in cards) {
      final qty = holdings[card.cardId];
      if (qty == null) continue;
      final change = history.changeFor(card.cardId);
      if (change == null || trendOf(change) == Trend.flat) continue;
      movers.add((card, change));
    }
    movers.sort((a, b) =>
        (b.$2 * holdings[b.$1.cardId]!).abs().compareTo((a.$2 * holdings[a.$1.cardId]!).abs()));
    final top = movers.take(_maxMovers).toList();
    final topCards = [for (final m in top) m.$1];

    return FrostedPanel(
      backgroundColor: isDark ? AppColours.darkCardPanel : AppColours.lightCardPanel,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            history.previousDate == null
                ? 'Biggest movers'
                : 'Biggest movers · since ${formatShortDate(history.previousDate!)}',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: text),
          ),
          const SizedBox(height: 8),
          if (top.isEmpty)
            Text(
              history.hasTrend
                  ? 'None of your cards changed price at the last update.'
                  : 'Shown after the next weekly price update.',
              style: TextStyle(fontSize: 11, color: text.withValues(alpha: 0.8)),
            ),
          for (var i = 0; i < top.length; i++)
            InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => CardProfilePage(cards: topCards, initialIndex: i)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: SizedBox(
                        width: 34,
                        height: 47,
                        child: CardArtworkImage(
                          card: top[i].$1,
                          memCacheWidth: 102,
                          placeholder: (_) => const GradientPlaceholder(),
                          errorWidget: (_) => const GradientPlaceholder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            top[i].$1.nameJp,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: text),
                          ),
                          Text(
                            '${top[i].$1.cardNumber}  ${top[i].$1.rarity}'
                            '${holdings[top[i].$1.cardId]! > 1 ? '  ×${holdings[top[i].$1.cardId]}' : ''}',
                            style: TextStyle(fontSize: 9, color: text.withValues(alpha: 0.8)),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatPrice(top[i].$1.priceJpy, prefs.currencyCode, prefs.fxRates),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColours.gold),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TrendTriangle(trend: trendOf(top[i].$2), size: 7),
                            const SizedBox(width: 4),
                            Text(
                              formatPriceChange(top[i].$2, prefs.currencyCode, prefs.fxRates),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: TrendTriangle.colourFor(context, trendOf(top[i].$2)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// --- Value by set ---------------------------------------------------------------

class _BySetPanel extends StatelessWidget {
  final List<CardModel> cards;
  final Map<String, int> holdings;
  final List<SetModel> sets;

  const _BySetPanel({required this.cards, required this.holdings, required this.sets});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? AppColours.darkPrimaryText : AppColours.lightNavWhite;
    final prefs = context.watch<PreferencesProvider>();
    final history = context.watch<PriceHistory>().data;
    final names = {for (final s in sets) s.code: s.name};

    // Booster sets each get a row; all starter decks share one, as do all
    // promos (there are dozens of promo events).
    final groups = <String, ({String code, String name, Map<String, int> holdings, double value})>{};
    for (final card in cards) {
      final qty = holdings[card.cardId];
      if (qty == null) continue;
      final (key, code, name) = switch (card.setType) {
        'starter' || 'starter_deck' => ('~decks', 'hSD', 'Starter Decks'),
        'promo' => ('~promos', 'PR', 'Promos'),
        _ => (card.setCode, card.setCode, names[card.setCode] ?? card.setCode),
      };
      final g = groups[key] ?? (code: code, name: name, holdings: <String, int>{}, value: 0.0);
      g.holdings[card.cardId] = qty;
      groups[key] = (code: g.code, name: g.name, holdings: g.holdings, value: g.value + qty * card.priceOrZero);
    }
    final rows = groups.values.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = rows.isEmpty ? 0.0 : rows.first.value;

    return FrostedPanel(
      backgroundColor: isDark ? AppColours.darkCardPanel : AppColours.lightCardPanel,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('By set', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: text)),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            Text('No cards yet.', style: TextStyle(fontSize: 11, color: text.withValues(alpha: 0.8))),
          for (final row in rows) ...[
            Row(
              children: [
                SizedBox(
                  width: 44,
                  child: Text(row.code, style: TextStyle(fontSize: 10, color: text.withValues(alpha: 0.8))),
                ),
                Expanded(
                  child: Text(
                    row.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: text),
                  ),
                ),
                if (history.valueChange(row.holdings) case final change?) ...[
                  TrendTriangle(trend: trendOf(change), size: 7),
                  const SizedBox(width: 5),
                ],
                Text(
                  formatPrice(row.value, prefs.currencyCode, prefs.fxRates),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColours.gold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: top <= 0 ? 0 : row.value / top,
                minHeight: 4,
                backgroundColor: const Color(0x1FFFFFFF),
                valueColor: AlwaysStoppedAnimation(AppColours.lightSkyBlue.withValues(alpha: 0.85)),
              ),
            ),
            const SizedBox(height: 9),
          ],
        ],
      ),
    );
  }
}
