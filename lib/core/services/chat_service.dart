import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/api_response.dart';
import 'package:myoffgridai_client/core/api/myoffgridai_api_client.dart';
import 'package:myoffgridai_client/core/models/conversation_model.dart';
import 'package:myoffgridai_client/core/models/message_model.dart';

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

  /// Sends a message (non-streaming) and returns the response.
  Future<ApiResponse<dynamic>> sendMessage(
    String conversationId,
    String content, {
    bool stream = false,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '${AppConstants.chatBasePath}/conversations/$conversationId/messages',
      data: {'content': content, 'stream': stream},
    );
    return ApiResponse.fromJson(response, null);
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
