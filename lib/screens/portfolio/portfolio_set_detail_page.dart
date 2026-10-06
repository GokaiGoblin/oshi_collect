import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../db/catalogue_db.dart';
import '../../models/card_model.dart';
import '../../models/enums.dart';
import '../../models/set_model.dart';
import '../../providers/collection_provider.dart';
import '../../providers/preferences_provider.dart';
import '../../theme/app_colours.dart';
import '../../widgets/card_tile.dart';
import '../../widgets/app_background.dart';
import '../../widgets/settings_menu.dart';
import '../card_profile/card_profile_page.dart';

enum _OwnershipFilter { all, owned, unowned }

class PortfolioSetDetailPage extends StatefulWidget {
  final String setCode;

  const PortfolioSetDetailPage({super.key, required this.setCode});

  @override
  State<PortfolioSetDetailPage> createState() => _PortfolioSetDetailPageState();
}

class _PortfolioSetDetailPageState extends State<PortfolioSetDetailPage> {
  late String _setCode;
  _OwnershipFilter _filter = _OwnershipFilter.all;
  bool _isLoading = true;
  List<SetModel> _sets = [];
  List<CardModel> _cards = [];
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

    final sets = await db.getBoosterSets();
    final cards = await db.getCardsBySetOrdered(_setCode);

    if (!mounted) return;
    setState(() {
      _sets = sets;
      _cards = cards;
      _isLoading = false;
    });
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
            _FilterSegmentedControl(
              filter: _filter,
              onChanged: (f) => setState(() => _filter = f),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _CardGrid(cards: _cards, filter: _filter, scrollController: _scrollController),
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
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
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
  final ScrollController? scrollController;

  const _CardGrid({required this.cards, required this.filter, this.scrollController});

  static const double _spacing = 10;

  @override
  Widget build(BuildContext context) {
    final collection = context.watch<CollectionProvider>();
    final columns = context.watch<PreferencesProvider>().cardViewColumns;
    final gridSize = columns == 3 ? GridSize.three : GridSize.two;

    final filtered = cards.where((card) {
      final owned = collection.isOwned(card.cardId);
      switch (filter) {
        case _OwnershipFilter.all:
          return true;
        case _OwnershipFilter.owned:
          return owned;
        case _OwnershipFilter.unowned:
          return !owned;
      }
    }).toList();

    if (filtered.isEmpty) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final muted = isDark ? AppColours.darkMutedText : AppColours.lightMutedText;
      return Center(child: Text('No cards found', style: TextStyle(color: muted)));
    }

    final rowCount = (filtered.length / columns).ceil();

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
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
    return CardTile(
      card: card,
      gridSize: gridSize,
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

