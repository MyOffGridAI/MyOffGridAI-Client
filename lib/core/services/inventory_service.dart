import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/myoffgridai_api_client.dart';
import 'package:myoffgridai_client/core/models/inventory_item_model.dart';

/// Service for inventory management operations.
///
/// Wraps [MyOffGridAIApiClient] and returns typed models.
class InventoryService {
  final MyOffGridAIApiClient _client;

  /// Creates an [InventoryService] with the given API [client].
  InventoryService({required MyOffGridAIApiClient client}) : _client = client;

  /// Lists inventory items with optional category filter.
  Future<List<InventoryItemModel>> listItems({String? category}) async {
    final params = <String, dynamic>{};
    if (category != null) params['category'] = category;

    final response = await _client.get<Map<String, dynamic>>(
      AppConstants.inventoryBasePath,
      queryParams: params.isNotEmpty ? params : null,
    );
    final data = response['data'] as List<dynamic>?;
    if (data == null) return [];
    return data
        .map((e) => InventoryItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Creates a new inventory item.
  Future<InventoryItemModel> createItem({
    required String name,
    required String category,
    required double quantity,
    String? unit,
    String? notes,
    double? lowStockThreshold,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      AppConstants.inventoryBasePath,
      data: {
        'name': name,
        'category': category,
        'quantity': quantity,
        if (unit != null) 'unit': unit,
        if (notes != null) 'notes': notes,
        if (lowStockThreshold != null) 'lowStockThreshold': lowStockThreshold,
      },
    );
    final data = response['data'] as Map<String, dynamic>;
    return InventoryItemModel.fromJson(data);
  }

  /// Updates an inventory item.
  Future<InventoryItemModel> updateItem(
    String itemId, {
    double? quantity,
    String? notes,
    double? lowStockThreshold,
  }) async {
    final response = await _client.put<Map<String, dynamic>>(
      '${AppConstants.inventoryBasePath}/$itemId',
      data: {
        if (quantity != null) 'quantity': quantity,
        if (notes != null) 'notes': notes,
        if (lowStockThreshold != null) 'lowStockThreshold': lowStockThreshold,
      },
    );
    final data = response['data'] as Map<String, dynamic>;
    return InventoryItemModel.fromJson(data);
  }

  /// Deletes an inventory item by [itemId].
  Future<void> deleteItem(String itemId) async {
    await _client.delete('${AppConstants.inventoryBasePath}/$itemId');
  }
}

/// Riverpod provider for [InventoryService].
final inventoryServiceProvider = Provider<InventoryService>((ref) {
  final client = ref.watch(apiClientProvider);
  return InventoryService(client: client);
});

/// Provider for the inventory item list.
final inventoryProvider =
    FutureProvider.autoDispose<List<InventoryItemModel>>((ref) async {
  final service = ref.watch(inventoryServiceProvider);
  return service.listItems();
});
