import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/models/conversation_model.dart';
import 'package:myoffgridai_client/core/services/chat_service.dart';
import 'package:myoffgridai_client/shared/utils/date_formatter.dart';
import 'package:myoffgridai_client/shared/widgets/empty_state_view.dart';
import 'package:myoffgridai_client/shared/widgets/error_view.dart';
import 'package:myoffgridai_client/shared/widgets/loading_indicator.dart';

/// Displays the list of chat conversations.
///
/// Shows active conversations with last message previews. Provides a FAB
/// to start new conversations and swipe-to-delete for existing ones.
class ChatListScreen extends ConsumerWidget {
  /// Creates a [ChatListScreen].
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Conversations')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createConversation(context, ref),
        child: const Icon(Icons.add),
      ),
      body: conversationsAsync.when(
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
              subtitle: 'Tap + to start a new conversation',
            );
          }
          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conv = conversations[index];
              return _ConversationTile(
                conversation: conv,
                onTap: () => context.go('/chat/${conv.id}'),
                onDelete: () => _deleteConversation(context, ref, conv.id),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _createConversation(BuildContext context, WidgetRef ref) async {
    try {
      final service = ref.read(chatServiceProvider);
      final conv = await service.createConversation();
      ref.invalidate(conversationsProvider);
      if (context.mounted) {
        context.go('/chat/${conv.id}');
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  Future<void> _deleteConversation(
    BuildContext context,
    WidgetRef ref,
    String conversationId,
  ) async {
    try {
      final service = ref.read(chatServiceProvider);
      await service.deleteConversation(conversationId);
      ref.invalidate(conversationsProvider);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationSummaryModel conversation;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ConversationTile({
    required this.conversation,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(conversation.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.chat_bubble_outline)),
        title: Text(
          conversation.title ?? 'New Conversation',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: conversation.lastMessagePreview != null
            ? Text(
                conversation.lastMessagePreview!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (conversation.updatedAt != null)
              Text(
                DateFormatter.formatRelative(DateTime.parse(conversation.updatedAt!)),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            Text(
              '${conversation.messageCount} msgs',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
