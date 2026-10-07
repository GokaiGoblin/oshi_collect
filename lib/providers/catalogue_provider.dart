import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../models/enums.dart';
import '../models/set_model.dart';
import '../db/catalogue_db.dart';
import '../utils/search_utils.dart';

class CatalogueProvider extends ChangeNotifier {
  final CatalogueDb _db;

  CatalogueProvider(this._db);

  List<CardModel> _allCards = [];
  List<CardModel> _filtered = [];
  List<SetModel> _sets = [];
  String _searchQuery = '';
  /// Special selection value meaning "every promo event at once".
  /// Not a real set code — it never appears in the database.
  static const allPromos = '__all_promos__';

  String? _selectedSet; // null = "All Sets", allPromos = "All Promos"
  bool _isLoading = false;

  // Filter sheet state — "owned" is applied by the catalogue grid itself
  // (it needs CollectionProvider, which this provider has no access to);
  // everything else is applied here in _applyFilters.
  OwnedFilter _ownedFilter = OwnedFilter.all;
  FoilFilter _foilFilter = FoilFilter.all;
  Set<String> _rarities = {};
  Set<String> _archetypes = {};
  // Price band: cards priced above _minPrice and at or below _maxPrice.
  // Either end can be null (no lower limit / no upper limit).
  double? _minPrice;
  double? _maxPrice;

  List<CardModel> get cards => _filtered;
  List<SetModel> get sets => _sets;
  String? get selectedSet => _selectedSet;
  bool get isLoading => _isLoading;

  OwnedFilter get ownedFilter => _ownedFilter;
  FoilFilter get foilFilter => _foilFilter;
  Set<String> get rarities => _rarities;
  Set<String> get archetypes => _archetypes;
  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    _sets = await _db.getSets();
    await _loadCards();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> selectSet(String? setCode) async {
    if (_selectedSet == setCode) return;
    _isLoading = true;
    _selectedSet = setCode;
    notifyListeners();

    await _loadCards();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadCards() async {
    if (_selectedSet == null) {
      _allCards = await _db.getAllCards();
    } else if (_selectedSet == allPromos) {
      // getAllCards already returns promos in event display order.
      _allCards = (await _db.getAllCards()).where((c) => c.setType == 'promo').toList();
    } else {
      _allCards = await _db.getCardsBySetOrdered(_selectedSet!);
    }
    _applyFilters();
  }

  void search(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  /// Commits a full set of filter sheet selections and re-applies them.
  /// "owned" is stored here purely so the sheet can read it back when
  /// re-opened — the actual owned/unowned split happens in the grid.
  void applyFilters({
    required OwnedFilter owned,
    required FoilFilter foil,
    required Set<String> rarities,
    required Set<String> archetypes,
    double? minPrice,
    double? maxPrice,
  }) {
    _ownedFilter = owned;
    _foilFilter = foil;
    _rarities = rarities;
    _archetypes = archetypes;
    _minPrice = minPrice;
    _maxPrice = maxPrice;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filtered = _allCards.where((c) {
      if (_searchQuery.isNotEmpty) {
        final q = normalizeCardNumberQuery(_searchQuery.toLowerCase());
        if (!c.matchesSearch(q)) return false;
      }

      if (_foilFilter == FoilFilter.foilOnly && !c.isFoil) return false;
      if (_foilFilter == FoilFilter.nonFoilOnly && c.isFoil) return false;

      if (_rarities.isNotEmpty && !_rarities.contains(c.rarity)) return false;

      if (_archetypes.isNotEmpty) {
        // archetype is stored as a comma-separated string (e.g. "Blue,Red") —
        // match if any of the card's archetypes are in the selected set
        final cardArchetypes = (c.archetype ?? '').split(',').map((a) => a.trim());
        if (!cardArchetypes.any(_archetypes.contains)) return false;
      }

      // Price band. Cards with no known price can't be placed in a band,
      // so they're hidden whenever a band is selected.
      if (_minPrice != null || _maxPrice != null) {
        final price = c.priceJpy;
        if (price == null) return false;
        if (_minPrice != null && price <= _minPrice!) return false;
        if (_maxPrice != null && price > _maxPrice!) return false;
      }

      return true;
    }).toList();
  }
}
