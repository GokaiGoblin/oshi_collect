import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/card_model.dart';
import '../../models/enums.dart';
import '../../models/set_model.dart';
import '../../db/catalogue_db.dart';
import '../../providers/catalogue_provider.dart';
import '../../providers/collection_provider.dart';
import '../../providers/preferences_provider.dart';
import '../../theme/app_colours.dart';
import '../../widgets/card_tile.dart';
import '../../widgets/frosted_panel.dart';
import '../../widgets/settings_menu.dart';
import '../card_profile/card_profile_page.dart';
import 'catalogue_filter_sheet.dart';

class CataloguePage extends StatefulWidget {
  const CataloguePage({super.key});

  @override
  State<CataloguePage> createState() => _CataloguePageState();
}

class _CataloguePageState extends State<CataloguePage> {
  @override
  void initState() {
    super.initState();
    // Defer to after the first frame — providers call notifyListeners()
    // synchronously and must not do so mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogueProvider>().load();
      context.read<CollectionProvider>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _CatalogueNavBar(),
        Expanded(
          child: Stack(
            children: [
              const Positioned.fill(child: _CardGrid()),
              const Positioned(top: 0, left: 0, right: 0, child: _SearchBar()),
            ],
          ),
        ),
      ],
    );
  }
}

// --- Nav bar --------------------------------------------------------------

class _CatalogueNavBar extends StatelessWidget {
  const _CatalogueNavBar();

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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(child: _SetSelector()),
              Text(
                'Catalogue',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: navText,
                ),
              ),
              const SizedBox(width: 16),
              SettingsMenu(iconColor: navText, showCardViewToggle: true, pageName: 'Catalogue'),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Set selector (taps open the two-part bottom sheet) -------------------

class _SetSelector extends StatelessWidget {
  const _SetSelector();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navText = isDark ? AppColours.darkSelectedNav : AppColours.lightSelectedNav;
    final catalogue = context.watch<CatalogueProvider>();

    final currentName = catalogue.selectedSet == null
        ? 'All Sets'
        : catalogue.sets
                .where((s) => s.code == catalogue.selectedSet)
                .firstOrNull
                ?.name ??
            catalogue.selectedSet!;

    return Semantics(
      label: 'Set: $currentName, tap to change',
      button: true,
      excludeSemantics: true,
      child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final catalogueProvider = context.read<CatalogueProvider>();
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => ChangeNotifierProvider.value(
            value: catalogueProvider,
            child: const _SetSelectorSheet(),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Set',
            style: TextStyle(fontSize: 11, color: navText.withValues(alpha: 0.75)),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  currentName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: navText),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down, size: 18, color: navText),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

// --- Set selector bottom sheet --------------------------------------------

class _SetSelectorSheet extends StatefulWidget {
  const _SetSelectorSheet();

  @override
  State<_SetSelectorSheet> createState() => _SetSelectorSheetState();
}

class _SetSelectorSheetState extends State<_SetSelectorSheet> {
  // Always defaults to Booster Sets when the sheet opens.
  String _activeType = 'booster';

  static const _types = [
    ('booster', 'Booster Sets'),
    ('starter', 'Starter Decks'),
    ('promo', 'Promos'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catalogue = context.watch<CatalogueProvider>();

    final sheetColour = isDark ? const Color(0xFF1C1A10) : AppColours.lightSelectedNav;
    final handleColour = isDark ? AppColours.darkFrameBorder : AppColours.lightFrameBorder;
    final primaryText = isDark ? AppColours.darkPrimaryText : AppColours.lightNavBar;
    final mutedText = isDark ? AppColours.darkMutedText : AppColours.lightMutedText;
    final dividerColour = isDark ? const Color(0x12FFFFFF) : const Color(0x33B4A0DC);
    final activeItemBg = isDark ? const Color(0x14FFFFFF) : const Color(0x14000000);

    // catalogue.sets already arrives in display order (release date, then
    // promo events by name).
    final filteredSets = catalogue.sets
        .where((s) => s.isAvailable && s.setType == _activeType)
        .toList();

    void select(String? code) {
      context.read<CatalogueProvider>().selectSet(code);
      Navigator.of(context).pop();
    }

    return Container(
      decoration: BoxDecoration(
        color: sheetColour,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: handleColour,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 6),
            // All Sets row
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => select(null),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: catalogue.selectedSet == null
                      ? BoxDecoration(
                          color: activeItemBg,
                          borderRadius: BorderRadius.circular(8),
                        )
                      : null,
                  child: Text(
                    'All Sets',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: primaryText,
                    ),
                  ),
                ),
              ),
            ),
            // Divider
            Container(
              height: 0.5,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: dividerColour,
            ),
            // Segmented control
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  for (int i = 0; i < _types.length; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    Expanded(
                      child: _TypeSegment(
                        label: _types[i].$2,
                        active: _activeType == _types[i].$1,
                        onTap: () => setState(() => _activeType = _types[i].$1),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Set list for the active type
            if (filteredSets.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Text(
                  'No sets available',
                  style: TextStyle(fontSize: 12, color: mutedText),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 8),
                itemCount: filteredSets.length,
                itemBuilder: (context, index) {
                  final set = filteredSets[index];
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => select(set.code),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        decoration: set.code == catalogue.selectedSet
                            ? BoxDecoration(
                                color: activeItemBg,
                                borderRadius: BorderRadius.circular(8),
                              )
                            : null,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            SizedBox(
                              width: 52,
                              child: Text(
                                set.code,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColours.gold,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                set.name,
                                style: TextStyle(fontSize: 13, color: primaryText),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

// Small segmented control button used inside _SetSelectorSheet.
class _TypeSegment extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TypeSegment({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeBg = isDark ? const Color(0xFF4C4018) : AppColours.lightNavBar;
    final activeText = isDark ? AppColours.darkPrimaryText : AppColours.lightSelectedNav;
    final inactiveBg = isDark ? const Color(0x0DFFFFFF) : const Color(0x99FFFFFF);
    final inactiveText = isDark ? const Color(0xFFA09880) : AppColours.lightSecondaryText;
    final borderColour = isDark ? AppColours.darkButtonBorder : AppColours.lightFrameBorder;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: active ? activeBg : inactiveBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColour, width: 0.5),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: active ? activeText : inactiveText,
            ),
          ),
        ),
      ),
    );
  }
}

// --- Search bar ------------------------------------------------------------

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  static const double _barHeight = 46;
  static const double _buttonSize = 52;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColours.darkMutedText : AppColours.lightMutedText;
    final primary = isDark ? AppColours.darkPrimaryText : AppColours.lightNavWhite;
    final hintColour = isDark ? AppColours.darkMutedText : AppColours.lightNavWhite;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
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
                        onChanged: (q) => context.read<CatalogueProvider>().search(q),
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
            Positioned(
              right: -10,
              top: -3,
              bottom: -3,
              child: _FilterButton(
                onTap: () => showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  barrierColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (_) => const CatalogueFilterSheet(),
                ),
              ),
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
            width: _SearchBar._buttonSize,
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

// --- Card grid --------------------------------------------------------------

class _CardGrid extends StatefulWidget {
  const _CardGrid();

  @override
  State<_CardGrid> createState() => _CardGridState();
}

class _CardGridState extends State<_CardGrid> {
  static const double _spacing = 10;

  final ScrollController _scrollController = ScrollController();
  // Updated each build so the scroll listener can see the current card list.
  List<CardModel> _prefetchCards = const [];
  int _prefetchColumns = 3;
  // Tracks the last seen selectedSet so we can jump to top on set change.
  Object? _prevSelectedSet = const Object();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_prefetchAhead);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Pre-caches images for the next 2 rows before they scroll into view.
  void _prefetchAhead() {
    if (!mounted || !_scrollController.hasClients || _prefetchCards.isEmpty) return;
    final screenW = MediaQuery.of(context).size.width;
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    const hPad = 28.0; // 14 left + 14 right list padding
    final cols = _prefetchColumns;
    final colW = (screenW - hPad - _spacing * (cols - 1)) / cols;
    // Artwork height = colW × (7/5) because CardTile aspect ratio is 5/7.
    final rowH = colW * (7.0 / 5.0) + CardTile.infoHeight(cols == 3, false, textScale: textScale) + _spacing;
    final offset = _scrollController.offset;
    final viewH = _scrollController.position.viewportDimension;
    final bottomRow = ((offset + viewH) / rowH).floor();
    for (int r = bottomRow + 1; r <= bottomRow + 2; r++) {
      final start = r * cols;
      if (start >= _prefetchCards.length) break;
      final end = min(start + cols, _prefetchCards.length);
      for (int i = start; i < end; i++) {
        precacheImage(CachedNetworkImageProvider(_prefetchCards[i].imageUrl), context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalogue = context.watch<CatalogueProvider>();
    final collection = context.watch<CollectionProvider>();
    final columns = context.watch<PreferencesProvider>().cardViewColumns;
    final gridSize = columns == 3 ? GridSize.three : GridSize.two;

    // Reset scroll to top whenever the selected set changes.
    final selectedSet = catalogue.selectedSet;
    if (selectedSet != _prevSelectedSet) {
      _prevSelectedSet = selectedSet;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) _scrollController.jumpTo(0);
      });
    }

    if (catalogue.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // "owned" filtering needs CollectionProvider — applied here rather than
    // inside CatalogueProvider which has no access to it.
    final cards = catalogue.cards.where((c) {
      switch (catalogue.ownedFilter) {
        case OwnedFilter.all:
          return true;
        case OwnedFilter.owned:
          return collection.isOwned(c.cardId);
        case OwnedFilter.notOwned:
          return !collection.isOwned(c.cardId);
      }
    }).toList();

    if (cards.isEmpty) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final muted = isDark ? AppColours.darkMutedText : AppColours.lightMutedText;
      return Center(child: Text('No cards found', style: TextStyle(color: muted)));
    }

    // Keep prefetch state current for the scroll listener.
    _prefetchCards = cards;
    _prefetchColumns = columns;

    if (catalogue.selectedSet != null) {
      // Single-set view: flat grid, no headers.
      final rowCount = (cards.length / columns).ceil();
      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(14, 74, 14, 16),
        itemCount: rowCount,
        itemBuilder: (context, rowIndex) {
          final start = rowIndex * columns;
          final rowCards = cards.sublist(start, min(start + columns, cards.length));
          return Padding(
            padding: const EdgeInsets.only(bottom: _spacing),
            child: _buildCardRow(context, rowCards, columns, gridSize, collection),
          );
        },
      );
    }

    // All-Sets view: cards grouped by set_type with section headers.
    return _buildGroupedView(context, cards, columns, gridSize, collection, catalogue.sets);
  }

  // Builds the grouped list for the All-Sets view.
  Widget _buildGroupedView(
    BuildContext context,
    List<CardModel> cards,
    int columns,
    GridSize gridSize,
    CollectionProvider collection,
    List<SetModel> sets,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark ? AppColours.darkSecondaryText : AppColours.lightSecondaryText;
    final primary = isDark ? AppColours.darkPrimaryText : AppColours.lightPrimaryText;
    final lineColour = isDark ? const Color(0x66D4CEB8) : const Color(0x99B4A0DC);

    final setLookup = {for (final s in sets) s.code: s};

    int typePriority(String setCode) {
      switch (setLookup[setCode]?.setType ?? '') {
        case 'booster':
          return 0;
        case 'starter':
          return 1;
        case 'promo':
          return 2;
        default:
          return 3;
      }
    }

    String typeLabel(int priority) {
      switch (priority) {
        case 0:
          return 'Booster Sets';
        case 1:
          return 'Starter Decks';
        case 2:
          return 'Promos';
        default:
          return 'Other';
      }
    }

    // Group cards by type priority. Cards arrive pre-sorted from the DB
    // (booster→starter→promo, then release_date ASC, card_number ASC), so
    // insertion order within each group is already correct.
    final Map<int, List<CardModel>> groups = {};
    for (final card in cards) {
      (groups[typePriority(card.setCode)] ??= []).add(card);
    }

    // Flatten into a mixed list:
    //   String        → type group header ("Booster Sets", "Promos", …)
    //   _SetHeader    → per-set sub-header ("hBP01 - Blooming Radiance", …)
    //   List<CardModel> → one row of card tiles
    final items = <Object>[];
    for (final priority in (groups.keys.toList()..sort())) {
      final groupCards = groups[priority]!;
      items.add(typeLabel(priority));

      // Sub-group by set_code, preserving existing release_date order.
      final Map<String, List<CardModel>> setGroups = {};
      final List<String> setOrder = [];
      for (final card in groupCards) {
        if (!setGroups.containsKey(card.setCode)) {
          setGroups[card.setCode] = [];
          setOrder.add(card.setCode);
        }
        setGroups[card.setCode]!.add(card);
      }

      for (final setCode in setOrder) {
        final setCards = setGroups[setCode]!;
        items.add(_SetHeader(setCode, setCards.first.setNameEn ?? setCode));
        for (var i = 0; i < setCards.length; i += columns) {
          items.add(setCards.sublist(i, min(i + columns, setCards.length)));
        }
      }
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(14, 74, 14, 16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        if (item is String) {
          // Divider-style type group header: label centred between two rules.
          return Padding(
            padding: EdgeInsets.fromLTRB(2, index == 0 ? 10 : 20, 2, 8),
            child: Row(
              children: [
                Expanded(child: Divider(color: lineColour, thickness: 1.0, height: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: secondary,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: lineColour, thickness: 1.0, height: 1)),
              ],
            ),
          );
        }

        if (item is _SetHeader) {
          // Per-set sub-header: "{set_code} - {set_name}", left-aligned.
          // Promo events have internal codes, so they show their name only.
          final prevIsGroupHeader = index > 0 && items[index - 1] is String;
          return Padding(
            padding: EdgeInsets.fromLTRB(2, prevIsGroupHeader ? 4 : 18, 2, 6),
            child: Text(
              setLookup[item.setCode]?.setType == 'promo'
                  ? item.setName
                  : '${item.setCode} - ${item.setName}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: primary,
              ),
            ),
          );
        }

        final rowCards = item as List<CardModel>;
        return Padding(
          padding: const EdgeInsets.only(bottom: _spacing),
          child: _buildCardRow(context, rowCards, columns, gridSize, collection),
        );
      },
    );
  }

  // One row of card tiles. Fixed-height info panels (CardTile.infoHeight) mean
  // every tile in a row is the same height — no IntrinsicHeight pass needed.
  Widget _buildCardRow(
    BuildContext context,
    List<CardModel> rowCards,
    int columns,
    GridSize gridSize,
    CollectionProvider collection,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < columns; i++) ...[
          if (i > 0) const SizedBox(width: _spacing),
          Expanded(
            child: i < rowCards.length
                ? _buildTile(context, rowCards[i], gridSize, collection)
                : const SizedBox.shrink(),
          ),
        ],
      ],
    );
  }

  Widget _buildTile(
    BuildContext context,
    CardModel card,
    GridSize gridSize,
    CollectionProvider collection,
  ) {
    return CardTile(
      card: card,
      gridSize: gridSize,
      showDupeDot: collection.duplicateCount(card.cardId) > 0,
      onTap: () async {
        final db = context.read<CatalogueDb>();
        final setCards = await db.getCardsBySetOrdered(card.setCode);
        final idx = setCards.indexWhere((c) => c.cardId == card.cardId);
        if (!context.mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CardProfilePage(
              cards: setCards,
              initialIndex: idx < 0 ? 0 : idx,
            ),
          ),
        );
      },
    );
  }
}

// Marker for a per-set sub-header row in the All-Sets grouped list.
class _SetHeader {
  final String setCode;
  final String setName;
  const _SetHeader(this.setCode, this.setName);
}
