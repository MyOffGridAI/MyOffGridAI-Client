import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/models/message_model.dart';
import 'package:myoffgridai_client/core/services/chat_messages_notifier.dart';
import 'package:myoffgridai_client/core/services/chat_service.dart';
import 'package:myoffgridai_client/features/chat/widgets/message_bubble.dart';

import 'package:myoffgridai_client/shared/widgets/error_view.dart';
import 'package:myoffgridai_client/shared/widgets/loading_indicator.dart';

/// Chat conversation screen showing messages and input field.
///
/// Displays messages in a scrollable list with the input field at the
/// bottom. User messages appear instantly (optimistic update) and an
/// animated thinking indicator shows while the AI responds. Supports
/// markdown rendering, thinking blocks, inference metadata, and message
/// actions (edit, delete, regenerate, branch).
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

/// State for [ChatConversationScreen] managing message input, sending, and initial message dispatch.
class _ChatConversationScreenState
    extends ConsumerState<ChatConversationScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialMessage != null) {
      _sendInitialMessage();
    }
  }

  /// Waits for the notifier's initial build to complete, then sends
  /// the welcome-screen message.
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
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync =
        ref.watch(chatMessagesNotifierProvider(widget.conversationId));
    final isThinking =
        ref.watch(aiThinkingProvider(widget.conversationId));
    final isJudgeEvaluating =
        ref.watch(judgeEvaluatingProvider(widget.conversationId));

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
                final indicatorCount = isJudgeEvaluating ? 1 : 0;
                final itemCount = messages.length + indicatorCount;
                if (messages.isEmpty && !isJudgeEvaluating) {
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
                    if (isJudgeEvaluating && index == 0) {
                      return const _JudgeEvaluatingIndicator();
                    }
                    final msgIndex = index - indicatorCount;
                    final msg = messages[messages.length - 1 - msgIndex];
                    final isStreaming = msg.id.startsWith('temp-assistant') ||
                        msg.id.startsWith('temp-regen');

                    return MessageBubble(
                      message: msg,
                      isStreaming: isStreaming,
                      isActivelyThinking: isThinking,
                      onEdit: msg.isUser ? _handleEdit : null,
                      onDelete: _handleDelete,
                      onRegenerate:
                          msg.isAssistant ? _handleRegenerate : null,
                      onBranch: _handleBranch,
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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: KeyboardListener(
                focusNode: FocusNode(),
                onKeyEvent: (event) {
                  // Shift+Enter inserts newline (default behavior)
                  // Enter alone sends the message
                  if (event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.enter &&
                      !HardwareKeyboard.instance.isShiftPressed) {
                    _sendMessage();
                  }
                },
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    suffixIcon: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _messageController,
                      builder: (context, value, _) {
                        final charCount = value.text.length;
                        if (charCount == 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(right: 8, top: 12),
                          child: Text(
                            '$charCount',
                            style: TextStyle(
                              fontSize: 10,
                              color: colorScheme.onSurface
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  maxLines: 6,
                  minLines: 1,
                  textInputAction: TextInputAction.newline,
                ),
              ),
            ),
            const SizedBox(width: 4),
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
        _focusNode.requestFocus();
      }
    }
  }

  /// Handles editing a user message via a dialog.
  void _handleEdit(MessageModel message) {
    final controller = TextEditingController(text: message.content);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(
          controller: controller,
          maxLines: 6,
          minLines: 1,
          decoration: const InputDecoration(
            hintText: 'Edit your message...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final newContent = controller.text.trim();
              if (newContent.isNotEmpty && newContent != message.content) {
                ref
                    .read(chatMessagesNotifierProvider(widget.conversationId)
                        .notifier)
                    .editMessage(message.id, newContent);
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose;
  }

  /// Handles deleting a message with confirmation.
  void _handleDelete(MessageModel message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text(
          'This will delete this message and all subsequent messages. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              ref
                  .read(chatMessagesNotifierProvider(widget.conversationId)
                      .notifier)
                  .deleteMessage(message.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Handles regenerating an assistant message.
  void _handleRegenerate(MessageModel message) {
    ref
        .read(chatMessagesNotifierProvider(widget.conversationId).notifier)
        .regenerateMessage(message.id);
  }

  /// Handles branching at a message.
  void _handleBranch(MessageModel message) {
    final service = ref.read(chatServiceProvider);
    service.branchConversation(widget.conversationId, message.id).then(
      (conversation) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Branched: ${conversation.title ?? 'New branch'}'),
            ),
          );
          ref.invalidate(conversationsProvider);
        }
      },
    ).catchError((e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to branch: $e')),
        );
      }
    });
  }
}

/// Indicator shown while the AI judge is evaluating a response.
class _JudgeEvaluatingIndicator extends StatelessWidget {
  const _JudgeEvaluatingIndicator();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.onTertiaryContainer,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Judge evaluating...',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onTertiaryContainer,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
