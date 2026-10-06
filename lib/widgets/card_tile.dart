import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/card_model.dart';
import '../models/enums.dart';
import '../providers/preferences_provider.dart';
import '../theme/app_colours.dart';
import '../utils/currency_utils.dart';
import 'card_artwork_image.dart';
import 'dupe_dot.dart';
import 'frosted_panel.dart';
import 'gradient_placeholder.dart';

class CardTile extends StatelessWidget {
  // Standard trading-card ratio (~63×88mm). Artwork is fixed to this ratio
  // so every tile in a row has the same artwork height regardless of content.
  static const double _artworkAspectRatio = 5 / 7;

  // How much the artwork overlaps the top of the info panel — hides the panel's
  // top corners behind the artwork's rounded bottom edge.
  static const double _artworkOverlap = 8.0;

  // Fixed info-panel height that fits 2 lines of card name (font × 1.4 leading)
  // plus the card-number row and vertical padding. Using a fixed height instead
  // of IntrinsicHeight eliminates the expensive two-pass layout measurement.
  // Includes _artworkOverlap so the top portion hidden under the artwork is
  // accounted for; the total tile height is invariant (overlap added here,
  // subtracted from the Stack height in build).
  // textScale should be MediaQuery.textScalerOf(context).scale(1.0) so the
  // panel grows proportionally when the user increases font size.
  static double infoHeight(bool isThree, bool hasValue, {double textScale = 1.0}) {
    const lh = 1.4;
    const pad = 6.0 + _artworkOverlap; // 3 px top + 3 px bottom + overlap
    // 4px margin instead of 2 so sub-pixel rounding at non-1.0 text scales
    // doesn't cause a micro-overflow in the inner Column.
    const margin = 4.0;
    final namePx = (isThree ? 10.0 : 12.0) * textScale;
    final numPx = (isThree ? 8.0 : 10.0) * textScale;
    final base = namePx * lh * 2.0 + numPx * lh + pad + margin;
    // Value row uses 8 px text + 2 px gap above it.
    return hasValue ? base + 8.0 * textScale * lh + 2.0 : base;
  }

  final CardModel card;
  final GridSize gridSize;
  final bool showDupeDot;   // small 8×8 owned indicator (Catalogue / Portfolio)
  final int? dupeQuantity;  // count badge on artwork (Inventory only)
  final double? totalValue; // "Total Value" row — duplicates × price (Inventory only)
  final bool isUnowned;     // greyed overlay with UNOWNED pill (Portfolio)
  final VoidCallback? onTap;

  const CardTile({
    super.key,
    required this.card,
    required this.gridSize,
    this.showDupeDot = false,
    this.dupeQuantity,
    this.totalValue,
    this.isUnowned = false,
    this.onTap,
  });

  String _semanticLabel() {
    final name = card.nameEn ?? card.nameJp;
    final rarityStr = card.isFoil ? '${card.rarity}, Foil' : card.rarity;
    final parts = <String>[name, card.cardNumber, rarityStr];
    if (isUnowned) {
      parts.add('Unowned');
    } else if (dupeQuantity != null && dupeQuantity! > 0) {
      parts.add('$dupeQuantity ${dupeQuantity == 1 ? "duplicate" : "duplicates"}');
    }
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final isThree = gridSize == GridSize.three;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDark ? AppColours.darkCardPanel : AppColours.lightCardPanel;
    // Light theme: navWhite on the dark frosted panel. Dark theme: warm cream default.
    final panelText = isDark ? AppColours.darkPrimaryText : AppColours.lightNavWhite;
    final totalValueLabel =
        isDark ? AppColours.darkHighestValueLabel : AppColours.lightNavWhite;
    final prefs = context.watch<PreferencesProvider>();

    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final panelHeight = infoHeight(isThree, totalValue != null, textScale: textScale);

    return Semantics(
      label: _semanticLabel(),
      button: onTap != null,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        // Outer clip — rounds the tile's four corner pixels.
        borderRadius: BorderRadius.circular(8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final artworkHeight = constraints.maxWidth / _artworkAspectRatio;
            // Stack height subtracts the overlap so total tile height is
            // identical to the old Column approach (artworkHeight + panelHeight
            // from infoHeight already includes the overlap px in its padding).
            return SizedBox(
              height: artworkHeight + panelHeight - _artworkOverlap,
              child: Stack(
                children: [
                  // --- Info panel — sits at the bottom; its top portion is
                  // hidden behind the artwork's rounded bottom edge ---
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: SizedBox(
                      height: panelHeight,
                      child: FrostedPanel(
                        backgroundColor: panelColor,
                        borderRadius: BorderRadius.zero,
                        // Top padding = 3 visible + 8 overlap = 11, so content
                        // clears the artwork edge.
                        padding: const EdgeInsets.fromLTRB(4, 11, 4, 3),
                        child: Stack(
                          clipBehavior: Clip.hardEdge,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      card.cardNumber,
                                      style: TextStyle(fontSize: isThree ? 8.0 : 10.0, color: panelText),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      card.rarity,
                                      style: TextStyle(fontSize: isThree ? 8.0 : 10.0, color: panelText),
                                    ),
                                  ],
                                ),
                                if (totalValue != null) ...[
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(
                                        'Total Value',
                                        style: TextStyle(
                                          fontSize: 8.0,
                                          fontWeight: FontWeight.w500,
                                          color: totalValueLabel,  // navWhite light / muted dark
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        // Unpriced cards show a dash rather than ¥0
                                        formatPrice(card.priceJpy == null ? null : totalValue,
                                            prefs.currencyCode, prefs.fxRates),
                                        style: const TextStyle(
                                          fontSize: 9.0,
                                          fontWeight: FontWeight.w500,
                                          color: AppColours.gold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                Text(
                                  card.nameJp,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: isThree ? 10.0 : 12.0,
                                    fontWeight: FontWeight.w500,
                                    color: panelText,
                                  ),
                                ),
                              ],
                            ),
                            if (showDupeDot) const DupeDot(),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // --- Artwork — positioned from the top, overlaps the panel
                  // by _artworkOverlap px, hiding the panel's top corners ---
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: ClipRRect(
                      // Inner clip — gives the artwork its own rounded corners
                      // on all four sides, including the bottom edge that
                      // overlaps the panel.
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        height: artworkHeight,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CardArtworkImage(
                              card: card,
                              memCacheWidth: isThree ? 300 : 450,
                              memCacheHeight: isThree ? 420 : 630,
                              placeholder: (_) => const GradientPlaceholder(),
                              errorWidget: (_) => const GradientPlaceholder(),
                            ),
                            if (isUnowned) const _UnownedOverlay(),
                            if (dupeQuantity != null && dupeQuantity! > 0)
                              _DupeQuantityBadge(count: dupeQuantity!),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      ),
    );
  }
}

class _UnownedOverlay extends StatelessWidget {
  const _UnownedOverlay();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: const Color(0x99000000)),
        Align(
          alignment: const Alignment(0, 0.5), // 75% down
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0x99000000),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'UNOWNED',
              style: TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DupeQuantityBadge extends StatelessWidget {
  final int count;
  const _DupeQuantityBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppColours.darkDupePink : AppColours.lightDupePink;

    return Positioned(
      bottom: 8,
      right: 7,
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
