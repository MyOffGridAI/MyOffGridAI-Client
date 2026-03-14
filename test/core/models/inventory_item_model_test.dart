import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/core/models/inventory_item_model.dart';

void main() {
  group('InventoryItemModel', () {
    test('parses from JSON with all fields', () {
      final json = {
        'id': 'item-1',
        'name': 'Rice',
        'category': 'FOOD',
        'quantity': 25.5,
        'unit': 'kg',
        'notes': 'Long grain',
        'lowStockThreshold': 5.0,
        'createdAt': '2026-03-14T10:00:00Z',
        'updatedAt': '2026-03-14T11:00:00Z',
      };

      final model = InventoryItemModel.fromJson(json);

      expect(model.id, 'item-1');
      expect(model.name, 'Rice');
      expect(model.category, 'FOOD');
      expect(model.quantity, 25.5);
      expect(model.unit, 'kg');
      expect(model.notes, 'Long grain');
      expect(model.lowStockThreshold, 5.0);
    });

    test('handles missing optional fields with defaults', () {
      final json = {'id': 'item-2'};

      final model = InventoryItemModel.fromJson(json);

      expect(model.name, '');
      expect(model.category, 'OTHER');
      expect(model.quantity, 0.0);
      expect(model.unit, isNull);
      expect(model.lowStockThreshold, isNull);
    });

    test('isLowStock when quantity at threshold', () {
      final model = InventoryItemModel.fromJson({
        'id': '1',
        'quantity': 5.0,
        'lowStockThreshold': 5.0,
      });
      expect(model.isLowStock, isTrue);
    });

    test('isLowStock when quantity below threshold', () {
      final model = InventoryItemModel.fromJson({
        'id': '1',
        'quantity': 2.0,
        'lowStockThreshold': 5.0,
      });
      expect(model.isLowStock, isTrue);
    });

    test('not low stock when quantity above threshold', () {
      final model = InventoryItemModel.fromJson({
        'id': '1',
        'quantity': 10.0,
        'lowStockThreshold': 5.0,
      });
      expect(model.isLowStock, isFalse);
    });

    test('not low stock when no threshold set', () {
      final model = InventoryItemModel.fromJson({
        'id': '1',
        'quantity': 1.0,
      });
      expect(model.isLowStock, isFalse);
    });
  });

  group('InventoryCategory', () {
    test('all contains expected categories', () {
      expect(InventoryCategory.all, contains('FOOD'));
      expect(InventoryCategory.all, contains('WATER'));
      expect(InventoryCategory.all, contains('FUEL'));
      expect(InventoryCategory.all, contains('TOOLS'));
      expect(InventoryCategory.all, contains('MEDICINE'));
      expect(InventoryCategory.all, contains('SPARE_PARTS'));
      expect(InventoryCategory.all, contains('OTHER'));
      expect(InventoryCategory.all.length, 7);
    });
  });
}
