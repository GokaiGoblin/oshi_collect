import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../../widgets/filter_sheet_widgets.dart';

/// Snapshot of the Portfolio set-detail screen's sort + filter selections.
/// (Owned / Unowned isn't here — the All / Owned / Unowned control above the
/// grid already does that.)
class PortfolioFilterState {
  final ValueSort sort;
  final FoilFilter foil;
  final Set<String> rarities;
  final Set<String> archetypes;

  const PortfolioFilterState({
    this.sort = ValueSort.cardNumber,
    this.foil = FoilFilter.all,
    this.rarities = const {},
    this.archetypes = const {},
  });
}

/// Bottom sheet for the Portfolio set detail grid — Sort By, Rarity, Foil and
/// Archetype, matching the Inventory sheet. Holds its own draft selections
/// (seeded from [current]) and only hands them back via [onApply].
class PortfolioFilterSheet extends StatefulWidget {
  final PortfolioFilterState current;
  final ValueChanged<PortfolioFilterState> onApply;

  const PortfolioFilterSheet({super.key, required this.current, required this.onApply});

  @override
  State<PortfolioFilterSheet> createState() => _PortfolioFilterSheetState();
}

class _PortfolioFilterSheetState extends State<PortfolioFilterSheet> {
  late ValueSort _sort;
  late FoilFilter _foil;
  late Set<String> _rarities;
  late Set<String> _archetypes;

  static const _foilOptions = [
    (FoilFilter.all, 'All'),
    (FoilFilter.foilOnly, 'Foil only'),
    (FoilFilter.nonFoilOnly, 'Non-foil only'),
  ];

  @override
  void initState() {
    super.initState();
    _sort = widget.current.sort;
    _foil = widget.current.foil;
    _rarities = Set.of(widget.current.rarities);
    _archetypes = Set.of(widget.current.archetypes);
  }

  void _resetAll() {
    setState(() {
      _sort = ValueSort.cardNumber;
      _foil = FoilFilter.all;
      _rarities = {};
      _archetypes = {};
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

  void _apply() {
    widget.onApply(PortfolioFilterState(sort: _sort, foil: _foil, rarities: _rarities, archetypes: _archetypes));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return FilterSheetScaffold(
      title: 'Sort & Filter',
      onResetAll: _resetAll,
      applyLabel: 'Apply',
      onApply: _apply,
      sections: [
        valueSortSection(_sort, (s) => setState(() => _sort = s)),
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
      ],
    );
  }
}
