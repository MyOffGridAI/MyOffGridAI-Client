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

/// Displays the AI's memory entries with search and filter capabilities.
///
/// Supports filtering by importance level and semantic search across
/// all memories. Each memory can be tapped to view details and edit tags.
class MemoryScreen extends ConsumerStatefulWidget {
  /// Creates a [MemoryScreen].
  const MemoryScreen({super.key});

  @override
  ConsumerState<MemoryScreen> createState() => _MemoryScreenState();
}

/// State for [MemoryScreen] managing search, importance filtering, and memory deletion.
class _MemoryScreenState extends ConsumerState<MemoryScreen> {
  final _searchController = TextEditingController();
  String? _selectedImportance;
  List<MemorySearchResultModel>? _searchResults;
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final memoriesAsync = ref.watch(memoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory'),
        actions: [
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
      ),
      body: Column(
        children: [
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
        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (context, index) => _MemoryTile(
            memory: filtered[index],
            onTap: () => _showMemoryDetail(filtered[index]),
            onDelete: () => _deleteMemory(filtered[index].id),
          ),
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
    return ListView.builder(
      itemCount: _searchResults!.length,
      itemBuilder: (context, index) {
        final result = _searchResults![index];
        return _MemoryTile(
          memory: result.memory,
          score: result.similarityScore,
          onTap: () => _showMemoryDetail(result.memory),
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

  void _showMemoryDetail(MemoryModel memory) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
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
              _importanceBadge(context, memory.importance),
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
            ],
          ),
        ),
      ),
    );
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
class _MemoryTile extends StatelessWidget {
  final MemoryModel memory;
  final double? score;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _MemoryTile({
    required this.memory,
    this.score,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(memory.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        title: Text(
          memory.content,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Text(memory.importance,
                style: const TextStyle(fontSize: 11)),
            if (score != null) ...[
              const SizedBox(width: 8),
              Text(
                '${(score! * 100).toStringAsFixed(0)}% match',
                style: const TextStyle(fontSize: 11),
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
      ),
    );
  }
}
