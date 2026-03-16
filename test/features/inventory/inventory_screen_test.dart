import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/models/inventory_item_model.dart';
import 'package:myoffgridai_client/core/services/inventory_service.dart';
import 'package:myoffgridai_client/features/inventory/inventory_screen.dart';

class MockInventoryService extends Mock implements InventoryService {}

void main() {
  late MockInventoryService mockService;

  final testItem = InventoryItemModel.fromJson(const {
    'id': '1',
    'name': 'Rice',
    'category': 'FOOD',
    'quantity': 25.0,
    'unit': 'kg',
    'notes': 'Basmati rice',
  });

  final testItem2 = InventoryItemModel.fromJson(const {
    'id': '2',
    'name': 'Diesel',
    'category': 'FUEL',
    'quantity': 50.0,
    'unit': 'L',
  });

  setUp(() {
    mockService = MockInventoryService();
  });

  Widget buildScreen({List<InventoryItemModel> items = const []}) {
    return ProviderScope(
      overrides: [
        inventoryProvider.overrideWith((ref) => items),
        inventoryServiceProvider.overrideWithValue(mockService),
      ],
      child: const MaterialApp(home: InventoryScreen()),
    );
  }

  group('InventoryScreen', () {
    testWidgets('shows empty state when no items', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('No inventory items'), findsOneWidget);
    });

    testWidgets('displays item list', (tester) async {
      await tester.pumpWidget(buildScreen(items: [testItem, testItem2]));
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
      final lowStockItem = InventoryItemModel.fromJson(const {
        'id': '1',
        'name': 'Water',
        'category': 'WATER',
        'quantity': 2.0,
        'lowStockThreshold': 5.0,
      });

      await tester.pumpWidget(buildScreen(items: [lowStockItem]));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.warning_amber), findsOneWidget);
    });

    testWidgets('shows app bar title', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Inventory'), findsOneWidget);
    });
  });

  group('PopupMenu', () {
    testWidgets('shows Edit and Delete options on more_vert tap',
        (tester) async {
      await tester.pumpWidget(buildScreen(items: [testItem]));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });
  });

  group('Edit sheet', () {
    testWidgets('opens on Edit menu tap', (tester) async {
      await tester.pumpWidget(buildScreen(items: [testItem]));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Item'), findsOneWidget);
    });

    testWidgets('opens on tile tap', (tester) async {
      await tester.pumpWidget(buildScreen(items: [testItem]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rice'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Item'), findsOneWidget);
    });

    testWidgets('pre-populates all fields from item', (tester) async {
      await tester.pumpWidget(buildScreen(items: [testItem]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rice'));
      await tester.pumpAndSettle();

      // Check that EditableText widgets contain pre-populated values
      final editableTexts = tester
          .widgetList<EditableText>(find.byType(EditableText))
          .map((e) => e.controller.text)
          .toList();

      expect(editableTexts, contains('Rice'));
      expect(editableTexts, contains('25.0'));
      expect(editableTexts, contains('kg'));
      expect(editableTexts, contains('Basmati rice'));
    });

    testWidgets('Save button disabled when form not dirty', (tester) async {
      await tester.pumpWidget(buildScreen(items: [testItem]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rice'));
      await tester.pumpAndSettle();

      final saveButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Save'),
      );
      expect(saveButton.onPressed, isNull);
    });

    testWidgets('Save button enabled when form dirty and valid',
        (tester) async {
      await tester.pumpWidget(buildScreen(items: [testItem]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rice'));
      await tester.pumpAndSettle();

      // Modify the name field (first TextFormField in the sheet)
      final nameField = find.byType(TextFormField).first;
      await tester.enterText(nameField, 'Brown Rice');
      await tester.pumpAndSettle();

      final saveButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Save'),
      );
      expect(saveButton.onPressed, isNotNull);
    });

    testWidgets('calls updateItem and shows success SnackBar on save',
        (tester) async {
      when(() => mockService.updateItem(any(), any())).thenAnswer(
        (_) async => InventoryItemModel.fromJson(const {
          'id': '1',
          'name': 'Brown Rice',
          'category': 'FOOD',
          'quantity': 25.0,
          'unit': 'kg',
        }),
      );

      await tester.pumpWidget(buildScreen(items: [testItem]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rice'));
      await tester.pumpAndSettle();

      // Modify name to mark dirty
      await tester.enterText(find.byType(TextFormField).first, 'Brown Rice');
      await tester.pumpAndSettle();

      // Tap save
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      verify(() => mockService.updateItem('1', any())).called(1);
      expect(find.text('Item updated'), findsOneWidget);
    });

    testWidgets('shows error SnackBar on edit failure', (tester) async {
      when(() => mockService.updateItem(any(), any())).thenThrow(
        const ApiException(statusCode: 500, message: 'Server error'),
      );

      await tester.pumpWidget(buildScreen(items: [testItem]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rice'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Brown Rice');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('Server error'), findsOneWidget);
    });
  });

  group('Delete', () {
    testWidgets('shows ConfirmationDialog with item name', (tester) async {
      await tester.pumpWidget(buildScreen(items: [testItem]));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Item'), findsOneWidget);
      expect(find.textContaining("'Rice'"), findsOneWidget);
    });

    testWidgets('calls deleteItem and shows SnackBar on confirm',
        (tester) async {
      when(() => mockService.deleteItem(any())).thenAnswer((_) async {});

      await tester.pumpWidget(buildScreen(items: [testItem]));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Tap the confirm button in the ConfirmationDialog
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();

      verify(() => mockService.deleteItem('1')).called(1);
      expect(find.text('Item deleted'), findsOneWidget);
    });

    testWidgets('does not call service on cancel', (tester) async {
      await tester.pumpWidget(buildScreen(items: [testItem]));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      verifyNever(() => mockService.deleteItem(any()));
    });

    testWidgets('shows error SnackBar on delete failure', (tester) async {
      when(() => mockService.deleteItem(any())).thenThrow(
        const ApiException(statusCode: 403, message: 'Forbidden'),
      );

      await tester.pumpWidget(buildScreen(items: [testItem]));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Forbidden'), findsOneWidget);
    });
  });
}
