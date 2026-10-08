// Basic smoke test — confirms the app builds and shows the bottom nav.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:holo_tcg_tracker/db/catalogue_db.dart';
import 'package:holo_tcg_tracker/db/price_updates.dart';
import 'package:holo_tcg_tracker/db/user_db.dart';
import 'package:holo_tcg_tracker/main.dart';

void main() {
  testWidgets('HoloTcgApp shows bottom navigation tabs', (WidgetTester tester) async {
    final prices = PriceUpdates();
    await tester.pumpWidget(HoloTcgApp(
      prices: prices,
      catalogueDb: CatalogueDb(prices),
      userDb: UserDb(),
    ));
    await tester.pump();

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('Catalogue'), findsWidgets);
    expect(find.text('Portfolio'), findsWidgets);
    expect(find.text('Inventory'), findsWidgets);
  });
}
