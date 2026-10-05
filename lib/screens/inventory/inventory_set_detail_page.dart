import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../db/catalogue_db.dart';
import '../../utils/search_utils.dart';
import '../../models/card_model.dart';
import '../../models/enums.dart';
import '../../models/set_model.dart';
import '../../providers/collection_provider.dart';
import '../../providers/preferences_provider.dart';
import '../../theme/app_colours.dart';
import '../../widgets/card_tile.dart';
import '../../widgets/frosted_panel.dart';
import '../../widgets/app_background.dart';
import '../../widgets/settings_menu.dart';
import '../card_profile/card_profile_page.dart';
import 'inventory_filter_sheet.dart';

class InventorySetDetailPage extends StatefulWidget {
  final String setCode;

  const InventorySetDetailPage({super.key, required this.setCode});

  @override
  State<InventorySetDetailPage> createState() => _InventorySetDetailPageState();
}

class _InventorySetDetailPageState extends State<InventorySetDetailPage> {
  late String _setCode;
  String _searchQuery = '';
  bool _isLoading = true;
  List<SetModel> _sets = [];
  List<CardModel> _cards = [];
  InventoryFilterState _filterState = const InventoryFilterState();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _setCode = widget.setCode;
    // Defer to after the first frame — providers call notifyListeners()
    // synchronously and must not do so mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final db = context.read<CatalogueDb>();
    context.read<CollectionProvider>().loadAll();

    final sets = await db.getSets();
    final cards = await db.getCardsBySetOrdered(_setCode);

    if (!mounted) return;
    setState(() {
      _sets = sets;
      _cards = cards;
      _isLoading = false;
    });
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => InventoryFilterSheet(
        current: _filterState,
        onApply: (state) => setState(() => _filterState = state),
      ),
    );
  }

  Future<void> _selectSet(String code) async {
    if (code == _setCode) return;
    setState(() {
      _setCode = code;
      _isLoading = true;
    });

    final cards = await context.read<CatalogueDb>().getCardsBySetOrdered(code);

    if (!mounted) return;
    setState(() {
      _cards = cards;
      _isLoading = false;
    });
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final setName = _sets.where((s) => s.code == _setCode).firstOrNull?.name ?? _setCode;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            _DetailNavBar(
              setCode: _setCode,
              setName: setName,
              sets: _sets,
              onSelectSet: _selectSet,
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _CardGrid(cards: _cards, searchQuery: _searchQuery, filterState: _filterState, scrollController: _scrollController),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _SearchBar(
                      query: _searchQuery,
                      onChanged: (q) => setState(() => _searchQuery = q),
                      onOpenFilters: _openFilterSheet,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Nav bar ----------------------------------------------------------------

class _DetailNavBar extends StatelessWidget {
  final String setCode;
  final String setName;
  final List<SetModel> sets;
  final ValueChanged<String> onSelectSet;

  const _DetailNavBar({
    required this.setCode,
    required this.setName,
    required this.sets,
    required this.onSelectSet,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navColour = isDark ? AppColours.darkNavBar : AppColours.lightNavBar;
    final navText = isDark ? AppColours.darkSelectedNav : AppColours.lightSelectedNav;
    final activeItemBg = isDark ? const Color(0x0FFFFFFF) : const Color(0x0F000000);

    return Container(
      // Fills the status bar area too — SafeArea below keeps the actual
      // content clear of the notch/status bar.
      color: navColour,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                child: Semantics(
                  label: 'Set: $setName, tap to change',
                  button: true,
                  excludeSemantics: true,
                child: PopupMenuButton<String>(
                  tooltip: 'Select set',
                  offset: const Offset(0, 40),
                  onSelected: onSelectSet,
                  itemBuilder: (_) => [
                    for (final set in sets.where((s) => s.isAvailable))
                      PopupMenuItem(
                        value: set.code,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: set.code == setCode ? activeItemBg : null,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              SizedBox(
                                width: 48,
                                child: Text(
                                  set.code,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColours.gold),
                                ),
                              ),
                              Expanded(child: Text(set.name, style: const TextStyle(fontSize: 12))),
                            ],
                          ),
                        ),
                      ),
                  ],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Set', style: TextStyle(fontSize: 10, color: navText.withValues(alpha: 0.75))),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              setName,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: navText),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.keyboard_arrow_down, size: 16, color: navText.withValues(alpha: 0.85)),
                        ],
                      ),
                    ],
                  ),
                ),
                ),
              ),
              Text(
                'Inventory',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: navText),
              ),
              const SizedBox(width: 16),
              SettingsMenu(iconColor: navText, showCardViewToggle: true, pageName: 'Inventory Set Detail'),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Search bar + filter button ----------------------------------------------

class _SearchBar extends StatelessWidget {
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onOpenFilters;

  const _SearchBar({required this.query, required this.onChanged, required this.onOpenFilters});

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

// --- Card grid ----------------------------------------------------------------

class _CardGrid extends StatelessWidget {
  final List<CardModel> cards;
  final String searchQuery;
  final InventoryFilterState filterState;
  final ScrollController? scrollController;

  const _CardGrid({required this.cards, required this.searchQuery, required this.filterState, this.scrollController});

  static const double _spacing = 10;

  @override
  Widget build(BuildContext context) {
    final collection = context.watch<CollectionProvider>();
    final columns = context.watch<PreferencesProvider>().cardViewColumns;
    final gridSize = columns == 3 ? GridSize.three : GridSize.two;
    final query = normalizeCardNumberQuery(searchQuery.trim().toLowerCase());

    // Only cards owned more than once (i.e. with at least one duplicate) ever
    // appear in Inventory — this view is purely about surplus copies. The
    // list arrives pre-sorted by card_number from the DB query.
    final filtered = cards.where((card) {
      if (collection.duplicateCount(card.cardId) <= 0) return false;

      if (query.isNotEmpty) {
        final matchesSearch = card.nameJp.toLowerCase().contains(query) ||
            (card.nameEn?.toLowerCase().contains(query) ?? false) ||
            card.cardNumber.toLowerCase().contains(query);
        if (!matchesSearch) return false;
      }

      if (filterState.foil == FoilFilter.foilOnly && !card.isFoil) return false;
      if (filterState.foil == FoilFilter.nonFoilOnly && card.isFoil) return false;

      if (filterState.rarities.isNotEmpty && !filterState.rarities.contains(card.rarity)) return false;

      if (filterState.archetypes.isNotEmpty) {
        // archetype is stored as a comma-separated string (e.g. "Blue,Red") —
        // match if any of the card's archetypes are in the selected set
        final cardArchetypes = (card.archetype ?? '').split(',').map((a) => a.trim());
        if (!cardArchetypes.any(filterState.archetypes.contains)) return false;
      }

      return true;
    }).toList();

    switch (filterState.sort) {
      case InventorySort.cardNumber:
        break; // already sorted by card_number from the DB query
      case InventorySort.mostDuplicates:
        filtered.sort((a, b) =>
            collection.duplicateCount(b.cardId).compareTo(collection.duplicateCount(a.cardId)));
        break;
      case InventorySort.highestTotalValue:
        filtered.sort((a, b) {
          final aTotal = collection.duplicateCount(a.cardId) * a.priceUsd;
          final bTotal = collection.duplicateCount(b.cardId) * b.priceUsd;
          return bTotal.compareTo(aTotal);
        });
        break;
      case InventorySort.highestSingleValue:
        filtered.sort((a, b) => b.priceUsd.compareTo(a.priceUsd));
        break;
    }

    if (filtered.isEmpty) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final muted = isDark ? AppColours.darkMutedText : AppColours.lightMutedText;
      return Center(child: Text('No duplicates found', style: TextStyle(color: muted)));
    }

    final rowCount = (filtered.length / columns).ceil();

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(14, 74, 14, 16),
      itemCount: rowCount,
      itemBuilder: (context, rowIndex) {
        final start = rowIndex * columns;
        final rowCards = filtered.sublist(start, min(start + columns, filtered.length));

        return Padding(
          padding: const EdgeInsets.only(bottom: _spacing),
          child: Row(
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
          ),
        );
      },
    );
  }

  Widget _buildTile(
    BuildContext context,
    CardModel card,
    GridSize gridSize,
    CollectionProvider collection,
  ) {
    final dupes = collection.duplicateCount(card.cardId);
    return CardTile(
      card: card,
      gridSize: gridSize,
      dupeQuantity: dupes,
      totalValue: dupes * card.priceUsd,
      onTap: () {
        final idx = cards.indexWhere((c) => c.cardId == card.cardId);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CardProfilePage(
              cards: cards,
              initialIndex: idx < 0 ? 0 : idx,
            ),
          ),
        );
      },
    );
  }
}

