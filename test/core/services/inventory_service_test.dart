import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/api/myoffgridai_api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/core/services/inventory_service.dart';

class MockApiClient extends Mock implements MyOffGridAIApiClient {}

void main() {
  late MockApiClient mockClient;
  late InventoryService service;

  setUp(() {
    mockClient = MockApiClient();
    service = InventoryService(client: mockClient);
  });

  group('listItems', () {
    test('returns parsed list from API response', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.inventoryBasePath,
          )).thenAnswer((_) async => {
            'data': [
              {
                'id': '1',
                'name': 'Rice',
                'category': 'FOOD',
                'quantity': 25.0,
                'unit': 'kg',
              },
            ],
          });

      final result = await service.listItems();

      expect(result, hasLength(1));
      expect(result[0].name, 'Rice');
      expect(result[0].category, 'FOOD');
    });

    test('passes category filter', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.inventoryBasePath,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {'data': <dynamic>[]});

      await service.listItems(category: 'FUEL');

      final captured = verify(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.inventoryBasePath,
            queryParams: captureAny(named: 'queryParams'),
          )).captured;

      final params = captured.first as Map<String, dynamic>;
      expect(params['category'], 'FUEL');
    });

    test('passes null queryParams when no category', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.inventoryBasePath,
          )).thenAnswer((_) async => {'data': <dynamic>[]});

      await service.listItems();

      verify(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.inventoryBasePath,
          )).called(1);
    });

    test('returns empty list when data is null', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.inventoryBasePath,
          )).thenAnswer((_) async => {'data': null});

      final result = await service.listItems();

      expect(result, isEmpty);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.inventoryBasePath,
          )).thenThrow(const ApiException(
        statusCode: 500,
        message: 'Internal server error',
      ));

      expect(
        () => service.listItems(),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('createItem', () {
    test('sends correct data and returns model', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            AppConstants.inventoryBasePath,
            data: any(named: 'data'),
          )).thenAnswer((_) async => {
            'data': {
              'id': 'new-1',
              'name': 'Diesel',
              'category': 'FUEL',
              'quantity': 100.0,
              'unit': 'L',
            },
          });

      final result = await service.createItem(
        name: 'Diesel',
        category: 'FUEL',
        quantity: 100.0,
        unit: 'L',
      );

      expect(result.id, 'new-1');
      expect(result.name, 'Diesel');
      verify(() => mockClient.post<Map<String, dynamic>>(
            AppConstants.inventoryBasePath,
            data: any(named: 'data'),
          )).called(1);
    });

    test('includes optional fields when provided', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            AppConstants.inventoryBasePath,
            data: any(named: 'data'),
          )).thenAnswer((_) async => {
            'data': {
              'id': 'new-2',
              'name': 'Rice',
              'category': 'FOOD',
              'quantity': 50.0,
              'unit': 'kg',
              'notes': 'Long grain',
              'lowStockThreshold': 10.0,
            },
          });

      await service.createItem(
        name: 'Rice',
        category: 'FOOD',
        quantity: 50.0,
        unit: 'kg',
        notes: 'Long grain',
        lowStockThreshold: 10.0,
      );

      final captured = verify(() => mockClient.post<Map<String, dynamic>>(
            AppConstants.inventoryBasePath,
            data: captureAny(named: 'data'),
          )).captured;

      final sentData = captured.first as Map<String, dynamic>;
      expect(sentData['name'], 'Rice');
      expect(sentData['category'], 'FOOD');
      expect(sentData['quantity'], 50.0);
      expect(sentData['unit'], 'kg');
      expect(sentData['notes'], 'Long grain');
      expect(sentData['lowStockThreshold'], 10.0);
    });

    test('omits optional fields when not provided', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            AppConstants.inventoryBasePath,
            data: any(named: 'data'),
          )).thenAnswer((_) async => {
            'data': {
              'id': 'new-3',
              'name': 'Water',
              'category': 'WATER',
              'quantity': 200.0,
            },
          });

      await service.createItem(
        name: 'Water',
        category: 'WATER',
        quantity: 200.0,
      );

      final captured = verify(() => mockClient.post<Map<String, dynamic>>(
            AppConstants.inventoryBasePath,
            data: captureAny(named: 'data'),
          )).captured;

      final sentData = captured.first as Map<String, dynamic>;
      expect(sentData['name'], 'Water');
      expect(sentData.containsKey('unit'), isFalse);
      expect(sentData.containsKey('notes'), isFalse);
      expect(sentData.containsKey('lowStockThreshold'), isFalse);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            AppConstants.inventoryBasePath,
            data: any(named: 'data'),
          )).thenThrow(const ApiException(
        statusCode: 400,
        message: 'Validation failed',
      ));

      expect(
        () => service.createItem(
          name: '',
          category: 'FOOD',
          quantity: -1,
        ),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('updateItem', () {
    test('sends PUT with updates and returns updated model', () async {
      when(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.inventoryBasePath}/item-1',
            data: any(named: 'data'),
          )).thenAnswer((_) async => {
            'data': {
              'id': 'item-1',
              'name': 'Updated Rice',
              'category': 'FOOD',
              'quantity': 30.0,
              'unit': 'kg',
            },
          });

      final result = await service.updateItem('item-1', {
        'name': 'Updated Rice',
        'quantity': 30.0,
      });

      expect(result.id, 'item-1');
      expect(result.name, 'Updated Rice');
      expect(result.quantity, 30.0);

      final captured = verify(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.inventoryBasePath}/item-1',
            data: captureAny(named: 'data'),
          )).captured;

      final sentData = captured.first as Map<String, dynamic>;
      expect(sentData['name'], 'Updated Rice');
      expect(sentData['quantity'], 30.0);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.inventoryBasePath}/item-1',
            data: any(named: 'data'),
          )).thenThrow(const ApiException(
        statusCode: 404,
        message: 'Item not found',
      ));

      expect(
        () => service.updateItem('item-1', {'name': 'test'}),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('deleteItem', () {
    test('calls DELETE on correct path', () async {
      when(() => mockClient.delete(
            '${AppConstants.inventoryBasePath}/item-1',
          )).thenAnswer((_) async {});

      await service.deleteItem('item-1');

      verify(() => mockClient.delete(
            '${AppConstants.inventoryBasePath}/item-1',
          )).called(1);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.delete(
            '${AppConstants.inventoryBasePath}/item-1',
          )).thenThrow(const ApiException(
        statusCode: 403,
        message: 'Forbidden',
      ));

      expect(
        () => service.deleteItem('item-1'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ── Provider body tests ───────────────────────────────────────────────
  group('inventoryServiceProvider', () {
    test('creates InventoryService from apiClientProvider', () {
      final mockClient = MockApiClient();
      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(mockClient)],
      );
      addTearDown(container.dispose);
      expect(container.read(inventoryServiceProvider), isA<InventoryService>());
    });
  });

  group('inventoryProvider', () {
    test('returns items from service', () async {
      final mockClient = MockApiClient();
      when(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.inventoryBasePath,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': [
              {'id': 'item-1', 'name': 'Rice', 'category': 'FOOD', 'quantity': 10.0},
            ],
          });
      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(mockClient)],
      );
      addTearDown(container.dispose);
      final items = await container.read(inventoryProvider.future);
      expect(items, hasLength(1));
    });
  });
}
