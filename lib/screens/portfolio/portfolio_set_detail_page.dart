import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../db/catalogue_db.dart';
import '../../models/card_model.dart';
import '../../models/enums.dart';
import '../../models/promo_category.dart';
import '../../models/set_model.dart';
import '../../providers/collection_provider.dart';
import '../../providers/preferences_provider.dart';
import '../../theme/app_colours.dart';
import '../../utils/search_utils.dart';
import '../../widgets/card_tile.dart';
import '../../widgets/deck_tile.dart';
import '../../widgets/frosted_panel.dart';
import '../../widgets/app_background.dart';
import '../../widgets/search_filter_bar.dart';
import '../../widgets/settings_menu.dart';
import '../card_profile/card_profile_page.dart';
import 'portfolio_filter_sheet.dart';

enum _OwnershipFilter { all, owned, unowned }

// The cards of one booster set or starter deck, or (opened from the Promos
// view) of one promo category, with a heading for each promo event in it.
class PortfolioSetDetailPage extends StatefulWidget {
  final String? setCode;
  final String? promoCategory; // a key from promo_category.dart

  const PortfolioSetDetailPage({super.key, required String this.setCode}) : promoCategory = null;

  const PortfolioSetDetailPage.promoCategory(String this.promoCategory, {super.key}) : setCode = null;

  @override
  State<PortfolioSetDetailPage> createState() => _PortfolioSetDetailPageState();
}

class _PortfolioSetDetailPageState extends State<PortfolioSetDetailPage> {
  // Exactly one of these is set: the open set/deck, or the open promo category.
  String? _setCode;
  String? _category;
  _OwnershipFilter _filter = _OwnershipFilter.all;
  String _searchQuery = '';
  PortfolioFilterState _filterState = const PortfolioFilterState();
  bool _isLoading = true;
  List<SetModel> _sets = [];
  List<CardModel> _cards = [];
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _setCode = widget.setCode;
    _category = widget.promoCategory;
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

    // The dropdown lists sets of the same kind as the one opened: booster
    // sets, starter decks from the Decks view, or (for a promo category)
    // the categories of the promo events.
    final List<SetModel> sets;
    if (_category != null) {
      sets = await db.getSetsOfType('promo');
    } else {
      final opened = (await db.getSets()).where((s) => s.code == _setCode).firstOrNull;
      sets = await db.getSetsOfType(opened?.setType ?? 'booster');
    }
    final cards = await _cardsFor(db, sets);

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
      builder: (_) => PortfolioFilterSheet(
        current: _filterState,
        onApply: (state) => setState(() => _filterState = state),
      ),
    );
  }

  // The open set's cards, or every card of the open promo category, event by
  // event in display order.
  Future<List<CardModel>> _cardsFor(CatalogueDb db, List<SetModel> sets) async {
    if (_category == null) return db.getCardsBySetOrdered(_setCode!);
    return [
      for (final e in _eventsOf(sets, _category!)) ...await db.getCardsBySetOrdered(e.code),
    ];
  }

  static List<SetModel> _eventsOf(List<SetModel> sets, String category) =>
      [for (final s in sets) if (s.isAvailable && s.promoCategory == category) s];

  // [value] is a set code, or a promo category key in category mode.
  Future<void> _select(String value) async {
    if (value == (_category ?? _setCode)) return;
    setState(() {
      if (_category != null) {
        _category = value;
      } else {
        _setCode = value;
      }
      _isLoading = true;
    });

    final cards = await _cardsFor(context.read<CatalogueDb>(), _sets);

    if (!mounted) return;
    setState(() {
      _cards = cards;
      _isLoading = false;
    });
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    // What the nav bar shows, and its dropdown entries: (value, code, name).
    final String navLabel, title;
    final List<(String, String?, String)> items;
    double codeWidth = 48;
    Map<String, String>? headings;
    if (_category != null) {
      navLabel = 'Promos';
      title = promoCategoryByKey(_category!)?.name ?? _category!;
      items = [
        for (final c in promoCategories)
          if (_eventsOf(_sets, c.key).isNotEmpty) (c.key, null, c.name),
      ];
      // A heading above each promo event's cards.
      headings = {for (final e in _eventsOf(_sets, _category!)) e.code: e.name};
    } else {
      final current = _sets.where((s) => s.code == _setCode).firstOrNull;
      final isDeck = current?.setType == 'starter';
      // Decks drop the "Starter:" / "Live:" prefix so the member name fits.
      String shortName(SetModel s) => isDeck ? DeckTile.splitName(s.name).$2 : s.name;
      navLabel = isDeck ? 'Deck' : 'Set';
      title = current == null ? _setCode! : shortName(current);
      items = [for (final s in _sets.where((s) => s.isAvailable)) (s.code, s.code, shortName(s))];
      // deck codes ("hSD20") need more room than "hBP01"
      if (isDeck) codeWidth = 60;
    }

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            _DetailNavBar(
              label: navLabel,
              title: title,
              selected: _category ?? _setCode!,
              items: items,
              codeWidth: codeWidth,
              onSelect: _select,
            ),
            _FilterSegmentedControl(
              filter: _filter,
              onChanged: (f) => setState(() => _filter = f),
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _CardGrid(
                            cards: _cards,
                            filter: _filter,
                            searchQuery: _searchQuery,
                            filterState: _filterState,
                            headings: headings,
                            scrollController: _scrollController,
                          ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SearchFilterBar(
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
  final String label; // 'Set', 'Deck' or 'Promos'
  final String title; // the open set/deck/category name
  final String selected; // value of the open entry
  // Dropdown entries: (value, gold code shown before the name or null, name).
  final List<(String, String?, String)> items;
  final double codeWidth;
  final ValueChanged<String> onSelect;

  const _DetailNavBar({
    required this.label,
    required this.title,
    required this.selected,
    required this.items,
    required this.codeWidth,
    required this.onSelect,
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
                  label: '$label: $title, tap to change',
                  button: true,
                  excludeSemantics: true,
                child: PopupMenuButton<String>(
                  tooltip: label == 'Promos' ? 'Select category' : 'Select ${label.toLowerCase()}',
                  offset: const Offset(0, 40),
                  onSelected: onSelect,
                  itemBuilder: (_) => [
                    for (final (value, code, name) in items)
                      PopupMenuItem(
                        value: value,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: value == selected ? activeItemBg : null,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              if (code != null)
                                SizedBox(
                                  width: codeWidth,
                                  child: Text(
                                    code,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColours.gold),
                                  ),
                                ),
                              Expanded(child: Text(name, style: const TextStyle(fontSize: 12))),
                            ],
                          ),
                        ),
                      ),
                  ],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label, style: TextStyle(fontSize: 10, color: navText.withValues(alpha: 0.75))),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              title,
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
                'Portfolio',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: navText),
              ),
              const SizedBox(width: 16),
              SettingsMenu(iconColor: navText, showCardViewToggle: true, pageName: 'Portfolio Set Detail'),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Segmented filter control -------------------------------------------------

class _FilterSegmentedControl extends StatelessWidget {
  final _OwnershipFilter filter;
  final ValueChanged<_OwnershipFilter> onChanged;

  const _FilterSegmentedControl({required this.filter, required this.onChanged});

  static const _options = [
    (_OwnershipFilter.all, 'All'),
    (_OwnershipFilter.owned, 'Owned'),
    (_OwnershipFilter.unowned, 'Unowned'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackColour = isDark ? const Color(0x0FFFFFFF) : const Color(0x0F000000);
    final trackBorder = isDark ? const Color(0x14FFFFFF) : const Color(0x73FFFFFF);
    final dividerColour = isDark ? const Color(0x0FFFFFFF) : const Color(0x4DFFFFFF);
    final inactiveText = isDark ? AppColours.darkMutedText : AppColours.lightSecondaryText;
    final activeBg = isDark ? AppColours.darkNavBar : AppColours.lightNavBar;
    final activeText = isDark ? AppColours.darkSelectedNav : AppColours.lightSelectedNav;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: FrostedPanel.blurSigma, sigmaY: FrostedPanel.blurSigma),
          child: Container(
            decoration: BoxDecoration(
              color: trackColour,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: trackBorder, width: 0.5),
            ),
            child: Row(
              children: [
                for (var i = 0; i < _options.length; i++) ...[
                  if (i > 0) Container(width: 0.5, height: 20, color: dividerColour),
                  Expanded(
                    child: _SegmentButton(
                      label: _options[i].$2,
                      isActive: filter == _options[i].$1,
                      activeBg: activeBg,
                      activeText: activeText,
                      inactiveText: inactiveText,
                      onTap: () => onChanged(_options[i].$1),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color activeBg;
  final Color activeText;
  final Color inactiveText;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    required this.isActive,
    required this.activeBg,
    required this.activeText,
    required this.inactiveText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isActive ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isActive ? activeText : inactiveText,
            ),
          ),
        ),
      ),
    );
  }
}

// --- Card grid ----------------------------------------------------------------

class _CardGrid extends StatelessWidget {
  final List<CardModel> cards;
  final _OwnershipFilter filter;
  final String searchQuery;
  final PortfolioFilterState filterState;
  // Promo category: event name by set code, shown as a heading above each
  // event's cards. Null = one plain grid.
  final Map<String, String>? headings;
  final ScrollController? scrollController;

  const _CardGrid({
    required this.cards,
    required this.filter,
    required this.searchQuery,
    required this.filterState,
    this.headings,
    this.scrollController,
  });

  static const double _spacing = 10;

  @override
  Widget build(BuildContext context) {
    final collection = context.watch<CollectionProvider>();
    final columns = context.watch<PreferencesProvider>().cardViewColumns;
    final gridSize = columns == 3 ? GridSize.three : GridSize.two;

    final query = normalizeCardNumberQuery(searchQuery.trim().toLowerCase());

    final matching = cards.where((card) {
      final owned = collection.isOwned(card.cardId);
      if (filter == _OwnershipFilter.owned && !owned) return false;
      if (filter == _OwnershipFilter.unowned && owned) return false;

      if (query.isNotEmpty && !card.matchesSearch(query)) return false;

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
    final filtered = sortByValueWithinSets(matching, filterState.sort);

    if (filtered.isEmpty) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final muted = isDark ? AppColours.darkMutedText : AppColours.lightMutedText;
      return Center(child: Text('No cards found', style: TextStyle(color: muted)));
    }

    // The list's entries: rows of cards, each event's rows led by its heading
    // (a String) when [headings] is set. Cards of one event are always next to
    // each other - sorting by value stays within each event.
    final entries = <Object>[];
    void addRows(List<CardModel> group) {
      for (var i = 0; i < group.length; i += columns) {
        entries.add(group.sublist(i, min(i + columns, group.length)));
      }
    }

    if (headings == null) {
      addRows(filtered);
    } else {
      var i = 0;
      while (i < filtered.length) {
        final code = filtered[i].setCode;
        var j = i;
        while (j < filtered.length && filtered[j].setCode == code) {
          j++;
        }
        entries.add(code);
        addRows(filtered.sublist(i, j));
        i = j;
      }
    }

    return ListView.builder(
      controller: scrollController,
      // Top padding leaves room for the search bar floating over the grid.
      padding: const EdgeInsets.fromLTRB(14, SearchFilterBar.gridTopPadding, 14, 16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        if (entry is String) {
          final eventCards = cards.where((c) => c.setCode == entry);
          return _EventHeading(
            name: headings![entry] ?? entry,
            ownedCount: eventCards.where((c) => collection.isOwned(c.cardId)).length,
            totalCount: eventCards.length,
            isFirst: index == 0,
          );
        }
        final rowCards = entry as List<CardModel>;
        final nameLines = CardTile.nameLinesForRow(
            context, rowCards, columns, context.read<PreferencesProvider>().japaneseNames);

        return Padding(
          padding: const EdgeInsets.only(bottom: _spacing),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < columns; i++) ...[
                if (i > 0) const SizedBox(width: _spacing),
                Expanded(
                  child: i < rowCards.length
                      ? _buildTile(context, rowCards[i], gridSize, collection, nameLines)
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
    int nameLines,
  ) {
    return CardTile(
      card: card,
      gridSize: gridSize,
      nameLines: nameLines,
      showPrice: true,
      isUnowned: !collection.isOwned(card.cardId),
      showDupeDot: collection.duplicateCount(card.cardId) > 0,
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

// The name of a promo event above its cards in a promo category, with how
// many of the event's cards are owned.
class _EventHeading extends StatelessWidget {
  final String name;
  final int ownedCount;
  final int totalCount;
  final bool isFirst;

  const _EventHeading({
    required this.name,
    required this.ownedCount,
    required this.totalCount,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColours.darkPrimaryText : AppColours.lightPrimaryText;
    final secondary = isDark ? AppColours.darkSecondaryText : AppColours.lightSecondaryText;

    return Semantics(
      header: true,
      label: '$name, $ownedCount of $totalCount owned',
      excludeSemantics: true,
      child: Padding(
        padding: EdgeInsets.fromLTRB(2, isFirst ? 0 : 6, 2, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: primary),
              ),
            ),
            const SizedBox(width: 8),
            Text('$ownedCount/$totalCount', style: TextStyle(fontSize: 11, color: secondary)),
          ],
        ),
      ),
    );
  }
}
