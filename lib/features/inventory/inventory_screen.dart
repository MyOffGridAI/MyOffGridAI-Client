import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
/// Supports adding, editing, and deleting items via popup menu,
/// bottom sheet editing, and swipe-to-delete.
class InventoryScreen extends ConsumerStatefulWidget {
  /// Creates an [InventoryScreen].
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

/// State for [InventoryScreen] managing category filtering and inventory CRUD operations.
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
                onEdit: () => _showEditSheet(item),
                onDelete: () => _deleteItem(item),
              );
            },
          );
        },
      ),
    );
  }

  /// Shows the add item dialog for creating a new inventory item.
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

  /// Opens the edit bottom sheet for the given [item].
  Future<void> _showEditSheet(InventoryItemModel item) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditInventoryItemSheet(item: item),
    );
    if (result == true) {
      ref.invalidate(inventoryProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item updated')),
        );
      }
    }
  }

  /// Confirms and deletes the given [item].
  Future<void> _deleteItem(InventoryItemModel item) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Item',
      message:
          "Are you sure you want to delete '${item.name}'? This cannot be undone.",
      confirmText: 'Delete',
      isDestructive: true,
    );
    if (confirmed != true) return;

    try {
      final service = ref.read(inventoryServiceProvider);
      await service.deleteItem(item.id);
      ref.invalidate(inventoryProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item deleted')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }
}

// ── Inventory Tile ────────────────────────────────────────────────────────

/// Renders a single inventory item row with category icon, stock warning, and action menu.
class _InventoryTile extends StatelessWidget {
  final InventoryItemModel item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _InventoryTile({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: item.isLowStock ? Colors.orange : null,
        child: Icon(_categoryIcon(item.category)),
      ),
      title: Text(item.name),
      subtitle: Text(
        '${item.quantity}${item.unit != null ? ' ${item.unit}' : ''} | ${item.category}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.isLowStock)
            const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  onEdit();
                case 'delete':
                  onDelete();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 16),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 16),
                    SizedBox(width: 8),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      onTap: onEdit,
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

// ── Edit Bottom Sheet ─────────────────────────────────────────────────────

/// Bottom sheet for editing an existing inventory item.
///
/// Pre-populates all fields from the current [InventoryItemModel].
/// Validates inputs and calls [InventoryService.updateItem] on save.
/// Returns `true` via [Navigator.pop] on successful save.
class _EditInventoryItemSheet extends ConsumerStatefulWidget {
  /// The inventory item to edit.
  final InventoryItemModel item;

  /// Creates an [_EditInventoryItemSheet] for the given [item].
  const _EditInventoryItemSheet({required this.item});

  @override
  ConsumerState<_EditInventoryItemSheet> createState() =>
      _EditInventoryItemSheetState();
}

/// State for [_EditInventoryItemSheet] managing form fields, dirty tracking, and save submission.
class _EditInventoryItemSheetState
    extends ConsumerState<_EditInventoryItemSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _unitCtrl;
  late final TextEditingController _notesCtrl;
  late String _category;
  bool _isDirty = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item.name);
    _qtyCtrl = TextEditingController(text: widget.item.quantity.toString());
    _unitCtrl = TextEditingController(text: widget.item.unit ?? '');
    _notesCtrl = TextEditingController(text: widget.item.notes ?? '');
    _category = widget.item.category;

    _nameCtrl.addListener(_markDirty);
    _qtyCtrl.addListener(_markDirty);
    _unitCtrl.addListener(_markDirty);
    _notesCtrl.addListener(_markDirty);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _unitCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  /// Validates and saves the updated inventory item.
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final service = ref.read(inventoryServiceProvider);
      await service.updateItem(widget.item.id, {
        'name': _nameCtrl.text.trim(),
        'category': _category,
        'quantity': double.tryParse(_qtyCtrl.text) ?? 0,
        if (_unitCtrl.text.trim().isNotEmpty) 'unit': _unitCtrl.text.trim(),
        if (_notesCtrl.text.trim().isNotEmpty) 'notes': _notesCtrl.text.trim(),
      });
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                'Edit Item',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              // Name
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                maxLength: 255,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),

              // Category
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: InventoryCategory.all
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _category = v ?? _category;
                    _isDirty = true;
                  });
                },
              ),
              const SizedBox(height: 12),

              // Quantity
              TextFormField(
                controller: _qtyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Quantity is required';
                  final parsed = double.tryParse(v);
                  if (parsed == null || parsed < 0) {
                    return 'Must be a number >= 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Unit
              TextFormField(
                controller: _unitCtrl,
                decoration: const InputDecoration(
                  labelText: 'Unit (optional)',
                  border: OutlineInputBorder(),
                  hintText: 'e.g. kg, liters, units',
                ),
              ),
              const SizedBox(height: 12),

              // Notes
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _isSaving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: (_isDirty && !_isSaving) ? _save : null,
                    child: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
