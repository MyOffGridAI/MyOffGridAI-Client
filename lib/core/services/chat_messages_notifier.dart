import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/core/models/inference_stream_event.dart';
import 'package:myoffgridai_client/core/models/message_model.dart';
import 'package:myoffgridai_client/core/services/chat_service.dart';


/// Manages messages for a single conversation with optimistic updates
/// and SSE streaming support.
///
/// When a user sends a message, the bubble appears immediately in the UI
/// while an SSE stream delivers typed events (thinking, content, done).
/// The assistant message is built up incrementally as chunks arrive.
class ChatMessagesNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<MessageModel>, String> {
  @override
  Future<List<MessageModel>> build(String arg) async {
    final service = ref.watch(chatServiceProvider);
    return service.listMessages(arg);
  }

  /// Sends a message via SSE streaming with typed event handling.
  ///
  /// 1. Appends a temporary user bubble so the UI updates instantly.
  /// 2. Sets the thinking flag so the thinking indicator shows.
  /// 3. Opens an SSE stream and processes typed events:
  ///    - `thinking`: Accumulates thinking content on the assistant bubble.
  ///    - `content`: Accumulates response content on the assistant bubble.
  ///    - `done`: Sets inference metadata and finalizes the message.
  /// 4. Re-fetches messages from server to get the persisted state.
  /// 5. On error: removes the temp message, clears thinking, rethrows.
  Future<void> sendMessage(String content) async {
    final conversationId = arg;
    final tempId = 'temp-${DateTime.now().millisecondsSinceEpoch}';
    final assistantTempId = 'temp-assistant-${DateTime.now().millisecondsSinceEpoch}';

    final tempMessage = MessageModel(
      id: tempId,
      role: 'USER',
      content: content,
      hasRagContext: false,
    );

    // Optimistic update — append user bubble immediately
    state = AsyncData([
      ...state.valueOrNull ?? [],
      tempMessage,
    ]);

    // Show thinking indicator
    ref.read(aiThinkingProvider(conversationId).notifier).state = true;

    final contentBuffer = StringBuffer();
    final thinkingBuffer = StringBuffer();

    try {
      final service = ref.read(chatServiceProvider);
      final stopwatch = Stopwatch()..start();

      await for (final event in service.sendMessageStream(conversationId, content)) {
        switch (event.type) {
          case InferenceEventType.thinking:
            thinkingBuffer.write(event.content ?? '');
            _upsertAssistantBubble(
              assistantTempId,
              content: contentBuffer.toString(),
              thinkingContent: thinkingBuffer.toString(),
            );

          case InferenceEventType.content:
            // First content chunk — hide thinking indicator
            if (contentBuffer.isEmpty) {
              ref.read(aiThinkingProvider(conversationId).notifier).state = false;
            }
            contentBuffer.write(event.content ?? '');
            _upsertAssistantBubble(
              assistantTempId,
              content: contentBuffer.toString(),
              thinkingContent: thinkingBuffer.toString(),
            );

          case InferenceEventType.done:
            stopwatch.stop();

            // Update assistant bubble with final metadata
            if (event.metadata != null) {
              _upsertAssistantBubble(
                assistantTempId,
                content: contentBuffer.toString(),
                thinkingContent: thinkingBuffer.isEmpty
                    ? null
                    : thinkingBuffer.toString(),
                tokensPerSecond: event.metadata!.tokensPerSecond,
                inferenceTimeSeconds: event.metadata!.inferenceTimeSeconds,
                stopReason: event.metadata!.stopReason,
                thinkingTokenCount: event.metadata!.thinkingTokenCount,
              );
            }

          case InferenceEventType.error:
            // Surface error content to the user
            _upsertAssistantBubble(
              assistantTempId,
              content: event.content ?? 'An error occurred during inference.',
            );
        }
      }

      // Re-fetch from server to get persisted messages with real IDs
      final messages = await service.listMessages(conversationId);
      state = AsyncData(messages);

      // Refresh conversation list (title may have changed)
      ref.invalidate(conversationsProvider);

      // Staggered re-fetches to pick up async title generation
      for (final delay in [3, 6, 10]) {
        Future.delayed(Duration(seconds: delay), () {
          if (ref.exists(conversationsProvider)) {
            ref.invalidate(conversationsProvider);
          }
        });
      }
    } catch (e) {
      // Remove temp messages on error
      final current = state.valueOrNull ?? [];
      state = AsyncData(current
          .where((m) => m.id != tempId && m.id != assistantTempId)
          .toList());
      rethrow;
    } finally {
      ref.read(aiThinkingProvider(conversationId).notifier).state = false;
    }
  }

  /// Upserts a streaming assistant bubble in the message list.
  ///
  /// If a message with [id] already exists, it is replaced with updated
  /// content. Otherwise, a new assistant message is appended.
  void _upsertAssistantBubble(
    String id, {
    String content = '',
    String? thinkingContent,
    double? tokensPerSecond,
    double? inferenceTimeSeconds,
    String? stopReason,
    int? thinkingTokenCount,
  }) {
    final current = state.valueOrNull ?? [];
    final msg = MessageModel(
      id: id,
      role: 'ASSISTANT',
      content: content,
      hasRagContext: false,
      thinkingContent: thinkingContent,
      tokensPerSecond: tokensPerSecond,
      inferenceTimeSeconds: inferenceTimeSeconds,
      stopReason: stopReason,
      thinkingTokenCount: thinkingTokenCount,
    );

    final idx = current.indexWhere((m) => m.id == id);
    if (idx >= 0) {
      final updated = [...current];
      updated[idx] = msg;
      state = AsyncData(updated);
    } else {
      state = AsyncData([...current, msg]);
    }
  }

  /// Edits a user message, refreshes the message list.
  Future<void> editMessage(String messageId, String newContent) async {
    final service = ref.read(chatServiceProvider);
    await service.editMessage(arg, messageId, newContent);
    final messages = await service.listMessages(arg);
    state = AsyncData(messages);
  }

  /// Deletes a message and all subsequent messages.
  Future<void> deleteMessage(String messageId) async {
    final service = ref.read(chatServiceProvider);
    await service.deleteMessage(arg, messageId);
    final messages = await service.listMessages(arg);
    state = AsyncData(messages);
  }

  /// Regenerates an assistant message via SSE streaming.
  Future<void> regenerateMessage(String messageId) async {
    final conversationId = arg;
    final assistantTempId = 'temp-regen-${DateTime.now().millisecondsSinceEpoch}';

    ref.read(aiThinkingProvider(conversationId).notifier).state = true;

    final contentBuffer = StringBuffer();
    final thinkingBuffer = StringBuffer();

    try {
      final service = ref.read(chatServiceProvider);
      final stopwatch = Stopwatch()..start();

      // Remove the old assistant message from UI
      final current = state.valueOrNull ?? [];
      state = AsyncData(current.where((m) => m.id != messageId).toList());

      await for (final event
          in service.regenerateMessage(conversationId, messageId)) {
        switch (event.type) {
          case InferenceEventType.thinking:
            thinkingBuffer.write(event.content ?? '');
            _upsertAssistantBubble(
              assistantTempId,
              content: contentBuffer.toString(),
              thinkingContent: thinkingBuffer.toString(),
            );

          case InferenceEventType.content:
            if (contentBuffer.isEmpty) {
              ref.read(aiThinkingProvider(conversationId).notifier).state =
                  false;
            }
            contentBuffer.write(event.content ?? '');
            _upsertAssistantBubble(
              assistantTempId,
              content: contentBuffer.toString(),
              thinkingContent: thinkingBuffer.toString(),
            );

          case InferenceEventType.done:
            stopwatch.stop();
            if (event.metadata != null) {
              _upsertAssistantBubble(
                assistantTempId,
                content: contentBuffer.toString(),
                thinkingContent: thinkingBuffer.isEmpty
                    ? null
                    : thinkingBuffer.toString(),
                tokensPerSecond: event.metadata!.tokensPerSecond,
                inferenceTimeSeconds: event.metadata!.inferenceTimeSeconds,
                stopReason: event.metadata!.stopReason,
              );
            }

          case InferenceEventType.error:
            _upsertAssistantBubble(
              assistantTempId,
              content: event.content ?? 'An error occurred during inference.',
            );
        }
      }

      // Re-fetch from server
      final messages = await service.listMessages(conversationId);
      state = AsyncData(messages);
    } catch (e) {
      final current = state.valueOrNull ?? [];
      state = AsyncData(
          current.where((m) => m.id != assistantTempId).toList());
      rethrow;
    } finally {
      ref.read(aiThinkingProvider(conversationId).notifier).state = false;
    }
  }
}

/// Family provider for [ChatMessagesNotifier] keyed by conversation ID.
final chatMessagesNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<ChatMessagesNotifier, List<MessageModel>, String>(
  ChatMessagesNotifier.new,
);
