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
  String? _selectedSet; // null = "All Sets"
  bool _isLoading = false;

  // Filter sheet state — "owned" is applied by the catalogue grid itself
  // (it needs CollectionProvider, which this provider has no access to);
  // everything else is applied here in _applyFilters.
  OwnedFilter _ownedFilter = OwnedFilter.all;
  FoilFilter _foilFilter = FoilFilter.all;
  Set<String> _rarities = {};
  Set<String> _archetypes = {};
  double? _maxPrice;

  List<CardModel> get cards => _filtered;
  List<SetModel> get sets => _sets;
  String? get selectedSet => _selectedSet;
  bool get isLoading => _isLoading;

  OwnedFilter get ownedFilter => _ownedFilter;
  FoilFilter get foilFilter => _foilFilter;
  Set<String> get rarities => _rarities;
  Set<String> get archetypes => _archetypes;
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
    _allCards = _selectedSet == null
        ? await _db.getAllCards()
        : await _db.getCardsBySetOrdered(_selectedSet!);
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
    double? maxPrice,
  }) {
    _ownedFilter = owned;
    _foilFilter = foil;
    _rarities = rarities;
    _archetypes = archetypes;
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

      // Cards with no known price can't be shown as under a price limit.
      if (_maxPrice != null && (c.priceJpy == null || c.priceJpy! > _maxPrice!)) return false;

      return true;
    }).toList();
  }
}
