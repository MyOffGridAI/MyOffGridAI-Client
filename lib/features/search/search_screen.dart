import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myoffgridai_client/core/models/conversation_model.dart';
import 'package:myoffgridai_client/core/models/knowledge_document_model.dart';
import 'package:myoffgridai_client/core/models/memory_model.dart';
import 'package:myoffgridai_client/core/services/chat_service.dart';
import 'package:myoffgridai_client/core/services/knowledge_service.dart';
import 'package:myoffgridai_client/core/services/memory_service.dart';

/// Unified search screen with tabbed results across Conversations,
/// Memories, and Knowledge.
///
/// Debounces input by 300ms and fires all 3 searches in parallel.
class SearchScreen extends ConsumerStatefulWidget {
  /// Creates a [SearchScreen].
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late final TabController _tabController;
  Timer? _debounce;

  List<ConversationSummaryModel> _conversations = [];
  List<MemorySearchResultModel> _memories = [];
  List<KnowledgeSearchResultModel> _knowledge = [];

  bool _isSearching = false;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _conversations = [];
        _memories = [];
        _knowledge = [];
        _lastQuery = '';
        _isSearching = false;
      });
      return;
    }

    if (query == _lastQuery) return;
    _lastQuery = query;
    setState(() => _isSearching = true);

    try {
      final chatService = ref.read(chatServiceProvider);
      final memoryService = ref.read(memoryServiceProvider);
      final knowledgeService = ref.read(knowledgeServiceProvider);

      // Fire all 3 searches in parallel
      final results = await Future.wait([
        chatService.searchConversations(query),
        memoryService.search(query),
        knowledgeService.search(query),
      ]);

      if (mounted && query == _lastQuery) {
        setState(() {
          _conversations =
              results[0] as List<ConversationSummaryModel>;
          _memories = results[1] as List<MemorySearchResultModel>;
          _knowledge =
              results[2] as List<KnowledgeSearchResultModel>;
          _isSearching = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search conversations, memories, knowledge...',
            border: InputBorder.none,
          ),
          onChanged: _onSearchChanged,
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Conversations'),
                  if (_conversations.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    _Badge(count: _conversations.length),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Memories'),
                  if (_memories.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    _Badge(count: _memories.length),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Knowledge'),
                  if (_knowledge.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    _Badge(count: _knowledge.length),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isSearching
          ? const Center(child: CircularProgressIndicator())
          : _lastQuery.isEmpty
              ? const Center(
                  child: Text('Start typing to search'),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildConversationsTab(),
                    _buildMemoriesTab(),
                    _buildKnowledgeTab(),
                  ],
                ),
    );
  }

  Widget _buildConversationsTab() {
    if (_conversations.isEmpty) {
      return const Center(child: Text('No matching conversations'));
    }
    return ListView.builder(
      itemCount: _conversations.length,
      itemBuilder: (context, index) {
        final conv = _conversations[index];
        return ListTile(
          leading: const Icon(Icons.chat_bubble_outline),
          title: Text(conv.title ?? 'Untitled'),
          subtitle: conv.lastMessagePreview != null
              ? Text(
                  conv.lastMessagePreview!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          trailing: conv.updatedAt != null
              ? Text(
                  conv.updatedAt!.substring(0, 10),
                  style: Theme.of(context).textTheme.bodySmall,
                )
              : null,
          onTap: () => context.go('/chat/${conv.id}'),
        );
      },
    );
  }

  Widget _buildMemoriesTab() {
    if (_memories.isEmpty) {
      return const Center(child: Text('No matching memories'));
    }
    return ListView.builder(
      itemCount: _memories.length,
      itemBuilder: (context, index) {
        final result = _memories[index];
        return ListTile(
          leading: const Icon(Icons.psychology_outlined),
          title: Text(
            result.memory.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            'Importance: ${result.memory.importance} '
            '- Score: ${result.similarityScore.toStringAsFixed(2)}',
          ),
          trailing: result.memory.tags != null
              ? Chip(
                  label: Text(
                    result.memory.tagList.take(2).join(', '),
                    style: const TextStyle(fontSize: 10),
                  ),
                  visualDensity: VisualDensity.compact,
                )
              : null,
        );
      },
    );
  }

  Widget _buildKnowledgeTab() {
    if (_knowledge.isEmpty) {
      return const Center(child: Text('No matching knowledge'));
    }
    return ListView.builder(
      itemCount: _knowledge.length,
      itemBuilder: (context, index) {
        final result = _knowledge[index];
        return ListTile(
          leading: const Icon(Icons.library_books_outlined),
          title: Text(result.documentName),
          subtitle: Text(
            result.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            'Score: ${result.similarityScore.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          onTap: () => context.go('/knowledge/${result.documentId}'),
        );
      },
    );
  }
}

class _Badge extends StatelessWidget {
  final int count;

  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 10,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
