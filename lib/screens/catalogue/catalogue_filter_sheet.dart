import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../providers/catalogue_provider.dart';
import '../../widgets/filter_sheet_widgets.dart';

/// Bottom sheet for the Catalogue grid — Owned, Foil, Rarity, Archetype and
/// Estimated Value filters. Holds its own draft selections (seeded from the
/// current CatalogueProvider state) and only commits them on "Apply Filters",
/// so dismissing the sheet without applying leaves the grid untouched.
class CatalogueFilterSheet extends StatefulWidget {
  const CatalogueFilterSheet({super.key});

  @override
  State<CatalogueFilterSheet> createState() => _CatalogueFilterSheetState();
}

class _CatalogueFilterSheetState extends State<CatalogueFilterSheet> {
  late OwnedFilter _owned;
  late FoilFilter _foil;
  late Set<String> _rarities;
  late Set<String> _archetypes;
  // Selected price band (null = any price). Index into _priceOptions.
  int? _priceBand;

  static const _ownedOptions = [
    (OwnedFilter.all, 'All'),
    (OwnedFilter.owned, 'Owned'),
    (OwnedFilter.notOwned, 'Not owned'),
  ];

  static const _foilOptions = [
    (FoilFilter.all, 'All'),
    (FoilFilter.foilOnly, 'Foil only'),
    (FoilFilter.nonFoilOnly, 'Non-foil only'),
  ];

  // Prices are stored in yen, so the bands are in yen too. Each band
  // covers prices above `min` and up to and including `max`, so they don't
  // overlap — picking ¥1,001–¥3,000 hides everything cheaper.
  static const _priceOptions = [
    (label: '≤ ¥500', min: null, max: 500.0),
    (label: '¥501–¥1,000', min: 500.0, max: 1000.0),
    (label: '¥1,001–¥3,000', min: 1000.0, max: 3000.0),
    (label: '¥3,001–¥10,000', min: 3000.0, max: 10000.0),
    (label: '¥10,001–¥30,000', min: 10000.0, max: 30000.0),
    (label: '¥30,000+', min: 30000.0, max: null),
  ];

  @override
  void initState() {
    super.initState();
    final catalogue = context.read<CatalogueProvider>();
    _owned = catalogue.ownedFilter;
    _foil = catalogue.foilFilter;
    _rarities = Set.of(catalogue.rarities);
    _archetypes = Set.of(catalogue.archetypes);
    // Find which band matches the currently applied limits (if any).
    final idx = _priceOptions.indexWhere(
        (p) => p.min == catalogue.minPrice && p.max == catalogue.maxPrice);
    _priceBand = (idx < 0 || (catalogue.minPrice == null && catalogue.maxPrice == null))
        ? null
        : idx;
  }

  void _resetAll() {
    setState(() {
      _owned = OwnedFilter.all;
      _foil = FoilFilter.all;
      _rarities = {};
      _archetypes = {};
      _priceBand = null;
    });
  }

  void _toggleRarity(String value) {
    setState(() {
      if (!_rarities.remove(value)) _rarities.add(value);
    });
  }

  void _toggleArchetype(String value) {
    setState(() {
      if (!_archetypes.remove(value)) _archetypes.add(value);
    });
  }

  void _selectPrice(int band) {
    setState(() => _priceBand = (_priceBand == band) ? null : band);
  }

  void _apply() {
    context.read<CatalogueProvider>().applyFilters(
          owned: _owned,
          foil: _foil,
          rarities: _rarities,
          archetypes: _archetypes,
          minPrice: _priceBand == null ? null : _priceOptions[_priceBand!].min,
          maxPrice: _priceBand == null ? null : _priceOptions[_priceBand!].max,
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return FilterSheetScaffold(
      title: 'Filters',
      onResetAll: _resetAll,
      applyLabel: 'Apply Filters',
      onApply: _apply,
      sections: [
        FilterSection(
          label: 'Owned',
          chips: [
            for (final option in _ownedOptions)
              FilterChipData(
                label: option.$2,
                active: _owned == option.$1,
                onTap: () => setState(() => _owned = option.$1),
              ),
          ],
        ),
        FilterSection(
          label: 'Foil',
          chips: [
            for (final option in _foilOptions)
              FilterChipData(
                label: option.$2,
                active: _foil == option.$1,
                onTap: () => setState(() => _foil = option.$1),
              ),
          ],
        ),
        FilterSection(
          label: 'Rarity',
          chips: [
            for (final r in standardRarities)
              FilterChipData(label: r, active: _rarities.contains(r), onTap: () => _toggleRarity(r)),
            for (final r in goldRarities)
              FilterChipData(label: r, active: _rarities.contains(r), gold: true, onTap: () => _toggleRarity(r)),
          ],
        ),
        FilterSection(
          label: 'Archetype',
          chips: [
            for (final a in archetypeOptions)
              FilterChipData(
                label: a.label,
                active: _archetypes.contains(a.label),
                dot: a,
                onTap: () => _toggleArchetype(a.label),
              ),
          ],
        ),
        FilterSection(
          label: 'Estimated Value',
          chips: [
            for (var i = 0; i < _priceOptions.length; i++)
              FilterChipData(
                label: _priceOptions[i].label,
                active: _priceBand == i,
                onTap: () => _selectPrice(i),
              ),
          ],
        ),
      ],
    );
  }
}
