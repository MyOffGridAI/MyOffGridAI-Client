import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/models/memory_model.dart';
import 'package:myoffgridai_client/core/services/memory_service.dart';
import 'package:myoffgridai_client/shared/utils/date_formatter.dart';
import 'package:myoffgridai_client/shared/widgets/confirmation_dialog.dart';
import 'package:myoffgridai_client/shared/widgets/empty_state_view.dart';
import 'package:myoffgridai_client/shared/widgets/error_view.dart';
import 'package:myoffgridai_client/shared/widgets/loading_indicator.dart';
import 'package:myoffgridai_client/core/auth/auth_state.dart';

/// Displays the AI's memory entries with search and filter capabilities.
///
/// Supports filtering by importance level and semantic search across
/// all memories. Each memory can be tapped to view details and edit tags.
/// Long-press a memory to enter multi-select mode for bulk actions.
class MemoryScreen extends ConsumerStatefulWidget {
  /// Creates a [MemoryScreen].
  const MemoryScreen({super.key});

  @override
  ConsumerState<MemoryScreen> createState() => _MemoryScreenState();
}

/// State for [MemoryScreen] managing search, importance filtering,
/// multi-select mode, and memory operations.
class _MemoryScreenState extends ConsumerState<MemoryScreen> {
  final _searchController = TextEditingController();
  String? _selectedImportance;
  List<MemorySearchResultModel>? _searchResults;
  bool _isSearching = false;

  bool _selectionMode = false;
  Set<String> _selectedIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final memoriesAsync = ref.watch(memoriesProvider);

    return Scaffold(
      appBar: _selectionMode ? _buildSelectionAppBar() : _buildNormalAppBar(),
      body: Column(
        children: [
          if (!_selectionMode)
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search memories...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchResults = null);
                          },
                        )
                      : null,
                ),
                onSubmitted: _onSearch,
              ),
            ),
          Expanded(
            child: _searchResults != null
                ? _buildSearchResults()
                : _buildMemoryList(memoriesAsync),
          ),
        ],
      ),
    );
  }

  AppBar _buildNormalAppBar() {
    return AppBar(
      title: const Text('Memory'),
      actions: [
        IconButton(
          icon: const Icon(Icons.checklist),
          tooltip: 'Select',
          onPressed: () => setState(() => _selectionMode = true),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.filter_list),
          onSelected: (value) {
            setState(() {
              _selectedImportance = value == 'ALL' ? null : value;
              _searchResults = null;
            });
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'ALL', child: Text('All')),
            const PopupMenuItem(value: 'CRITICAL', child: Text('Critical')),
            const PopupMenuItem(value: 'HIGH', child: Text('High')),
            const PopupMenuItem(value: 'MEDIUM', child: Text('Medium')),
            const PopupMenuItem(value: 'LOW', child: Text('Low')),
          ],
        ),
      ],
    );
  }

  AppBar _buildSelectionAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _exitSelectionMode,
      ),
      title: Text('${_selectedIds.length} selected'),
      actions: [
        IconButton(
          icon: const Icon(Icons.people_outline),
          tooltip: 'Share selected',
          onPressed:
              _selectedIds.isEmpty ? null : () => _toggleShareSelected(true),
        ),
        IconButton(
          icon: const Icon(Icons.lock_outline),
          tooltip: 'Make selected private',
          onPressed:
              _selectedIds.isEmpty ? null : () => _toggleShareSelected(false),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Delete selected',
          onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
        ),
      ],
    );
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedIds = {};
    });
  }

  void _enterSelectionMode(String memoryId) {
    setState(() {
      _selectionMode = true;
      _selectedIds = {memoryId};
    });
  }

  void _toggleSelection(String memoryId) {
    setState(() {
      if (_selectedIds.contains(memoryId)) {
        _selectedIds.remove(memoryId);
        if (_selectedIds.isEmpty) {
          _selectionMode = false;
        }
      } else {
        _selectedIds.add(memoryId);
      }
    });
  }

  String? get _currentUserId {
    return ref.read(authStateProvider).valueOrNull?.id;
  }

  /// Returns the list of owned memories from [filtered], used for Select All.
  List<MemoryModel> _ownedMemories(List<MemoryModel> filtered) {
    final currentUid = _currentUserId;
    return filtered
        .where((m) => m.userId == null || m.userId == currentUid)
        .toList();
  }

  Widget _buildSelectAllRow(List<MemoryModel> filtered) {
    final owned = _ownedMemories(filtered);
    if (owned.isEmpty) return const SizedBox.shrink();

    final ownedIds = owned.map((m) => m.id).toSet();
    final selectedOwned = _selectedIds.intersection(ownedIds);
    final bool allSelected = selectedOwned.length == ownedIds.length;
    final bool? triState = selectedOwned.isEmpty
        ? false
        : allSelected
            ? true
            : null;

    return CheckboxListTile(
      tristate: true,
      value: triState,
      title: Text('Select All (${owned.length})'),
      onChanged: (_) {
        setState(() {
          if (allSelected) {
            _selectedIds.removeAll(ownedIds);
            if (_selectedIds.isEmpty) {
              _selectionMode = false;
            }
          } else {
            _selectedIds.addAll(ownedIds);
          }
        });
      },
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Widget _buildMemoryList(AsyncValue<List<MemoryModel>> memoriesAsync) {
    return memoriesAsync.when(
      loading: () => const LoadingIndicator(),
      error: (error, _) => ErrorView(
        title: 'Failed to load memories',
        message: error is ApiException
            ? error.message
            : 'An unexpected error occurred.',
        onRetry: () => ref.invalidate(memoriesProvider),
      ),
      data: (memories) {
        final filtered = _selectedImportance != null
            ? memories
                .where((m) => m.importance == _selectedImportance)
                .toList()
            : memories;

        if (filtered.isEmpty) {
          return const EmptyStateView(
            icon: Icons.psychology_outlined,
            title: 'No memories yet',
            subtitle: 'Memories are created from your conversations',
          );
        }
        final currentUid = _currentUserId;
        return ListView.builder(
          itemCount: filtered.length + (_selectionMode ? 1 : 0),
          itemBuilder: (context, index) {
            if (_selectionMode && index == 0) {
              return _buildSelectAllRow(filtered);
            }
            final memoryIndex = _selectionMode ? index - 1 : index;
            final memory = filtered[memoryIndex];
            final isOwner =
                memory.userId == null || memory.userId == currentUid;
            return _MemoryTile(
              memory: memory,
              isOwner: isOwner,
              selectionMode: _selectionMode,
              isSelected: _selectedIds.contains(memory.id),
              onTap: _selectionMode
                  ? (isOwner ? () => _toggleSelection(memory.id) : null)
                  : () => _showMemoryDetail(memory, isOwner),
              onLongPress:
                  isOwner ? () => _enterSelectionMode(memory.id) : null,
              onDelete: () => _deleteMemory(memory.id),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) return const LoadingIndicator();
    if (_searchResults!.isEmpty) {
      return const EmptyStateView(
        icon: Icons.search_off,
        title: 'No results found',
      );
    }
    final currentUid = _currentUserId;
    return ListView.builder(
      itemCount: _searchResults!.length,
      itemBuilder: (context, index) {
        final result = _searchResults![index];
        final isOwner = result.memory.userId == null ||
            result.memory.userId == currentUid;
        return _MemoryTile(
          memory: result.memory,
          score: result.similarityScore,
          isOwner: isOwner,
          selectionMode: false,
          isSelected: false,
          onTap: () => _showMemoryDetail(result.memory, isOwner),
          onDelete: () => _deleteMemory(result.memory.id),
        );
      },
    );
  }

  Future<void> _onSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = null);
      return;
    }
    _exitSelectionMode();
    setState(() => _isSearching = true);
    try {
      final service = ref.read(memoryServiceProvider);
      final results = await service.search(query.trim());
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } on ApiException catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  void _showMemoryDetail(MemoryModel memory, bool isOwner) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _MemoryDetailSheet(
        memory: memory,
        isOwner: isOwner,
        onToggleShared: isOwner ? () => _toggleShared(memory) : null,
      ),
    );
  }

  Future<void> _toggleShared(MemoryModel memory) async {
    try {
      final service = ref.read(memoryServiceProvider);
      await service.updateShared(memory.id, !memory.shared);
      ref.invalidate(memoriesProvider);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              memory.shared ? 'Memory set to private' : 'Memory shared',
            ),
          ),
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

  Future<void> _deleteMemory(String id) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Memory',
      message: 'This memory will be permanently deleted.',
      isDestructive: true,
    );
    if (confirmed != true) return;

    try {
      final service = ref.read(memoryServiceProvider);
      await service.deleteMemory(id);
      ref.invalidate(memoriesProvider);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  /// Deletes all selected memories in a single batch call.
  Future<void> _deleteSelected() async {
    final count = _selectedIds.length;
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete $count Memories',
      message: '$count memories will be permanently deleted.',
      isDestructive: true,
    );
    if (confirmed != true) return;

    try {
      final service = ref.read(memoryServiceProvider);
      await service.deleteMemoriesBatch(_selectedIds.toList());
      ref.invalidate(memoriesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$count memories deleted')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
    _exitSelectionMode();
  }

  /// Updates the shared visibility of all selected memories.
  Future<void> _toggleShareSelected(bool shared) async {
    try {
      final service = ref.read(memoryServiceProvider);
      await service.updateSharedBatch(_selectedIds.toList(), shared);
      ref.invalidate(memoriesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              shared
                  ? '${_selectedIds.length} memories shared'
                  : '${_selectedIds.length} memories set to private',
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
    _exitSelectionMode();
  }
}

/// Bottom sheet displaying memory details with a shared/private toggle for owners.
class _MemoryDetailSheet extends StatelessWidget {
  final MemoryModel memory;
  final bool isOwner;
  final VoidCallback? onToggleShared;

  const _MemoryDetailSheet({
    required this.memory,
    required this.isOwner,
    this.onToggleShared,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _importanceBadge(context, memory.importance),
                const SizedBox(width: 8),
                Icon(
                  memory.shared ? Icons.people_outline : Icons.lock_outline,
                  size: 16,
                  color: memory.shared
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(width: 4),
                Text(
                  memory.shared ? 'Shared' : 'Private',
                  style: TextStyle(
                    fontSize: 11,
                    color: memory.shared
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SelectableText(
              memory.content,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            if (memory.tagList.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: memory.tagList
                    .map((tag) => Chip(label: Text(tag)))
                    .toList(),
              ),
              const SizedBox(height: 12),
            ],
            if (memory.createdAt != null)
              Text(
                'Created: ${DateFormatter.formatFull(DateTime.parse(memory.createdAt!))}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            Text(
              'Accessed ${memory.accessCount} times',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (isOwner && onToggleShared != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onToggleShared,
                  icon: Icon(
                    memory.shared ? Icons.lock_outline : Icons.people_outline,
                  ),
                  label: Text(
                    memory.shared ? 'Make Private' : 'Share with Household',
                  ),
                ),
              ),
            ],
            if (!isOwner) ...[
              const SizedBox(height: 16),
              Text(
                'Shared by another user (read-only)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _importanceBadge(BuildContext context, String importance) {
    final colors = {
      'CRITICAL': Colors.red,
      'HIGH': Colors.orange,
      'MEDIUM': Colors.blue,
      'LOW': Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (colors[importance] ?? Colors.grey).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors[importance] ?? Colors.grey),
      ),
      child: Text(
        importance,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: colors[importance] ?? Colors.grey,
        ),
      ),
    );
  }
}

/// Renders a single memory entry as a dismissible list tile within [MemoryScreen].
///
/// In selection mode, shows a checkbox instead of the shared/lock icon and
/// disables swipe-to-delete. Non-owner memories show a disabled checkbox.
class _MemoryTile extends StatelessWidget {
  final MemoryModel memory;
  final double? score;
  final bool isOwner;
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback onDelete;

  const _MemoryTile({
    required this.memory,
    this.score,
    this.isOwner = true,
    this.selectionMode = false,
    this.isSelected = false,
    required this.onTap,
    this.onLongPress,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final tile = ListTile(
      leading: selectionMode
          ? Checkbox(
              value: isSelected,
              onChanged: isOwner ? (_) => onTap?.call() : null,
            )
          : Icon(
              memory.shared ? Icons.people_outline : Icons.lock_outline,
              size: 20,
              color: memory.shared
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
            ),
      title: Text(
        memory.content,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          Text(memory.importance, style: const TextStyle(fontSize: 11)),
          if (score != null) ...[
            const SizedBox(width: 8),
            Text(
              '${(score! * 100).toStringAsFixed(0)}% match',
              style: const TextStyle(fontSize: 11),
            ),
          ],
          if (!isOwner) ...[
            const SizedBox(width: 8),
            Text(
              'Shared',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
      trailing: memory.createdAt != null
          ? Text(
              DateFormatter.formatRelative(DateTime.parse(memory.createdAt!)),
              style: Theme.of(context).textTheme.bodySmall,
            )
          : null,
      onTap: onTap,
      onLongPress: selectionMode ? null : onLongPress,
    );

    if (selectionMode) {
      return tile;
    }

    return Dismissible(
      key: Key(memory.id),
      direction: isOwner ? DismissDirection.endToStart : DismissDirection.none,
      background: Container(
        color: Theme.of(context).colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: tile,
    );
  }
}
