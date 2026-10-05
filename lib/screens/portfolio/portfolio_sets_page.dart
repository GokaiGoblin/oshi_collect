import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../db/catalogue_db.dart';
import '../../models/card_model.dart';
import '../../models/set_model.dart';
import '../../providers/collection_provider.dart';
import '../../theme/app_colours.dart';
import '../../widgets/set_card.dart';
import '../../widgets/settings_menu.dart';
import 'portfolio_set_detail_page.dart';

String _setArtworkUrl(String setCode) =>
    'https://standbyinteractive.com/sets/${setCode}_thumbnail.png';

class PortfolioSetsPage extends StatefulWidget {
  const PortfolioSetsPage({super.key});

  @override
  State<PortfolioSetsPage> createState() => _PortfolioSetsPageState();
}

class _PortfolioSetsPageState extends State<PortfolioSetsPage> {
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
        const _PortfolioNavBar(),
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

class _PortfolioNavBar extends StatelessWidget {
  const _PortfolioNavBar();

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
        final estimatedValue = ownedCards.fold<double>(0, (sum, c) => sum + c.priceUsd);

        return SetCard(
          mode: SetCardMode.portfolio,
          setCode: set.code,
          setName: set.name,
          artworkUrl: _setArtworkUrl(set.code),
          ownedCount: ownedCards.length,
          totalCount: cards.length,
          estimatedValue: estimatedValue,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PortfolioSetDetailPage(setCode: set.code)),
          ),
        );
      },
    );
  }
}
