import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/core/models/message_model.dart';
import 'package:myoffgridai_client/core/services/chat_service.dart';
import 'package:myoffgridai_client/features/chat/chat_conversation_screen.dart';

/// Manages messages for a single conversation with optimistic updates.
///
/// When a user sends a message, the bubble appears immediately in the UI
/// while the API call runs in the background. On success the full message
/// list is re-fetched from the server (which includes the persisted user
/// message and the assistant response). On error the temporary message is
/// removed and the error is rethrown for the caller to handle.
class ChatMessagesNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<MessageModel>, String> {
  @override
  Future<List<MessageModel>> build(String arg) async {
    final service = ref.watch(chatServiceProvider);
    return service.listMessages(arg);
  }

  /// Sends a message with an optimistic local update.
  ///
  /// 1. Appends a temporary user bubble so the UI updates instantly.
  /// 2. Sets the thinking flag so the thinking indicator shows.
  /// 3. Calls the API with a stopwatch running for response timing.
  /// 4. On success: re-fetches messages from server and clears thinking.
  /// 5. Schedules a delayed re-fetch to pick up async title generation.
  /// 6. On error: removes the temp message, clears thinking, rethrows.
  Future<void> sendMessage(String content) async {
    final conversationId = arg;
    final tempId = 'temp-${DateTime.now().millisecondsSinceEpoch}';

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

    try {
      final service = ref.read(chatServiceProvider);

      // Track response time
      final stopwatch = Stopwatch()..start();
      await service.sendMessage(conversationId, content);
      stopwatch.stop();

      // Store response time for display on the AI bubble
      ref.read(responseTimeProvider(conversationId).notifier).state =
          stopwatch.elapsed;

      // Re-fetch from server to get persisted messages + assistant response
      final messages = await service.listMessages(conversationId);
      state = AsyncData(messages);

      // Refresh conversation list (title may have changed)
      ref.invalidate(conversationsProvider);

      // Delayed re-fetch to pick up async title generation (~3s later)
      Future.delayed(const Duration(seconds: 3), () {
        if (ref.exists(conversationsProvider)) {
          ref.invalidate(conversationsProvider);
        }
      });
    } catch (e) {
      // Remove temp message on error
      final current = state.valueOrNull ?? [];
      state = AsyncData(current.where((m) => m.id != tempId).toList());
      rethrow;
    } finally {
      // Clear thinking indicator
      ref.read(aiThinkingProvider(conversationId).notifier).state = false;
    }
  }
}

/// Family provider for [ChatMessagesNotifier] keyed by conversation ID.
final chatMessagesNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<ChatMessagesNotifier, List<MessageModel>, String>(
  ChatMessagesNotifier.new,
);
