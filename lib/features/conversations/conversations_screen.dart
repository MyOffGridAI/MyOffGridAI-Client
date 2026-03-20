import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/models/conversation_model.dart';
import 'package:myoffgridai_client/core/services/chat_service.dart';
import 'package:myoffgridai_client/shared/utils/date_formatter.dart';
import 'package:myoffgridai_client/shared/widgets/confirmation_dialog.dart';
import 'package:myoffgridai_client/shared/widgets/empty_state_view.dart';
import 'package:myoffgridai_client/shared/widgets/error_view.dart';
import 'package:myoffgridai_client/shared/widgets/loading_indicator.dart';

/// Displays a full conversations management screen with search,
/// Active/Archived tabs, and rename/archive/delete actions.
///
/// Follows the [KnowledgeScreen] pattern: [ConsumerStatefulWidget],
/// AppBar with search toggle, list with popup menu actions.
class ConversationsScreen extends ConsumerStatefulWidget {
  /// Creates a [ConversationsScreen].
  const ConversationsScreen({super.key});

  @override
  ConsumerState<ConversationsScreen> createState() =>
      _ConversationsScreenState();
}

/// State for [ConversationsScreen] managing search, tabs, and conversation actions.
class _ConversationsScreenState extends ConsumerState<ConversationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _isSearching = false;
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<ConversationSummaryModel>? _searchResults;
  bool _isSearchLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = null;
        _isSearchLoading = false;
      });
      return;
    }
    setState(() => _isSearchLoading = true);
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final service = ref.read(chatServiceProvider);
        final results = await service.searchConversations(query.trim());
        if (mounted) {
          setState(() {
            _searchResults = results;
            _isSearchLoading = false;
          });
        }
      } on ApiException catch (e) {
        if (mounted) {
          setState(() => _isSearchLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message)),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search conversations...',
                  border: InputBorder.none,
                ),
                onChanged: _onSearchChanged,
              )
            : const Text('Conversations'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            tooltip: _isSearching ? 'Close search' : 'Search',
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchResults = null;
                  _isSearchLoading = false;
                }
              });
            },
          ),
        ],
        bottom: _isSearching
            ? null
            : TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Active'),
                  Tab(text: 'Archived'),
                ],
              ),
      ),
      body: _isSearching
          ? _buildSearchResults()
          : TabBarView(
              controller: _tabController,
              children: [
                _ActiveTab(
                  onRename: _showRenameDialog,
                  onArchive: _archiveConversation,
                  onDelete: _confirmDelete,
                ),
                _ArchivedTab(
                  onRename: _showRenameDialog,
                  onDelete: _confirmDelete,
                ),
              ],
            ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearchLoading) {
      return const LoadingIndicator();
    }
    if (_searchResults == null) {
      return const EmptyStateView(
        icon: Icons.search,
        title: 'Search conversations',
        subtitle: 'Type to search by title',
      );
    }
    if (_searchResults!.isEmpty) {
      return EmptyStateView(
        icon: Icons.search_off,
        title: 'No results for \'${_searchController.text}\'',
      );
    }
    return ListView.builder(
      itemCount: _searchResults!.length,
      itemBuilder: (context, index) {
        final conv = _searchResults![index];
        return _ConversationListTile(
          conversation: conv,
          onTap: () => context.go('/chat/${conv.id}'),
          onRename: () => _showRenameDialog(conv),
          onArchive: conv.isArchived ? null : () => _archiveConversation(conv.id),
          onDelete: () => _confirmDelete(conv.id),
        );
      },
    );
  }

  Future<void> _showRenameDialog(ConversationSummaryModel conversation) async {
    final controller = TextEditingController(
      text: conversation.title ?? '',
    );
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename conversation'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.pop(ctx, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (result != null && result.isNotEmpty && mounted) {
      try {
        final service = ref.read(chatServiceProvider);
        await service.renameConversation(conversation.id, result);
        ref.invalidate(conversationsProvider);
        ref.invalidate(archivedConversationsProvider);
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message)),
          );
        }
      }
    }
  }

  Future<void> _archiveConversation(String conversationId) async {
    try {
      final service = ref.read(chatServiceProvider);
      await service.archiveConversation(conversationId);
      ref.invalidate(conversationsProvider);
      ref.invalidate(archivedConversationsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conversation archived')),
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

  Future<void> _confirmDelete(String conversationId) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Conversation',
      message:
          'This will permanently delete this conversation and all its messages.',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      try {
        final service = ref.read(chatServiceProvider);
        await service.deleteConversation(conversationId);
        ref.invalidate(conversationsProvider);
        ref.invalidate(archivedConversationsProvider);
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message)),
          );
        }
      }
    }
  }
}

/// Active conversations tab showing non-archived conversations.
class _ActiveTab extends ConsumerWidget {
  final void Function(ConversationSummaryModel) onRename;
  final void Function(String) onArchive;
  final void Function(String) onDelete;

  const _ActiveTab({
    required this.onRename,
    required this.onArchive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);
    return conversationsAsync.when(
      loading: () => const LoadingIndicator(),
      error: (error, _) => ErrorView(
        title: 'Failed to load conversations',
        message: error is ApiException
            ? error.message
            : 'An unexpected error occurred.',
        onRetry: () => ref.invalidate(conversationsProvider),
      ),
      data: (conversations) {
        if (conversations.isEmpty) {
          return const EmptyStateView(
            icon: Icons.chat_bubble_outline,
            title: 'No conversations yet',
            subtitle: 'Start a new chat to begin',
          );
        }
        return ListView.builder(
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            final conv = conversations[index];
            return _ConversationListTile(
              conversation: conv,
              onTap: () => context.go('/chat/${conv.id}'),
              onRename: () => onRename(conv),
              onArchive: () => onArchive(conv.id),
              onDelete: () => onDelete(conv.id),
            );
          },
        );
      },
    );
  }
}

/// Archived conversations tab.
class _ArchivedTab extends ConsumerWidget {
  final void Function(ConversationSummaryModel) onRename;
  final void Function(String) onDelete;

  const _ArchivedTab({
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archivedAsync = ref.watch(archivedConversationsProvider);
    return archivedAsync.when(
      loading: () => const LoadingIndicator(),
      error: (error, _) => ErrorView(
        title: 'Failed to load archived conversations',
        message: error is ApiException
            ? error.message
            : 'An unexpected error occurred.',
        onRetry: () => ref.invalidate(archivedConversationsProvider),
      ),
      data: (conversations) {
        if (conversations.isEmpty) {
          return const EmptyStateView(
            icon: Icons.archive_outlined,
            title: 'No archived conversations',
          );
        }
        return ListView.builder(
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            final conv = conversations[index];
            return _ConversationListTile(
              conversation: conv,
              onTap: () => context.go('/chat/${conv.id}'),
              onRename: () => onRename(conv),
              onArchive: null,
              onDelete: () => onDelete(conv.id),
            );
          },
        );
      },
    );
  }
}

/// A single conversation tile used in the management screen.
class _ConversationListTile extends StatelessWidget {
  final ConversationSummaryModel conversation;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback? onArchive;
  final VoidCallback onDelete;

  const _ConversationListTile({
    required this.conversation,
    required this.onTap,
    required this.onRename,
    this.onArchive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final title = (conversation.title != null && conversation.title!.isNotEmpty)
        ? conversation.title!
        : 'Untitled';

    return ListTile(
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          Text(
            '${conversation.messageCount} messages',
            style: const TextStyle(fontSize: 12),
          ),
          if (conversation.lastMessagePreview != null) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                conversation.lastMessagePreview!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
          if (conversation.updatedAt != null) ...[
            const SizedBox(width: 8),
            Text(
              DateFormatter.formatRelative(
                  DateTime.parse(conversation.updatedAt!)),
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
            ),
          ],
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          switch (value) {
            case 'rename':
              onRename();
            case 'archive':
              onArchive?.call();
            case 'delete':
              onDelete();
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'rename',
            child: Row(
              children: [
                Icon(Icons.edit, size: 16),
                SizedBox(width: 8),
                Text('Rename'),
              ],
            ),
          ),
          if (onArchive != null)
            const PopupMenuItem(
              value: 'archive',
              child: Row(
                children: [
                  Icon(Icons.archive, size: 16),
                  SizedBox(width: 8),
                  Text('Archive'),
                ],
              ),
            ),
          const PopupMenuItem(
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
      onTap: onTap,
    );
  }
}
