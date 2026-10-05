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
  double? _maxPrice;

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

  static const _priceOptions = [
    (label: '≤ £5', value: 5.0),
    (label: '≤ £10', value: 10.0),
    (label: '≤ £20', value: 20.0),
    (label: '≤ £50', value: 50.0),
    (label: '≤ £150', value: 150.0),
  ];

  @override
  void initState() {
    super.initState();
    final catalogue = context.read<CatalogueProvider>();
    _owned = catalogue.ownedFilter;
    _foil = catalogue.foilFilter;
    _rarities = Set.of(catalogue.rarities);
    _archetypes = Set.of(catalogue.archetypes);
    _maxPrice = catalogue.maxPrice;
  }

  void _resetAll() {
    setState(() {
      _owned = OwnedFilter.all;
      _foil = FoilFilter.all;
      _rarities = {};
      _archetypes = {};
      _maxPrice = null;
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

  void _selectPrice(double value) {
    setState(() => _maxPrice = (_maxPrice == value) ? null : value);
  }

  void _apply() {
    context.read<CatalogueProvider>().applyFilters(
          owned: _owned,
          foil: _foil,
          rarities: _rarities,
          archetypes: _archetypes,
          maxPrice: _maxPrice,
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
            for (final p in _priceOptions)
              FilterChipData(
                label: p.label,
                active: _maxPrice == p.value,
                onTap: () => _selectPrice(p.value),
              ),
          ],
        ),
      ],
    );
  }
}
