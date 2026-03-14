import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/core/models/inventory_item_model.dart';
import 'package:myoffgridai_client/core/services/inventory_service.dart';
import 'package:myoffgridai_client/features/inventory/inventory_screen.dart';

void main() {
  group('InventoryScreen', () {
    Widget buildScreen({List<InventoryItemModel> items = const []}) {
      return ProviderScope(
        overrides: [
          inventoryProvider.overrideWith((ref) => items),
        ],
        child: const MaterialApp(home: InventoryScreen()),
      );
    }

    testWidgets('shows empty state when no items', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('No inventory items'), findsOneWidget);
    });

    testWidgets('displays item list', (tester) async {
      final items = [
        InventoryItemModel.fromJson({
          'id': '1',
          'name': 'Rice',
          'category': 'FOOD',
          'quantity': 25.0,
          'unit': 'kg',
        }),
        InventoryItemModel.fromJson({
          'id': '2',
          'name': 'Diesel',
          'category': 'FUEL',
          'quantity': 50.0,
          'unit': 'L',
        }),
      ];

      await tester.pumpWidget(buildScreen(items: items));
      await tester.pumpAndSettle();

      expect(find.text('Rice'), findsOneWidget);
      expect(find.text('Diesel'), findsOneWidget);
    });

    testWidgets('shows add FAB', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('shows low stock warning', (tester) async {
      final items = [
        InventoryItemModel.fromJson({
          'id': '1',
          'name': 'Water',
          'category': 'WATER',
          'quantity': 2.0,
          'lowStockThreshold': 5.0,
        }),
      ];

      await tester.pumpWidget(buildScreen(items: items));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.warning_amber), findsOneWidget);
    });

    testWidgets('shows app bar title', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Inventory'), findsOneWidget);
    });
  });
}
