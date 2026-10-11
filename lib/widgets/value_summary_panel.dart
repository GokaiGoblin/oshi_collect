import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../db/price_history.dart';
import '../db/price_updates.dart';
import '../providers/preferences_provider.dart';
import '../theme/app_colours.dart';
import '../utils/currency_utils.dart';
import 'frosted_panel.dart';
import 'trend_triangle.dart';
import 'value_chart.dart';

/// The frosted panel at the top of Portfolio Sets / Inventory Sets: total
/// value, how it moved at the last weekly price update, a mini chart of the
/// last 12 updates and a "View history" button.
class ValueSummaryPanel extends StatelessWidget {
  /// "Portfolio value" / "Duplicates value".
  final String label;

  /// Today's total, from the same prices the set cards show.
  final double currentValue;

  /// card_id -> copies counted, for the history chart.
  final Map<String, int> holdings;

  final VoidCallback onViewHistory;

  static const _chartPoints = 12;

  const ValueSummaryPanel({
    super.key,
    required this.label,
    required this.currentValue,
    required this.holdings,
    required this.onViewHistory,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelColour = isDark ? AppColours.darkCardPanel : AppColours.lightCardPanel;
    final text = isDark ? AppColours.darkPrimaryText : AppColours.lightNavWhite;
    final prefs = context.watch<PreferencesProvider>();
    final history = context.watch<PriceHistory>().data;
    final pricesOn = context.watch<PriceUpdates>().updatedOn ?? history.latestDate;

    final series = history.valueSeries(holdings);
    final change = history.valueChange(holdings);
    final recent = series.length > _chartPoints ? series.sublist(series.length - _chartPoints) : series;

    return FrostedPanel(
      backgroundColor: panelColour,
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(fontSize: 11, color: text)),
                    const SizedBox(height: 2),
                    Text(
                      formatPrice(currentValue, prefs.currencyCode, prefs.fxRates),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColours.gold,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (change != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: _ChangeSummary(
                    change: change,
                    previousValue: series[series.length - 2].value,
                    since: history.previousDate!,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (history.hasTrend)
            Semantics(
              label: 'Chart of value over the last ${recent.length} price updates',
              child: ValueChart(values: [for (final p in recent) p.value], height: 56),
            )
          else
            Text(
              'Your value history builds up with each weekly price update.',
              style: TextStyle(fontSize: 11, color: text.withValues(alpha: 0.8)),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  [
                    if (pricesOn != null) 'Prices as of ${formatShortDate(pricesOn)}',
                    if (history.hasTrend) '${recent.length} updates',
                  ].join(' · '),
                  style: TextStyle(fontSize: 10, color: text.withValues(alpha: 0.8)),
                ),
              ),
              if (history.hasTrend) ViewHistoryButton(onTap: onViewHistory),
            ],
          ),
        ],
      ),
    );
  }
}

/// "▲ +¥12,480" over "+2.7% since 4 Oct", in the trend's soft colour.
class _ChangeSummary extends StatelessWidget {
  final double change;
  final double previousValue;
  final DateTime since;

  const _ChangeSummary({required this.change, required this.previousValue, required this.since});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? AppColours.darkPrimaryText : AppColours.lightNavWhite;
    final prefs = context.watch<PreferencesProvider>();
    final trend = trendOf(change);
    final colour = TrendTriangle.colourFor(context, trend);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TrendTriangle(trend: trend, size: 10),
            const SizedBox(width: 5),
            Text(
              formatPriceChange(change, prefs.currencyCode, prefs.fxRates),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colour),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '${formatPercentChange(change, previousValue)} since ${formatShortDate(since)}',
          style: TextStyle(fontSize: 10, color: text.withValues(alpha: 0.8)),
        ),
      ],
    );
  }
}

/// "+2.7%" / "−1.9%" / "0.0%". A rise from nothing has no percentage.
String formatPercentChange(double change, double before) {
  if (before <= 0) return change > 0 ? 'New' : '0.0%';
  final pct = change / before * 100;
  if (pct.abs() < 0.05) return '0.0%';
  return '${pct > 0 ? '+' : '−'}${pct.abs().toStringAsFixed(1)}%';
}

/// The pill button that opens the Value History page — sky blue in light
/// theme, dark gold in dark theme (the app's standard button colours).
class ViewHistoryButton extends StatelessWidget {
  final VoidCallback onTap;
  const ViewHistoryButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColours.darkGoldButton : AppColours.lightSkyBlue;
    final fg = isDark ? AppColours.gold : AppColours.lightButtonText;

    return Material(
      color: bg,
      shape: StadiumBorder(
        side: isDark ? const BorderSide(color: AppColours.darkButtonBorder) : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: ConstrainedBox(
          // 44px tall touch target; the pill itself looks slimmer.
          constraints: const BoxConstraints(minHeight: 36, minWidth: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Center(
              widthFactor: 1,
              child: Text(
                'View history',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
