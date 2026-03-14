import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/models/inventory_item_model.dart';
import 'package:myoffgridai_client/core/services/inventory_service.dart';
import 'package:myoffgridai_client/shared/widgets/confirmation_dialog.dart';
import 'package:myoffgridai_client/shared/widgets/empty_state_view.dart';
import 'package:myoffgridai_client/shared/widgets/error_view.dart';
import 'package:myoffgridai_client/shared/widgets/loading_indicator.dart';

/// Displays the inventory with category filters and item management.
///
/// Shows inventory items grouped by category with low stock warnings.
/// Supports adding, editing, and deleting items.
class InventoryScreen extends ConsumerStatefulWidget {
  /// Creates an [InventoryScreen].
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(inventoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() =>
                  _selectedCategory = value == 'ALL' ? null : value);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'ALL', child: Text('All')),
              ...InventoryCategory.all.map(
                (c) => PopupMenuItem(value: c, child: Text(c)),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        child: const Icon(Icons.add),
      ),
      body: itemsAsync.when(
        loading: () => const LoadingIndicator(),
        error: (error, _) => ErrorView(
          title: 'Failed to load inventory',
          message: error is ApiException
              ? error.message
              : 'An unexpected error occurred.',
          onRetry: () => ref.invalidate(inventoryProvider),
        ),
        data: (items) {
          final filtered = _selectedCategory != null
              ? items.where((i) => i.category == _selectedCategory).toList()
              : items;

          if (filtered.isEmpty) {
            return const EmptyStateView(
              icon: Icons.inventory_2_outlined,
              title: 'No inventory items',
              subtitle: 'Tap + to add your first item',
            );
          }
          return ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final item = filtered[index];
              return _InventoryTile(
                item: item,
                onTap: () => _showEditDialog(item),
                onDelete: () => _deleteItem(item.id),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showAddItemDialog() async {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final unitCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String category = InventoryCategory.other;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: InventoryCategory.all
                      .map((c) =>
                          DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => category = v ?? category),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: qtyCtrl,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: unitCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Unit (optional)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Notes (optional)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (result != true || nameCtrl.text.isEmpty) {
      nameCtrl.dispose();
      qtyCtrl.dispose();
      unitCtrl.dispose();
      notesCtrl.dispose();
      return;
    }

    try {
      final service = ref.read(inventoryServiceProvider);
      await service.createItem(
        name: nameCtrl.text,
        category: category,
        quantity: double.tryParse(qtyCtrl.text) ?? 0,
        unit: unitCtrl.text.isNotEmpty ? unitCtrl.text : null,
        notes: notesCtrl.text.isNotEmpty ? notesCtrl.text : null,
      );
      ref.invalidate(inventoryProvider);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }

    nameCtrl.dispose();
    qtyCtrl.dispose();
    unitCtrl.dispose();
    notesCtrl.dispose();
  }

  Future<void> _showEditDialog(InventoryItemModel item) async {
    final qtyCtrl =
        TextEditingController(text: item.quantity.toString());
    final notesCtrl = TextEditingController(text: item.notes ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qtyCtrl,
              decoration: const InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != true) {
      qtyCtrl.dispose();
      notesCtrl.dispose();
      return;
    }

    try {
      final service = ref.read(inventoryServiceProvider);
      await service.updateItem(
        item.id,
        quantity: double.tryParse(qtyCtrl.text),
        notes: notesCtrl.text.isNotEmpty ? notesCtrl.text : null,
      );
      ref.invalidate(inventoryProvider);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }

    qtyCtrl.dispose();
    notesCtrl.dispose();
  }

  Future<void> _deleteItem(String itemId) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Item',
      message: 'This item will be permanently deleted.',
      isDestructive: true,
    );
    if (confirmed != true) return;

    try {
      final service = ref.read(inventoryServiceProvider);
      await service.deleteItem(itemId);
      ref.invalidate(inventoryProvider);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }
}

class _InventoryTile extends StatelessWidget {
  final InventoryItemModel item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _InventoryTile({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: item.isLowStock ? Colors.orange : null,
          child: Icon(_categoryIcon(item.category)),
        ),
        title: Text(item.name),
        subtitle: Text(
          '${item.quantity}${item.unit != null ? ' ${item.unit}' : ''} | ${item.category}',
        ),
        trailing: item.isLowStock
            ? const Icon(Icons.warning_amber, color: Colors.orange)
            : null,
        onTap: onTap,
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'FOOD':
        return Icons.restaurant;
      case 'WATER':
        return Icons.water_drop;
      case 'FUEL':
        return Icons.local_gas_station;
      case 'TOOLS':
        return Icons.build;
      case 'MEDICINE':
        return Icons.medical_services;
      case 'SPARE_PARTS':
        return Icons.settings;
      default:
        return Icons.inventory_2;
    }
  }
}
