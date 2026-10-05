import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../db/catalogue_db.dart';
import '../../models/card_model.dart';
import '../../models/set_model.dart';
import '../../providers/collection_provider.dart';
import '../../theme/app_colours.dart';
import '../../widgets/set_card.dart';
import '../../widgets/settings_menu.dart';
import 'inventory_set_detail_page.dart';

String _setArtworkUrl(String setCode) =>
    'https://standbyinteractive.com/sets/${setCode}_thumbnail.png';

class InventorySetsPage extends StatefulWidget {
  const InventorySetsPage({super.key});

  @override
  State<InventorySetsPage> createState() => _InventorySetsPageState();
}

class _InventorySetsPageState extends State<InventorySetsPage> {
  bool _isLoading = true;
  List<SetModel> _sets = [];
  Map<String, List<CardModel>> _cardsBySet = {};

  @override
  void initState() {
    super.initState();
    // Defer to after the first frame — providers call notifyListeners()
    // synchronously and must not do so mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final db = context.read<CatalogueDb>();
    context.read<CollectionProvider>().loadAll();

    final sets = await db.getSets();
    final allCards = await db.getAllCards();

    final grouped = <String, List<CardModel>>{};
    for (final card in allCards) {
      grouped.putIfAbsent(card.setCode, () => []).add(card);
    }

    if (!mounted) return;
    setState(() {
      _sets = sets;
      _cardsBySet = grouped;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _InventoryNavBar(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _SetsList(sets: _sets, cardsBySet: _cardsBySet),
        ),
      ],
    );
  }
}

// --- Nav bar ----------------------------------------------------------------

class _InventoryNavBar extends StatelessWidget {
  const _InventoryNavBar();

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
              const Expanded(child: _ViewSelector()),
              Text(
                'Inventory',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: navText),
              ),
              const SizedBox(width: 16),
              SettingsMenu(iconColor: navText, pageName: 'Inventory'),
            ],
          ),
        ),
      ),
    );
  }
}

class _ViewSelector extends StatelessWidget {
  const _ViewSelector();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navText = isDark ? AppColours.darkSelectedNav : AppColours.lightSelectedNav;
    final muted = isDark ? AppColours.darkMutedText : AppColours.lightMutedText;

    return Semantics(
      label: 'Select view: Sets',
      button: true,
      excludeSemantics: true,
      child: PopupMenuButton<String>(
      tooltip: 'Select view',
      offset: const Offset(0, 40),
      onSelected: (_) {}, // "Sets" is the only available view for now
      itemBuilder: (_) => [
        const CheckedPopupMenuItem(
          value: 'sets',
          checked: true,
          child: Text('Sets'),
        ),
        PopupMenuItem(
          enabled: false,
          child: Opacity(
            opacity: 0.38,
            child: Row(
              children: [
                const Text('Decks'),
                const Spacer(),
                Text('Coming soon', style: TextStyle(fontSize: 9, color: muted, letterSpacing: 0.6)),
              ],
            ),
          ),
        ),
        PopupMenuItem(
          enabled: false,
          child: Opacity(
            opacity: 0.38,
            child: Row(
              children: [
                const Text('Promos'),
                const Spacer(),
                Text('Coming soon', style: TextStyle(fontSize: 9, color: muted, letterSpacing: 0.6)),
              ],
            ),
          ),
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
              Text('Sets', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: navText)),
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

  const _SetsList({required this.sets, required this.cardsBySet});

  @override
  Widget build(BuildContext context) {
    final collection = context.watch<CollectionProvider>();

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      itemCount: sets.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final set = sets[index];
        final isUpcoming = !set.isAvailable;

        if (isUpcoming) {
          return SetCard(
            mode: SetCardMode.inventory,
            setCode: set.code,
            setName: set.name,
            artworkUrl: _setArtworkUrl(set.code),
            ownedCount: 0,
            totalCount: 0,
            duplicateCount: 0,
            totalValue: 0,
            isComingSoon: true,
          );
        }

        final cards = cardsBySet[set.code] ?? const [];
        final ownedCards = cards.where((c) => collection.isOwned(c.cardId));

        // duplicateCount/totalValue sum (owned − 1) per card; the highest
        // value duplicate is the priciest card with at least one duplicate.
        var duplicateCount = 0;
        var totalValue = 0.0;
        CardModel? highestValueDupe;
        for (final card in cards) {
          final dupes = collection.duplicateCount(card.cardId);
          if (dupes <= 0) continue;
          duplicateCount += dupes;
          totalValue += dupes * card.priceUsd;
          if (highestValueDupe == null || card.priceUsd > highestValueDupe.priceUsd) {
            highestValueDupe = card;
          }
        }

        return SetCard(
          mode: SetCardMode.inventory,
          setCode: set.code,
          setName: set.name,
          artworkUrl: _setArtworkUrl(set.code),
          ownedCount: ownedCards.length,
          totalCount: cards.length,
          duplicateCount: duplicateCount,
          totalValue: totalValue,
          highestValueCardNumber: highestValueDupe?.cardNumber,
          highestValueCardRarity: highestValueDupe?.rarity,
          highestValueCardValue: highestValueDupe?.priceUsd,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => InventorySetDetailPage(setCode: set.code)),
          ),
        );
      },
    );
  }
}
