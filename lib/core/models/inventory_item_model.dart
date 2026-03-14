/// Represents an inventory item.
///
/// Mirrors the server's InventoryItemDto. Category uses enum values:
/// FOOD, WATER, FUEL, TOOLS, MEDICINE, SPARE_PARTS, OTHER.
class InventoryItemModel {
  final String id;
  final String name;
  final String category;
  final double quantity;
  final String? unit;
  final String? notes;
  final double? lowStockThreshold;
  final String? createdAt;
  final String? updatedAt;

  const InventoryItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    this.unit,
    this.notes,
    this.lowStockThreshold,
    this.createdAt,
    this.updatedAt,
  });

  /// Creates an [InventoryItemModel] from a JSON map.
  factory InventoryItemModel.fromJson(Map<String, dynamic> json) {
    return InventoryItemModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'OTHER',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String?,
      notes: json['notes'] as String?,
      lowStockThreshold: (json['lowStockThreshold'] as num?)?.toDouble(),
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  /// Whether the item is below its low stock threshold.
  bool get isLowStock =>
      lowStockThreshold != null && quantity <= lowStockThreshold!;
}

/// Valid inventory categories matching the server enum.
class InventoryCategory {
  InventoryCategory._();

  static const String food = 'FOOD';
  static const String water = 'WATER';
  static const String fuel = 'FUEL';
  static const String tools = 'TOOLS';
  static const String medicine = 'MEDICINE';
  static const String spareParts = 'SPARE_PARTS';
  static const String other = 'OTHER';

  static const List<String> all = [
    food, water, fuel, tools, medicine, spareParts, other,
  ];
}
