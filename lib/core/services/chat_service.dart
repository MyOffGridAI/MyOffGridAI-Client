import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/myoffgridai_api_client.dart';
import 'package:myoffgridai_client/core/models/conversation_model.dart';
import 'package:myoffgridai_client/core/models/inference_stream_event.dart';
import 'package:myoffgridai_client/core/models/message_model.dart';
import 'package:myoffgridai_client/core/services/log_service.dart';

/// Service for chat conversation and message operations.
///
/// Wraps [MyOffGridAIApiClient] and returns typed models. Screens access
/// this service via Riverpod providers.
class ChatService {
  final MyOffGridAIApiClient _client;

  /// Creates a [ChatService] with the given API [client].
  ChatService({required MyOffGridAIApiClient client}) : _client = client;

  /// Lists conversations with pagination and optional archive filter.
  Future<List<ConversationSummaryModel>> listConversations({
    int page = 0,
    int size = 20,
    bool archived = false,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '${AppConstants.chatBasePath}/conversations',
      queryParams: {'page': page, 'size': size, 'archived': archived},
    );
    final data = response['data'] as List<dynamic>?;
    if (data == null) return [];
    return data
        .map((e) => ConversationSummaryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Creates a new conversation with an optional [title].
  Future<ConversationModel> createConversation({String? title}) async {
    final response = await _client.post<Map<String, dynamic>>(
      '${AppConstants.chatBasePath}/conversations',
      data: title != null ? {'title': title} : {},
    );
    final data = response['data'] as Map<String, dynamic>;
    return ConversationModel.fromJson(data);
  }

  /// Gets a single conversation by [conversationId].
  Future<ConversationModel> getConversation(String conversationId) async {
    final response = await _client.get<Map<String, dynamic>>(
      '${AppConstants.chatBasePath}/conversations/$conversationId',
    );
    final data = response['data'] as Map<String, dynamic>;
    return ConversationModel.fromJson(data);
  }

  /// Deletes a conversation by [conversationId].
  Future<void> deleteConversation(String conversationId) async {
    await _client.delete(
      '${AppConstants.chatBasePath}/conversations/$conversationId',
    );
  }

  /// Archives a conversation by [conversationId].
  Future<void> archiveConversation(String conversationId) async {
    await _client.put<Map<String, dynamic>>(
      '${AppConstants.chatBasePath}/conversations/$conversationId/archive',
    );
  }

  /// Renames a conversation by [conversationId] with a new [title].
  Future<ConversationModel> renameConversation(
    String conversationId,
    String title,
  ) async {
    final response = await _client.put<Map<String, dynamic>>(
      '${AppConstants.chatBasePath}/conversations/$conversationId/title',
      data: {'title': title},
    );
    final data = response['data'] as Map<String, dynamic>;
    return ConversationModel.fromJson(data);
  }

  /// Searches conversations by title.
  Future<List<ConversationSummaryModel>> searchConversations(
    String query,
  ) async {
    final response = await _client.get<Map<String, dynamic>>(
      '${AppConstants.chatBasePath}/conversations/search',
      queryParams: {'q': query},
    );
    final data = response['data'] as List<dynamic>?;
    if (data == null) return [];
    return data
        .map((e) =>
            ConversationSummaryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Lists messages in a conversation with pagination.
  Future<List<MessageModel>> listMessages(
    String conversationId, {
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '${AppConstants.chatBasePath}/conversations/$conversationId/messages',
      queryParams: {'page': page, 'size': size},
    );
    final data = response['data'] as List<dynamic>?;
    if (data == null) return [];
    return data
        .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Sends a message (non-streaming) and returns the assistant's response.
  Future<MessageModel> sendMessage(
    String conversationId,
    String content, {
    bool stream = false,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '${AppConstants.chatBasePath}/conversations/$conversationId/messages',
      data: {'content': content, 'stream': stream},
    );
    final data = response['data'] as Map<String, dynamic>;
    return MessageModel.fromJson(data);
  }

  /// Sends a message with SSE streaming, yielding typed [InferenceStreamEvent]s.
  ///
  /// The server emits `data:` lines containing JSON objects with `type`,
  /// `content`, and `metadata` fields. This method parses each SSE line
  /// and yields the corresponding event.
  Stream<InferenceStreamEvent> sendMessageStream(
    String conversationId,
    String content,
  ) async* {
    yield* _sseStream(
      '${AppConstants.chatBasePath}/conversations/$conversationId/messages',
      data: {'content': content, 'stream': true},
    );
  }

  /// Edits a user message and triggers re-inference.
  ///
  /// Deletes all subsequent messages and updates the message content.
  Future<MessageModel> editMessage(
    String conversationId,
    String messageId,
    String newContent,
  ) async {
    final response = await _client.put<Map<String, dynamic>>(
      '${AppConstants.chatBasePath}/conversations/$conversationId/messages/$messageId',
      data: {'content': newContent},
    );
    final data = response['data'] as Map<String, dynamic>;
    return MessageModel.fromJson(data);
  }

  /// Deletes a message and all subsequent messages in the conversation.
  Future<void> deleteMessage(
    String conversationId,
    String messageId,
  ) async {
    await _client.delete(
      '${AppConstants.chatBasePath}/conversations/$conversationId/messages/$messageId',
    );
  }

  /// Branches a conversation at a specific message.
  ///
  /// Creates a new conversation with all messages up to (inclusive) [messageId].
  Future<ConversationModel> branchConversation(
    String conversationId,
    String messageId, {
    String? title,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '${AppConstants.chatBasePath}/conversations/$conversationId/branch/$messageId',
      data: title != null ? {'title': title} : null,
    );
    final data = response['data'] as Map<String, dynamic>;
    return ConversationModel.fromJson(data);
  }

  /// Regenerates an assistant message via SSE streaming.
  ///
  /// Deletes the target message and re-runs inference, yielding typed events.
  Stream<InferenceStreamEvent> regenerateMessage(
    String conversationId,
    String messageId,
  ) async* {
    yield* _sseStream(
      '${AppConstants.chatBasePath}/conversations/$conversationId/messages/$messageId/regenerate',
    );
  }

  /// Opens an SSE stream via POST and yields parsed [InferenceStreamEvent]s.
  Stream<InferenceStreamEvent> _sseStream(
    String path, {
    Map<String, dynamic>? data,
  }) async* {
    final responseBody = await _client.postStream(
      path,
      data: data,
      receiveTimeout: AppConstants.sseTimeout,
    );

    final stream = responseBody?.stream;
    if (stream == null) return;

    final lineBuffer = StringBuffer();
    await for (final chunk in stream) {
      final text = utf8.decode(chunk, allowMalformed: true);
      lineBuffer.write(text);

      // Process complete lines from the buffer
      final buffered = lineBuffer.toString();
      final lines = buffered.split('\n');

      // Keep the last incomplete line in the buffer
      lineBuffer.clear();
      if (!buffered.endsWith('\n')) {
        lineBuffer.write(lines.removeLast());
      } else {
        lines.removeLast(); // Remove trailing empty string
      }

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;

        // SSE format: "data:..." or "data: ..."
        if (trimmed.startsWith('data:')) {
          final payload = trimmed.substring(5).trim();
          if (payload.isEmpty) continue;

          try {
            final json = jsonDecode(payload) as Map<String, dynamic>;
            final event = InferenceStreamEvent.fromJson(json);
            LogService.instance.debug('SSE', 'type=${event.type.name} content=${event.content?.substring(0, event.content!.length.clamp(0, 50))}');
            yield event;
          } catch (e) {
            LogService.instance.error('SSE', 'Parse error: payload=$payload', e);
          }
        }
      }
    }
  }
}

/// Riverpod provider for [ChatService].
final chatServiceProvider = Provider<ChatService>((ref) {
  final client = ref.watch(apiClientProvider);
  return ChatService(client: client);
});

/// Provider for the conversation list.
final conversationsProvider =
    FutureProvider.autoDispose<List<ConversationSummaryModel>>((ref) async {
  final service = ref.watch(chatServiceProvider);
  return service.listConversations();
});

/// Provider for messages in a specific conversation.
final messagesProvider = FutureProvider.autoDispose
    .family<List<MessageModel>, String>((ref, conversationId) async {
  final service = ref.watch(chatServiceProvider);
  return service.listMessages(conversationId);
});

/// Provider tracking AI thinking state per conversation.
final aiThinkingProvider =
    StateProvider.autoDispose.family<bool, String>((ref, conversationId) {
  return false;
});

/// Provider tracking judge evaluation state per conversation.
///
/// Set to true when a `judge_evaluating` SSE event arrives, false when
/// `judge_result` arrives or the stream completes.
final judgeEvaluatingProvider =
    StateProvider.autoDispose.family<bool, String>((ref, conversationId) {
  return false;
});

/// Provider for sidebar collapsed state.
final sidebarCollapsedProvider = StateProvider<bool>((ref) => false);
