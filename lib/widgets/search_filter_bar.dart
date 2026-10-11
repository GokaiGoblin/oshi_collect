import 'package:flutter/material.dart';

import '../theme/app_colours.dart';
import 'frosted_panel.dart';

/// Frosted search bar with the round filter button overlapping its right
/// end — used on the Inventory and Portfolio set-detail grids. Place it over
/// the top of the grid (the grid leaves [gridTopPadding] of space for it).
class SearchFilterBar extends StatelessWidget {
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onOpenFilters;

  const SearchFilterBar({super.key, required this.query, required this.onChanged, required this.onOpenFilters});

  static const double _barHeight = 46;

  // Space above and below the bar. The grids underneath start at
  // [gridTopPadding] so the first row sits just below the bar — change these
  // together. Shared with the Catalogue's own search bar.
  static const double topGap = 6;
  static const double bottomGap = 6;
  static const double gridTopPadding = topGap + _barHeight + bottomGap + 4;
  static const double _buttonSize = 52;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColours.darkMutedText : AppColours.lightMutedText;
    final primary = isDark ? AppColours.darkPrimaryText : AppColours.lightNavWhite;
    final hintColour = isDark ? AppColours.darkMutedText : AppColours.lightNavWhite;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, topGap, 16, bottomGap),
      child: SizedBox(
        height: _barHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: FrostedPanel(
                borderRadius: BorderRadius.circular(_barHeight / 2),
                padding: const EdgeInsets.fromLTRB(16, 0, 44, 0),
                child: Row(
                  children: [
                    Icon(Icons.search, size: 18, color: muted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        onChanged: onChanged,
                        style: TextStyle(fontSize: 13, color: primary),
                        cursorColor: primary,
                        decoration: InputDecoration(
                          isCollapsed: true,
                          border: InputBorder.none,
                          hintText: 'Search cards…',
                          hintStyle: TextStyle(fontSize: 13, color: hintColour),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Overlaps and spills past the search bar's right edge — the
            // "cut off" look from the mockup
            Positioned(
              right: -10,
              top: -3,
              bottom: -3,
              child: _FilterButton(onTap: onOpenFilters),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final VoidCallback onTap;
  const _FilterButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColour = isDark ? AppColours.darkNavBar : AppColours.lightSkyBlue;
    final iconColour = isDark ? AppColours.darkSelectedNav : AppColours.lightButtonText;

    return Tooltip(
      message: 'Filter',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: SearchFilterBar._buttonSize,
            decoration: BoxDecoration(
              color: bgColour,
              shape: BoxShape.circle,
              border: isDark ? Border.all(color: AppColours.darkSelectedNav) : null,
            ),
            alignment: Alignment.center,
            child: Icon(Icons.tune_rounded, size: 20, color: iconColour),
          ),
        ),
      ),
    );
  }
}

