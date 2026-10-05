import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../providers/preferences_provider.dart';
import '../theme/app_colours.dart';
import '../utils/currency_utils.dart';
import 'frosted_panel.dart';
import 'gradient_placeholder.dart';

// Which screen is hosting the card — controls the info panel layout and
// whether the progress bar is shown over the artwork.
enum SetCardMode { portfolio, inventory }

// Wide set card used in the Portfolio Sets and Inventory Sets list views.
// The artwork has rounded bottom corners and the info panel sits underneath
// it, overlapping by 10px so it "peeks behind" the artwork's curve.
class SetCard extends StatelessWidget {
  static const double _artworkHeight = 155.0;
  static const double _panelOverlap = 10.0;

  final SetCardMode mode;
  final String setCode;
  final String setName;
  final String artworkUrl;
  final int ownedCount;
  final int totalCount;

  // Portfolio mode
  final double? estimatedValue;

  // Inventory mode
  final int? duplicateCount;
  final double? totalValue;
  final String? highestValueCardNumber;
  final String? highestValueCardRarity;
  final double? highestValueCardValue;

  final bool isComingSoon;
  final VoidCallback? onTap;

  const SetCard({
    super.key,
    required this.mode,
    required this.setCode,
    required this.setName,
    required this.artworkUrl,
    required this.ownedCount,
    required this.totalCount,
    this.estimatedValue,
    this.duplicateCount,
    this.totalValue,
    this.highestValueCardNumber,
    this.highestValueCardRarity,
    this.highestValueCardValue,
    this.isComingSoon = false,
    this.onTap,
  });

  String _semanticLabel() {
    if (isComingSoon) return '$setCode, $setName, Coming soon';
    if (mode == SetCardMode.portfolio) {
      return '$setCode, $setName, $ownedCount of $totalCount cards owned';
    }
    return '$setCode, $setName, ${duplicateCount ?? 0} duplicates';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _semanticLabel(),
      button: !isComingSoon && onTap != null,
      onTap: isComingSoon ? null : onTap,
      excludeSemantics: true,
      child: GestureDetector(
      onTap: isComingSoon ? null : onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // The only non-positioned child — its size becomes the card's
            // size. Reserving (artworkHeight - overlap) of empty space above
            // the panel means the artwork can overlap it without leaving a
            // gap at the bottom of the card.
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: _artworkHeight - _panelOverlap),
                _InfoPanel(
                  mode: mode,
                  setCode: setCode,
                  setName: setName,
                  ownedCount: ownedCount,
                  totalCount: totalCount,
                  estimatedValue: estimatedValue,
                  duplicateCount: duplicateCount,
                  totalValue: totalValue,
                  highestValueCardNumber: highestValueCardNumber,
                  highestValueCardRarity: highestValueCardRarity,
                  highestValueCardValue: highestValueCardValue,
                ),
              ],
            ),

            // Painted after (so on top of) the panel — its rounded bottom
            // corners overlap and "peek over" the panel's top edge.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: _artworkHeight,
                child: _Artwork(
                  artworkUrl: artworkUrl,
                  showProgressBar: mode == SetCardMode.portfolio,
                  ownedCount: ownedCount,
                  totalCount: totalCount,
                ),
              ),
            ),

            if (isComingSoon) const _ComingSoonOverlay(),
          ],
        ),
      ),
      ),
    );
  }
}

// --- Artwork -----------------------------------------------------------

class _Artwork extends StatelessWidget {
  final String artworkUrl;
  final bool showProgressBar;
  final int ownedCount;
  final int totalCount;

  const _Artwork({
    required this.artworkUrl,
    required this.showProgressBar,
    required this.ownedCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(10),
        bottomRight: Radius.circular(10),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: artworkUrl,
            fit: BoxFit.cover,
            memCacheWidth: 800,
            placeholder: (ctx, url) => const GradientPlaceholder(),
            errorWidget: (ctx, url, err) => const GradientPlaceholder(),
          ),
          if (showProgressBar)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _ProgressBar(ownedCount: ownedCount, totalCount: totalCount),
            ),
        ],
      ),
    );
  }
}

// --- Progress bar (Portfolio only) --------------------------------------

class _ProgressBar extends StatelessWidget {
  final int ownedCount;
  final int totalCount;

  const _ProgressBar({required this.ownedCount, required this.totalCount});

  static const double _barHeight = 18.0;
  static const double _labelHeight = 15.0;

  @override
  Widget build(BuildContext context) {
    final fraction =
        totalCount == 0 ? 0.0 : (ownedCount / totalCount).clamp(0.0, 1.0);
    final pct = (fraction * 100).round();
    final labelPinnedLeft = fraction < 0.2;

    // LayoutBuilder gives the exact available width from the Positioned parent;
    // SizedBox uses it explicitly so the Stack always has tight constraints.
    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = constraints.maxWidth;
        final fillWidth = barWidth * fraction;

        return SizedBox(
          width: barWidth,
          height: _barHeight,
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              // Sky-blue fill — track is transparent so only fill is painted.
              // The artwork's ClipRRect clips the bar's corners to match the
              // artwork's rounded bottom edges.
              if (fraction > 0)
                Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: fillWidth,
                    height: _barHeight,
                    child: ColoredBox(
                      color: AppColours.lightSkyBlue.withValues(alpha: 0.85),
                    ),
                  ),
                ),

              // % label — hidden at 0%, pinned to the left edge below 20%
              // fill, otherwise tracks the fill's right edge; vertically
              // centred within the bar height
              if (fraction > 0)
                Positioned(
                  left: labelPinnedLeft ? 8 : fillWidth,
                  top: (_barHeight - _labelHeight) / 2,
                  child: labelPinnedLeft
                      ? _StrokedPercentLabel(pct: pct)
                      : FractionalTranslation(
                          translation: const Offset(-1, 0),
                          child: _StrokedPercentLabel(pct: pct),
                        ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// Dark purple fill with a 2px white stroke.
// #544D85 on the sky-blue fill (#B8D4EC) gives ~4.9:1 — passes WCAG AA.
// White stroke maintains readability when the label falls over dark artwork.
class _StrokedPercentLabel extends StatelessWidget {
  final int pct;
  const _StrokedPercentLabel({required this.pct});

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 14, fontWeight: FontWeight.w700, height: 1.0);
    return Semantics(
      label: '$pct percent of set owned',
      excludeSemantics: true,
      child: Stack(
        children: [
          Text(
            '$pct%',
            style: style.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2
                ..color = Colors.white.withValues(alpha: 0.85),
            ),
          ),
          Text('$pct%', style: style.copyWith(color: AppColours.lightNavBar)),
        ],
      ),
    );
  }
}

// --- Info panel ----------------------------------------------------------

class _InfoPanel extends StatelessWidget {
  final SetCardMode mode;
  final String setCode;
  final String setName;
  final int ownedCount;
  final int totalCount;
  final double? estimatedValue;
  final int? duplicateCount;
  final double? totalValue;
  final String? highestValueCardNumber;
  final String? highestValueCardRarity;
  final double? highestValueCardValue;

  const _InfoPanel({
    required this.mode,
    required this.setCode,
    required this.setName,
    required this.ownedCount,
    required this.totalCount,
    this.estimatedValue,
    this.duplicateCount,
    this.totalValue,
    this.highestValueCardNumber,
    this.highestValueCardRarity,
    this.highestValueCardValue,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelColour = isDark ? AppColours.darkCardPanel : AppColours.lightCardPanel;
    // Info text: navWhite over dark frosted panel in light theme; themed colours in dark.
    final infoText = isDark ? AppColours.darkPrimaryText : AppColours.lightNavWhite;
    final infoMuted = isDark ? AppColours.darkMutedText : AppColours.lightNavWhite;
    final infoSecondary = isDark ? AppColours.darkSecondaryText : AppColours.lightNavWhite;
    final dupePink = isDark ? AppColours.darkDupePink : AppColours.lightDupePink;
    final highestValueLabel =
        isDark ? AppColours.darkHighestValueLabel : AppColours.lightNavWhite;
    final prefs = context.watch<PreferencesProvider>();
    String fmt(double? v) => formatPrice(v ?? 0, prefs.currencyCode, prefs.fxRates);

    return FrostedPanel(
      backgroundColor: panelColour,
      borderRadius: BorderRadius.zero,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(setCode, style: TextStyle(fontSize: 11, color: infoMuted)),
                    Text(
                      setName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: infoText,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: mode == SetCardMode.portfolio
                    ? [
                        Text(
                          '$ownedCount/$totalCount',
                          style: TextStyle(fontSize: 12, color: infoSecondary),
                        ),
                        Text(
                          fmt(estimatedValue),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColours.gold,
                          ),
                        ),
                      ]
                    : [
                        Text(
                          '${duplicateCount ?? 0}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: dupePink,
                          ),
                        ),
                        Text(
                          fmt(totalValue),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColours.gold,
                          ),
                        ),
                      ],
              ),
            ],
          ),

          if (mode == SetCardMode.inventory && highestValueCardNumber != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Text('Highest Value', style: TextStyle(fontSize: 10, color: highestValueLabel)),
                const SizedBox(width: 6),
                Text(
                  '$highestValueCardNumber  ${highestValueCardRarity ?? ''}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: dupePink,
                  ),
                ),
                const Spacer(),
                Text(
                  fmt(highestValueCardValue),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColours.gold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// --- Coming Soon overlay --------------------------------------------------

class _ComingSoonOverlay extends StatelessWidget {
  const _ComingSoonOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: const Color(0x99000000),
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xCC000000),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'COMING SOON',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}
