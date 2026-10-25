import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../db/price_history.dart';
import '../providers/preferences_provider.dart';
import '../theme/app_colours.dart';
import '../utils/currency_utils.dart';
import 'frosted_panel.dart';
import 'gradient_placeholder.dart';
import 'set_card.dart';
import 'trend_triangle.dart';

// One starter deck in the Portfolio "Decks" view, shown two per row.
// The deck box image (transparent PNG from R2 decks/<code>_thumbnail.png)
// stands on a light frosted panel with the progress bar along its bottom;
// the info panel underneath shows the deck code, owned count, name and value.
// The Promos view uses the same tile for each promo category, passing its
// own [artwork] (the blended card cover) in place of the deck box.
class DeckTile extends StatelessWidget {
  // Width ÷ height of the artwork area. The box images are about 0.6 wide
  // for every 1 tall; a little extra width leaves a margin around the box.
  static const double _artworkAspectRatio = 0.68;
  static const double _lineHeight = 1.2;
  static const double _nameSize = 13;
  static const double _smallSize = 10;

  final String setCode;
  final String setName; // DB name, e.g. "Starter: Tokino Sora & AZKi"
  final String artworkUrl;
  final int ownedCount;
  final int totalCount;
  final double estimatedValue;
  final Trend? valueTrend;
  // Lines of name the panel makes room for: 1 when every deck name in the
  // row fits on one line, else 2 (see [nameLinesForRow]).
  final int nameLines;
  final VoidCallback? onTap;
  // Replaces the deck box image, filling the artwork area edge to edge.
  final Widget? artwork;
  final double artworkAspectRatio;
  // Bottom-left of the info panel; defaults to the deck type from the name.
  final String? typeLabel;

  const DeckTile({
    super.key,
    required this.setCode,
    required this.setName,
    required this.artworkUrl,
    required this.ownedCount,
    required this.totalCount,
    required this.estimatedValue,
    this.valueTrend,
    this.nameLines = 2,
    this.onTap,
    this.artwork,
    this.artworkAspectRatio = _artworkAspectRatio,
    this.typeLabel,
  });

  /// 1 if every deck name in a row fits on one line, otherwise 2 — tiles in
  /// a row must share the value so they stay the same height.
  /// Assumes the Decks grid layout: 12 px side padding, 10 px between tiles.
  static int nameLinesForRow(BuildContext context, List<String> setNames) {
    final tileWidth = (MediaQuery.sizeOf(context).width - 24 - 10) / 2;
    final textWidth = tileWidth - 16; // info panel's 8 px side padding
    final style = DefaultTextStyle.of(context).style.merge(
          const TextStyle(fontSize: _nameSize, fontWeight: FontWeight.w600, height: _lineHeight),
        );
    for (final name in setNames) {
      final painter = TextPainter(
        text: TextSpan(text: splitName(name).$2, style: style),
        textDirection: TextDirection.ltr,
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout(maxWidth: textWidth);
      final fits = !painter.didExceedMaxLines;
      painter.dispose();
      if (!fits) return 2;
    }
    return 1;
  }

  /// "Starter: Tokino Sora & AZKi" → ("Start Deck", "Tokino Sora & AZKi");
  /// "Live: Sakura Miko" → ("Live Start Deck", "Sakura Miko").
  static (String, String) splitName(String name) {
    final i = name.indexOf(': ');
    if (i < 0) return ('Start Deck', name);
    final prefix = name.substring(0, i);
    final rest = name.substring(i + 2);
    return (prefix == 'Live' ? 'Live Start Deck' : 'Start Deck', rest);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelColour = isDark ? AppColours.darkCardPanel : AppColours.lightCardPanel;
    final infoText = isDark ? AppColours.darkPrimaryText : AppColours.lightNavWhite;
    final infoMuted = isDark ? AppColours.darkMutedText : AppColours.lightNavWhite;
    final infoSecondary = isDark ? AppColours.darkSecondaryText : AppColours.lightNavWhite;
    final prefs = context.watch<PreferencesProvider>();
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final (nameType, deckName) = splitName(setName);
    final deckType = typeLabel ?? nameType;

    return Semantics(
      label: '$setCode, $deckName, $ownedCount of $totalCount cards owned',
      button: onTap != null,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Deck box on a light frosted panel; the progress bar lies
              // over the bottom of the box, as on the booster set cards ---
              AspectRatio(
                aspectRatio: artworkAspectRatio,
                child: FrostedPanel(
                  borderRadius: BorderRadius.zero,
                  padding: EdgeInsets.zero,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (artwork != null)
                        artwork!
                      else
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
                          child: CachedNetworkImage(
                            imageUrl: artworkUrl,
                            fit: BoxFit.contain,
                            memCacheHeight: 700,
                            placeholder: (_, _) => const SizedBox.shrink(),
                            errorWidget: (_, _, _) => const _MissingBox(),
                          ),
                        ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: SetProgressBar(ownedCount: ownedCount, totalCount: totalCount),
                      ),
                    ],
                  ),
                ),
              ),

              // --- Info panel ---
              FrostedPanel(
                backgroundColor: panelColour,
                borderRadius: BorderRadius.zero,
                padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //   hSD20 ................ 12/20
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            setCode,
                            style: TextStyle(fontSize: _smallSize, height: _lineHeight, color: infoMuted),
                          ),
                        ),
                        Text(
                          '$ownedCount/$totalCount',
                          style: TextStyle(fontSize: _smallSize, height: _lineHeight, color: infoSecondary),
                        ),
                      ],
                    ),
                    // Deck name — the same number of lines on both tiles of a
                    // row so they stay the same height.
                    SizedBox(
                      height: _nameSize * _lineHeight * nameLines * textScale,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          deckName,
                          maxLines: nameLines,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: _nameSize,
                            height: _lineHeight,
                            fontWeight: FontWeight.w600,
                            color: infoText,
                          ),
                        ),
                      ),
                    ),
                    //   Live Start Deck ....... ▲ ¥1,234
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            deckType,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: _smallSize, height: _lineHeight, color: infoMuted),
                          ),
                        ),
                        if (valueTrend != null) ...[
                          TrendTriangle(trend: valueTrend!, size: 7),
                          const SizedBox(width: 3),
                        ],
                        Text(
                          formatPrice(estimatedValue, prefs.currencyCode, prefs.fxRates),
                          style: const TextStyle(
                            fontSize: 11,
                            height: _lineHeight,
                            fontWeight: FontWeight.w600,
                            color: AppColours.gold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Shown when a deck has no box image on R2 yet.
class _MissingBox extends StatelessWidget {
  const _MissingBox();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: 0.6,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: const GradientPlaceholder(),
        ),
      ),
    );
  }
}
