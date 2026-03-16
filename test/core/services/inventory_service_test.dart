import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/api/myoffgridai_api_client.dart';
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

    test('returns empty list when data is null', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.inventoryBasePath,
          )).thenAnswer((_) async => {'data': null});

      final result = await service.listItems();

      expect(result, isEmpty);
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
}
