import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../db/catalogue_db.dart';
import '../../db/price_history.dart';
import '../../db/price_updates.dart';
import '../../data/promo_covers.dart';
import '../../models/card_model.dart';
import '../../models/promo_category.dart';
import '../../models/set_model.dart';
import '../../providers/collection_provider.dart';
import '../../theme/app_colours.dart';
import '../../utils/holdings.dart';
import '../../widgets/deck_tile.dart';
import '../../widgets/promo_cover.dart';
import '../../widgets/set_card.dart';
import '../../widgets/settings_menu.dart';
import '../../widgets/value_summary_panel.dart';
import '../value_history/value_history_page.dart';
import 'portfolio_set_detail_page.dart';

String _setArtworkUrl(String setCode) =>
    'https://standbyinteractive.com/sets/${setCode}_thumbnail.png';

// Deck box images (transparent PNGs) live in their own R2 folder.
String _deckArtworkUrl(String setCode) =>
    'https://standbyinteractive.com/decks/${setCode}_thumbnail.png';

// What the Portfolio tab lists, picked from the View dropdown in the nav bar.
enum _PortfolioView { sets, decks, promos }

class PortfolioSetsPage extends StatefulWidget {
  const PortfolioSetsPage({super.key});

  @override
  State<PortfolioSetsPage> createState() => _PortfolioSetsPageState();
}

class _PortfolioSetsPageState extends State<PortfolioSetsPage> {
  bool _isLoading = true;
  _PortfolioView _view = _PortfolioView.sets;
  List<SetModel> _sets = [];
  List<SetModel> _decks = [];
  List<SetModel> _promoEvents = [];
  Map<String, List<CardModel>> _cardsBySet = {};
  List<CardModel> _allCards = [];
  List<SetModel> _allSets = [];
  PriceUpdates? _prices;

  @override
  void initState() {
    super.initState();
    // Reload when newer prices arrive from R2 so the values stay current.
    _prices = context.read<PriceUpdates>()..addListener(_reloadCards);
    // Defer to after the first frame — providers call notifyListeners()
    // synchronously and must not do so mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _prices?.removeListener(_reloadCards);
    super.dispose();
  }

  void _reloadCards() {
    if (!_isLoading) _load(reloadCollection: false);
  }

  Future<void> _load({bool reloadCollection = true}) async {
    final db = context.read<CatalogueDb>();
    if (reloadCollection) context.read<CollectionProvider>().loadAll();

    final sets = await db.getBoosterSets();
    final decks = await db.getSetsOfType('starter');
    final promoEvents = await db.getSetsOfType('promo');
    final allSets = await db.getSets();
    final allCards = await db.getAllCards();

    final grouped = <String, List<CardModel>>{};
    for (final card in allCards) {
      grouped.putIfAbsent(card.setCode, () => []).add(card);
    }

    if (!mounted) return;
    setState(() {
      _sets = sets;
      _decks = decks;
      _promoEvents = promoEvents;
      _cardsBySet = grouped;
      _allCards = allCards;
      _allSets = allSets;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PortfolioNavBar(
          view: _view,
          onViewChanged: (v) => setState(() => _view = v),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : switch (_view) {
                  _PortfolioView.sets =>
                    _SetsList(sets: _sets, cardsBySet: _cardsBySet, allCards: _allCards, allSets: _allSets),
                  _PortfolioView.decks =>
                    _DecksGrid(decks: _decks, cardsBySet: _cardsBySet, allCards: _allCards, allSets: _allSets),
                  _PortfolioView.promos =>
                    _PromosGrid(events: _promoEvents, cardsBySet: _cardsBySet, allCards: _allCards, allSets: _allSets),
                },
        ),
      ],
    );
  }
}

// --- Nav bar ----------------------------------------------------------------

class _PortfolioNavBar extends StatelessWidget {
  final _PortfolioView view;
  final ValueChanged<_PortfolioView> onViewChanged;

  const _PortfolioNavBar({required this.view, required this.onViewChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navColour = isDark ? AppColours.darkNavBar : AppColours.lightNavBar;
    final navText = isDark ? AppColours.darkSelectedNav : AppColours.lightSelectedNav;

    return Container(
      // Fills the status bar area too — SafeArea below keeps the actual
      // content clear of the notch/status bar.
      color: navColour,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _ViewSelector(view: view, onChanged: onViewChanged)),
              Text(
                'Portfolio',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: navText),
              ),
              const SizedBox(width: 16),
              SettingsMenu(iconColor: navText, pageName: 'Portfolio'),
            ],
          ),
        ),
      ),
    );
  }
}

class _ViewSelector extends StatelessWidget {
  final _PortfolioView view;
  final ValueChanged<_PortfolioView> onChanged;

  const _ViewSelector({required this.view, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navText = isDark ? AppColours.darkSelectedNav : AppColours.lightSelectedNav;

    final label = switch (view) {
      _PortfolioView.sets => 'Sets',
      _PortfolioView.decks => 'Decks',
      _PortfolioView.promos => 'Promos',
    };

    return Semantics(
      label: 'Select view: $label',
      button: true,
      excludeSemantics: true,
      child: PopupMenuButton<_PortfolioView>(
      tooltip: 'Select view',
      offset: const Offset(0, 40),
      onSelected: onChanged,
      itemBuilder: (_) => [
        CheckedPopupMenuItem(
          value: _PortfolioView.sets,
          checked: view == _PortfolioView.sets,
          child: const Text('Sets'),
        ),
        CheckedPopupMenuItem(
          value: _PortfolioView.decks,
          checked: view == _PortfolioView.decks,
          child: const Text('Decks'),
        ),
        CheckedPopupMenuItem(
          value: _PortfolioView.promos,
          checked: view == _PortfolioView.promos,
          child: const Text('Promos'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('View', style: TextStyle(fontSize: 10, color: navText.withValues(alpha: 0.75))),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: navText)),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down, size: 16, color: navText.withValues(alpha: 0.85)),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

// --- Sets list ---------------------------------------------------------------

class _SetsList extends StatelessWidget {
  final List<SetModel> sets;
  final Map<String, List<CardModel>> cardsBySet;
  final List<CardModel> allCards; // boosters, decks and promos
  final List<SetModel> allSets;

  const _SetsList({
    required this.sets,
    required this.cardsBySet,
    required this.allCards,
    required this.allSets,
  });

  @override
  Widget build(BuildContext context) {
    final collection = context.watch<CollectionProvider>();
    final history = context.watch<PriceHistory>().data;
    // Every card counted, across boosters, decks and promos — not only the
    // booster sets listed below.
    final holdings = holdingsFor(HoldingsKind.portfolio, allCards, collection);

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      // Item 0 is the value summary panel, then one card per set.
      itemCount: sets.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == 0) {
          return ValueSummaryPanel(
            label: 'Portfolio value',
            currentValue: holdingsValue(holdings, allCards),
            holdings: holdings,
            onViewHistory: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ValueHistoryPage(
                  kind: HoldingsKind.portfolio,
                  allCards: allCards,
                  sets: allSets,
                ),
              ),
            ),
          );
        }
        final set = sets[index - 1];
        final isUpcoming = !set.isAvailable;

        if (isUpcoming) {
          return SetCard(
            mode: SetCardMode.portfolio,
            setCode: set.code,
            setName: set.name,
            artworkUrl: _setArtworkUrl(set.code),
            ownedCount: 0,
            totalCount: 0,
            estimatedValue: 0,
            isComingSoon: true,
          );
        }

        final cards = cardsBySet[set.code] ?? const [];
        final ownedCards = cards.where((c) => collection.isOwned(c.cardId));
        final estimatedValue = ownedCards.fold<double>(0, (sum, c) => sum + c.priceOrZero);

        return SetCard(
          mode: SetCardMode.portfolio,
          setCode: set.code,
          setName: set.name,
          artworkUrl: _setArtworkUrl(set.code),
          ownedCount: ownedCards.length,
          totalCount: cards.length,
          estimatedValue: estimatedValue,
          valueTrend: _trend(history, holdingsFor(HoldingsKind.portfolio, cards, collection)),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PortfolioSetDetailPage(setCode: set.code)),
          ),
        );
      },
    );
  }
}

// --- Decks grid --------------------------------------------------------------

class _DecksGrid extends StatelessWidget {
  final List<SetModel> decks;
  final Map<String, List<CardModel>> cardsBySet;
  final List<CardModel> allCards;
  final List<SetModel> allSets;

  const _DecksGrid({
    required this.decks,
    required this.cardsBySet,
    required this.allCards,
    required this.allSets,
  });

  @override
  Widget build(BuildContext context) {
    final collection = context.watch<CollectionProvider>();
    final history = context.watch<PriceHistory>().data;
    final shown = decks.where((d) => d.isAvailable).toList();

    return _TwoPerRowGrid(
      allCards: allCards,
      allSets: allSets,
      names: [for (final d in shown) d.name],
      tileBuilder: (i, nameLines) {
        final deck = shown[i];
        final cards = cardsBySet[deck.code] ?? const [];
        final ownedCards = cards.where((c) => collection.isOwned(c.cardId));
        return DeckTile(
          setCode: deck.code,
          setName: deck.name,
          artworkUrl: _deckArtworkUrl(deck.code),
          ownedCount: ownedCards.length,
          totalCount: cards.length,
          estimatedValue: ownedCards.fold<double>(0, (sum, c) => sum + c.priceOrZero),
          valueTrend: _trend(history, holdingsFor(HoldingsKind.portfolio, cards, collection)),
          nameLines: nameLines,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PortfolioSetDetailPage(setCode: deck.code)),
          ),
        );
      },
    );
  }
}

// --- Promos grid -------------------------------------------------------------

// One tile per promo category (Basic PR Packs, Birthday, ...), each with its
// fixed blended card cover. Tapping opens all the category's cards.
class _PromosGrid extends StatelessWidget {
  final List<SetModel> events; // every promo event (sets with set_type 'promo')
  final Map<String, List<CardModel>> cardsBySet;
  final List<CardModel> allCards;
  final List<SetModel> allSets;

  const _PromosGrid({
    required this.events,
    required this.cardsBySet,
    required this.allCards,
    required this.allSets,
  });

  @override
  Widget build(BuildContext context) {
    final collection = context.watch<CollectionProvider>();
    final history = context.watch<PriceHistory>().data;

    // Released events of each category; categories with none are left out.
    final eventsOf = <String, List<SetModel>>{};
    for (final e in events.where((e) => e.isAvailable && e.promoCategory != null)) {
      eventsOf.putIfAbsent(e.promoCategory!, () => []).add(e);
    }
    final shown = [for (final c in promoCategories) if (eventsOf.containsKey(c.key)) c];

    return _TwoPerRowGrid(
      allCards: allCards,
      allSets: allSets,
      names: [for (final c in shown) c.name],
      tileBuilder: (i, nameLines) {
        final category = shown[i];
        final categoryEvents = eventsOf[category.key]!;
        final cards = [for (final e in categoryEvents) ...?cardsBySet[e.code]];
        final ownedCards = cards.where((c) => collection.isOwned(c.cardId));
        final layers = promoCovers[category.key] ?? const <CoverLayer>[];
        final cardsById = {for (final c in cards) c.cardId: c};
        return DeckTile(
          setCode: category.countLabel(categoryEvents.length),
          setName: category.name,
          artworkUrl: '',
          artwork: PromoCover(
            layers: layers,
            imageUrls: {
              for (final l in layers)
                if (cardsById[l.cardId.toString()] case final card?) card.cardId: card.imageUrl,
            },
          ),
          artworkAspectRatio: PromoCover.aspectRatio,
          typeLabel: '',
          ownedCount: ownedCards.length,
          totalCount: cards.length,
          estimatedValue: ownedCards.fold<double>(0, (sum, c) => sum + c.priceOrZero),
          valueTrend: _trend(history, holdingsFor(HoldingsKind.portfolio, cards, collection)),
          nameLines: nameLines,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PortfolioSetDetailPage.promoCategory(category.key)),
          ),
        );
      },
    );
  }
}

// The Decks and Promos layout: the value summary panel, then tiles two per row.
class _TwoPerRowGrid extends StatelessWidget {
  final List<CardModel> allCards;
  final List<SetModel> allSets;
  final List<String> names; // one per tile, for fitting the name lines
  final Widget Function(int index, int nameLines) tileBuilder;

  const _TwoPerRowGrid({
    required this.allCards,
    required this.allSets,
    required this.names,
    required this.tileBuilder,
  });

  static const double _spacing = 10;

  @override
  Widget build(BuildContext context) {
    final collection = context.watch<CollectionProvider>();
    final holdings = holdingsFor(HoldingsKind.portfolio, allCards, collection);
    final rowCount = (names.length / 2).ceil();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      // Item 0 is the value summary panel (same as the Sets view), then one
      // row of two tiles per item.
      itemCount: rowCount + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: _spacing),
            child: ValueSummaryPanel(
              label: 'Portfolio value',
              currentValue: holdingsValue(holdings, allCards),
              holdings: holdings,
              onViewHistory: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ValueHistoryPage(
                    kind: HoldingsKind.portfolio,
                    allCards: allCards,
                    sets: allSets,
                  ),
                ),
              ),
            ),
          );
        }
        final start = (index - 1) * 2;
        final end = (start + 2).clamp(0, names.length);
        // Both tiles of a row share the name height so they line up.
        final nameLines = DeckTile.nameLinesForRow(context, names.sublist(start, end));
        return Padding(
          padding: const EdgeInsets.only(bottom: _spacing),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: tileBuilder(start, nameLines)),
              const SizedBox(width: _spacing),
              Expanded(
                child: start + 1 < names.length ? tileBuilder(start + 1, nameLines) : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Which way a set's value moved at the last price update (null = unknown).
Trend? _trend(PriceHistoryData history, Map<String, int> holdings) {
  if (holdings.isEmpty) return null;
  final change = history.valueChange(holdings);
  return change == null ? null : trendOf(change);
}
