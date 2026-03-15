import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/models/message_model.dart';
import 'package:myoffgridai_client/core/services/chat_messages_notifier.dart';
import 'package:myoffgridai_client/core/services/chat_service.dart';
import 'package:myoffgridai_client/features/chat/widgets/thinking_indicator.dart';
import 'package:myoffgridai_client/shared/widgets/error_view.dart';
import 'package:myoffgridai_client/shared/widgets/loading_indicator.dart';

/// Provider for the response time of the latest AI response per conversation.
final responseTimeProvider =
    StateProvider.autoDispose.family<Duration?, String>((ref, conversationId) {
  return null;
});

/// Chat conversation screen showing messages and input field.
///
/// Displays messages in a scrollable list with the input field at the
/// bottom. User messages appear instantly (optimistic update) and an
/// animated thinking indicator shows while the AI responds.
class ChatConversationScreen extends ConsumerStatefulWidget {
  /// The conversation ID to display.
  final String conversationId;

  /// Optional initial message to send on mount (from welcome screen).
  final String? initialMessage;

  /// Creates a [ChatConversationScreen] for the given [conversationId].
  const ChatConversationScreen({
    super.key,
    required this.conversationId,
    this.initialMessage,
  });

  @override
  ConsumerState<ChatConversationScreen> createState() =>
      _ChatConversationScreenState();
}

class _ChatConversationScreenState
    extends ConsumerState<ChatConversationScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialMessage != null) {
      _sendInitialMessage();
    }
  }

  /// Waits for the notifier's initial build to complete, then sends
  /// the welcome-screen message. Awaiting the build prevents it from
  /// overwriting the optimistic user bubble with an empty list.
  Future<void> _sendInitialMessage() async {
    await ref.read(
      chatMessagesNotifierProvider(widget.conversationId).future,
    );
    if (mounted) {
      ref
          .read(chatMessagesNotifierProvider(widget.conversationId).notifier)
          .sendMessage(widget.initialMessage!);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync =
        ref.watch(chatMessagesNotifierProvider(widget.conversationId));
    final isThinking =
        ref.watch(aiThinkingProvider(widget.conversationId));
    final responseTime =
        ref.watch(responseTimeProvider(widget.conversationId));

    // Get conversation title from the conversations list
    final conversationsAsync = ref.watch(conversationsProvider);
    final title = conversationsAsync.whenOrNull(
      data: (conversations) {
        final match = conversations
            .where((c) => c.id == widget.conversationId)
            .toList();
        return match.isNotEmpty ? match.first.title : null;
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(title ?? 'New Conversation'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const LoadingIndicator(),
              error: (error, _) => ErrorView(
                title: 'Failed to load messages',
                message: error is ApiException
                    ? error.message
                    : 'An unexpected error occurred.',
                onRetry: () => ref.invalidate(
                    chatMessagesNotifierProvider(widget.conversationId)),
              ),
              data: (messages) {
                final itemCount = messages.length + (isThinking ? 1 : 0);
                if (messages.isEmpty && !isThinking) {
                  return const Center(
                    child: Text('Send a message to start the conversation'),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: itemCount,
                  itemBuilder: (context, index) {
                    // Index 0 = bottom of list (most recent)
                    if (isThinking && index == 0) {
                      return const ThinkingIndicatorBubble();
                    }
                    final msgIndex = isThinking ? index - 1 : index;
                    final msg = messages[messages.length - 1 - msgIndex];
                    // Show response time only on the last assistant message
                    final isLastAssistant = msg.isAssistant &&
                        msgIndex == 0 &&
                        !isThinking;
                    return _MessageBubble(
                      message: msg,
                      responseTime: isLastAssistant ? responseTime : null,
                    );
                  },
                );
              },
            ),
          ),
          _buildInputBar(context),
        ],
      ),
    );
  }

  Widget _buildInputBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                ),
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            IconButton(
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              onPressed: _isSending ? null : _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      await ref
          .read(chatMessagesNotifierProvider(widget.conversationId).notifier)
          .sendMessage(content);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final Duration? responseTime;

  const _MessageBubble({required this.message, this.responseTime});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (responseTime != null && !isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'thought for ${(responseTime!.inMilliseconds / 1000).toStringAsFixed(1)}s',
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ),
            SelectableText(
              message.content,
              style: TextStyle(
                color: isUser ? colorScheme.onPrimary : colorScheme.onSurface,
              ),
            ),
            if (message.hasRagContext)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(
                  Icons.auto_stories,
                  size: 14,
                  color: isUser
                      ? colorScheme.onPrimary.withValues(alpha: 0.7)
                      : colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
