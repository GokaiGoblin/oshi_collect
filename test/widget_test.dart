// Basic smoke test — confirms the app builds and shows the bottom nav.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:holo_tcg_tracker/main.dart';

void main() {
  testWidgets('HoloTcgApp shows bottom navigation tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const HoloTcgApp());
    await tester.pump();

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('Catalogue'), findsWidgets);
    expect(find.text('Portfolio'), findsWidgets);
    expect(find.text('Inventory'), findsWidgets);
  });
}
