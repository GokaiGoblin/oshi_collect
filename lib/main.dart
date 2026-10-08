import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'db/catalogue_db.dart';
import 'db/price_updates.dart';
import 'db/user_db.dart';
import 'providers/catalogue_provider.dart';
import 'providers/collection_provider.dart';
import 'providers/preferences_provider.dart';
import 'theme/app_theme.dart';
import 'widgets/app_background.dart';
import 'screens/catalogue/catalogue_page.dart';
import 'screens/portfolio/portfolio_sets_page.dart';
import 'screens/inventory/inventory_sets_page.dart';

void main() {
  // Needed before anything touches plugins (the price cache uses path_provider).
  WidgetsFlutterBinding.ensureInitialized();
  // Created once here (not in build) so a rebuild can't start a second
  // database or price download.
  final prices = PriceUpdates();
  final catalogueDb = CatalogueDb(prices);
  final userDb = UserDb();
  // Check R2 for newer prices in the background — the app never waits on it.
  prices.refresh();
  runApp(HoloTcgApp(prices: prices, catalogueDb: catalogueDb, userDb: userDb));
}

class HoloTcgApp extends StatelessWidget {
  final PriceUpdates prices;
  final CatalogueDb catalogueDb;
  final UserDb userDb;

  const HoloTcgApp({
    super.key,
    required this.prices,
    required this.catalogueDb,
    required this.userDb,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<CatalogueDb>.value(value: catalogueDb),
        ChangeNotifierProvider<PriceUpdates>.value(value: prices),
        ChangeNotifierProvider(create: (_) => PreferencesProvider()),
        ChangeNotifierProvider(create: (_) => CatalogueProvider(catalogueDb)),
        ChangeNotifierProvider(create: (_) => CollectionProvider(userDb)),
      ],
      child: Consumer<PreferencesProvider>(
        builder: (ctx, prefs, child) => MaterialApp(
          title: 'Oshi Collect',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: prefs.themeMode,
          home: const _Shell(),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}

class _Shell extends StatefulWidget {
  const _Shell();

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int _tab = 0;

  // One Navigator per tab so each tab maintains its own navigation stack.
  // IndexedStack keeps all three alive; switching tabs shows/hides them without
  // destroying state or triggering re-loads.
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  Widget _buildTabNavigator(int index) {
    const roots = [CataloguePage(), PortfolioSetsPage(), InventorySetsPage()];
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (_) => MaterialPageRoute(
        builder: (_) => roots[index],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Nav bars are dark in both themes (#544D85 light / #1A1626 dark), so the
    // status bar icons (time, battery, signal) need to stay white at all times.
    // Because sub-pages push within their tab's Navigator (inside this
    // AnnotatedRegion), the overlay style is inherited by all routes.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: PopScope(
        // Route back-button presses into the current tab's navigator stack;
        // at the tab root do nothing (user exits via the home gesture instead).
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          final nav = _navigatorKeys[_tab].currentState;
          if (nav != null && nav.canPop()) nav.pop();
        },
        child: AppBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: IndexedStack(
              index: _tab,
              children: [
                _buildTabNavigator(0),
                _buildTabNavigator(1),
                _buildTabNavigator(2),
              ],
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _tab,
              onTap: (i) {
                // Always pop the target tab's stack to its root, then switch
                // to it. This ensures tapping any tab — whether active or not —
                // always lands on that tab's root page.
                _navigatorKeys[i].currentState?.popUntil((r) => r.isFirst);
                if (i != _tab) setState(() => _tab = i);
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.grid_view),
                  label: 'Catalogue',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.collections_bookmark),
                  label: 'Portfolio',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.inventory_2),
                  label: 'Inventory',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
