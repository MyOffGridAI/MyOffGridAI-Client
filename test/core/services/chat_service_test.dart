import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/api/myoffgridai_api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/core/services/chat_service.dart';

class MockApiClient extends Mock implements MyOffGridAIApiClient {}

void main() {
  late MockApiClient mockClient;
  late ChatService service;

  setUp(() {
    mockClient = MockApiClient();
    service = ChatService(client: mockClient);
  });

  // ---------------------------------------------------------------------------
  // listConversations
  // ---------------------------------------------------------------------------
  group('listConversations', () {
    test('returns parsed list from API response', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.chatBasePath}/conversations',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': [
              {
                'id': 'conv-1',
                'title': 'Chicken Coop Plans',
                'isArchived': false,
                'messageCount': 5,
                'updatedAt': '2026-03-16T10:00:00Z',
                'lastMessagePreview': 'How many nesting boxes?',
              },
              {
                'id': 'conv-2',
                'title': 'Solar Panel Wiring',
                'isArchived': false,
                'messageCount': 12,
                'updatedAt': '2026-03-15T08:30:00Z',
                'lastMessagePreview': 'Use 10 AWG wire',
              },
            ],
          });

      final result = await service.listConversations();

      expect(result, hasLength(2));
      expect(result[0].id, 'conv-1');
      expect(result[0].title, 'Chicken Coop Plans');
      expect(result[0].messageCount, 5);
      expect(result[1].id, 'conv-2');
      expect(result[1].lastMessagePreview, 'Use 10 AWG wire');
    });

    test('passes pagination and archived query params', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.chatBasePath}/conversations',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {'data': <dynamic>[]});

      await service.listConversations(page: 2, size: 10, archived: true);

      final captured = verify(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.chatBasePath}/conversations',
            queryParams: captureAny(named: 'queryParams'),
          )).captured;

      final params = captured.first as Map<String, dynamic>;
      expect(params['page'], 2);
      expect(params['size'], 10);
      expect(params['archived'], true);
    });

    test('returns empty list when data is null', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.chatBasePath}/conversations',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {'data': null});

      final result = await service.listConversations();

      expect(result, isEmpty);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.chatBasePath}/conversations',
            queryParams: any(named: 'queryParams'),
          )).thenThrow(const ApiException(
        statusCode: 500,
        message: 'Internal server error',
      ));

      expect(
        () => service.listConversations(),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // createConversation
  // ---------------------------------------------------------------------------
  group('createConversation', () {
    test('sends title and returns ConversationModel', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.chatBasePath}/conversations',
            data: any(named: 'data'),
          )).thenAnswer((_) async => {
            'data': {
              'id': 'conv-new',
              'title': 'Garden Layout',
              'isArchived': false,
              'messageCount': 0,
              'createdAt': '2026-03-16T12:00:00Z',
              'updatedAt': '2026-03-16T12:00:00Z',
            },
          });

      final result = await service.createConversation(title: 'Garden Layout');

      expect(result.id, 'conv-new');
      expect(result.title, 'Garden Layout');
      expect(result.messageCount, 0);
    });

    test('sends empty body when title is null', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.chatBasePath}/conversations',
            data: any(named: 'data'),
          )).thenAnswer((_) async => {
            'data': {
              'id': 'conv-untitled',
              'title': null,
              'isArchived': false,
              'messageCount': 0,
            },
          });

      await service.createConversation();

      final captured = verify(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.chatBasePath}/conversations',
            data: captureAny(named: 'data'),
          )).captured;

      final sentData = captured.first as Map;
      expect(sentData.containsKey('title'), isFalse);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.chatBasePath}/conversations',
            data: any(named: 'data'),
          )).thenThrow(const ApiException(
        statusCode: 400,
        message: 'Bad request',
      ));

      expect(
        () => service.createConversation(title: 'Test'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // getConversation
  // ---------------------------------------------------------------------------
  group('getConversation', () {
    test('returns ConversationModel for given id', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.chatBasePath}/conversations/conv-1',
          )).thenAnswer((_) async => {
            'data': {
              'id': 'conv-1',
              'title': 'Water Filtration',
              'isArchived': false,
              'messageCount': 3,
              'createdAt': '2026-03-10T08:00:00Z',
              'updatedAt': '2026-03-16T09:00:00Z',
            },
          });

      final result = await service.getConversation('conv-1');

      expect(result.id, 'conv-1');
      expect(result.title, 'Water Filtration');
      expect(result.isArchived, isFalse);
      verify(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.chatBasePath}/conversations/conv-1',
          )).called(1);
    });

    test('throws ApiException on 404', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.chatBasePath}/conversations/missing',
          )).thenThrow(const ApiException(
        statusCode: 404,
        message: 'Conversation not found',
      ));

      expect(
        () => service.getConversation('missing'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // deleteConversation
  // ---------------------------------------------------------------------------
  group('deleteConversation', () {
    test('calls DELETE on correct path', () async {
      when(() => mockClient.delete(
            '${AppConstants.chatBasePath}/conversations/conv-1',
          )).thenAnswer((_) async {});

      await service.deleteConversation('conv-1');

      verify(() => mockClient.delete(
            '${AppConstants.chatBasePath}/conversations/conv-1',
          )).called(1);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.delete(
            '${AppConstants.chatBasePath}/conversations/conv-1',
          )).thenThrow(const ApiException(
        statusCode: 403,
        message: 'Forbidden',
      ));

      expect(
        () => service.deleteConversation('conv-1'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // archiveConversation
  // ---------------------------------------------------------------------------
  group('archiveConversation', () {
    test('calls PUT on correct archive path', () async {
      when(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.chatBasePath}/conversations/conv-1/archive',
          )).thenAnswer((_) async => <String, dynamic>{});

      await service.archiveConversation('conv-1');

      verify(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.chatBasePath}/conversations/conv-1/archive',
          )).called(1);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.chatBasePath}/conversations/conv-1/archive',
          )).thenThrow(const ApiException(
        statusCode: 404,
        message: 'Conversation not found',
      ));

      expect(
        () => service.archiveConversation('conv-1'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // renameConversation
  // ---------------------------------------------------------------------------
  group('renameConversation', () {
    test('sends title and returns updated ConversationModel', () async {
      when(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.chatBasePath}/conversations/conv-1/title',
            data: any(named: 'data'),
          )).thenAnswer((_) async => {
            'data': {
              'id': 'conv-1',
              'title': 'Renamed Conversation',
              'isArchived': false,
              'messageCount': 5,
              'createdAt': '2026-03-10T08:00:00Z',
              'updatedAt': '2026-03-16T14:00:00Z',
            },
          });

      final result = await service.renameConversation('conv-1', 'Renamed Conversation');

      expect(result.id, 'conv-1');
      expect(result.title, 'Renamed Conversation');

      final captured = verify(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.chatBasePath}/conversations/conv-1/title',
            data: captureAny(named: 'data'),
          )).captured;

      final sentData = captured.first as Map<String, dynamic>;
      expect(sentData['title'], 'Renamed Conversation');
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.chatBasePath}/conversations/conv-1/title',
            data: any(named: 'data'),
          )).thenThrow(const ApiException(
        statusCode: 400,
        message: 'Title too long',
      ));

      expect(
        () => service.renameConversation('conv-1', 'x' * 500),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // searchConversations
  // ---------------------------------------------------------------------------
  group('searchConversations', () {
    test('returns matching conversations', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.chatBasePath}/conversations/search',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': [
              {
                'id': 'conv-1',
                'title': 'Solar Panel Setup',
                'isArchived': false,
                'messageCount': 8,
                'updatedAt': '2026-03-15T10:00:00Z',
                'lastMessagePreview': 'Connect in series',
              },
            ],
          });

      final result = await service.searchConversations('solar');

      expect(result, hasLength(1));
      expect(result[0].title, 'Solar Panel Setup');
    });

    test('passes query param correctly', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.chatBasePath}/conversations/search',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {'data': <dynamic>[]});

      await service.searchConversations('water filter');

      final captured = verify(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.chatBasePath}/conversations/search',
            queryParams: captureAny(named: 'queryParams'),
          )).captured;

      final params = captured.first as Map<String, dynamic>;
      expect(params['q'], 'water filter');
    });

    test('returns empty list when data is null', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.chatBasePath}/conversations/search',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {'data': null});

      final result = await service.searchConversations('nothing');

      expect(result, isEmpty);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.chatBasePath}/conversations/search',
            queryParams: any(named: 'queryParams'),
          )).thenThrow(const ApiException(
        statusCode: 500,
        message: 'Search failed',
      ));

      expect(
        () => service.searchConversations('test'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // listMessages
  // ---------------------------------------------------------------------------
  group('listMessages', () {
    test('returns parsed message list', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.chatBasePath}/conversations/conv-1/messages',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': [
              {
                'id': 'msg-1',
                'role': 'USER',
                'content': 'How do I compost?',
                'tokenCount': 12,
                'hasRagContext': false,
                'createdAt': '2026-03-16T10:00:00Z',
              },
              {
                'id': 'msg-2',
                'role': 'ASSISTANT',
                'content': 'Start with a green-brown ratio...',
                'tokenCount': 85,
                'hasRagContext': true,
                'createdAt': '2026-03-16T10:00:05Z',
              },
            ],
          });

      final result = await service.listMessages('conv-1');

      expect(result, hasLength(2));
      expect(result[0].id, 'msg-1');
      expect(result[0].role, 'USER');
      expect(result[0].isUser, isTrue);
      expect(result[1].role, 'ASSISTANT');
      expect(result[1].isAssistant, isTrue);
      expect(result[1].hasRagContext, isTrue);
    });

    test('passes pagination query params', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.chatBasePath}/conversations/conv-1/messages',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {'data': <dynamic>[]});

      await service.listMessages('conv-1', page: 3, size: 50);

      final captured = verify(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.chatBasePath}/conversations/conv-1/messages',
            queryParams: captureAny(named: 'queryParams'),
          )).captured;

      final params = captured.first as Map<String, dynamic>;
      expect(params['page'], 3);
      expect(params['size'], 50);
    });

    test('returns empty list when data is null', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.chatBasePath}/conversations/conv-1/messages',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {'data': null});

      final result = await service.listMessages('conv-1');

      expect(result, isEmpty);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.chatBasePath}/conversations/conv-1/messages',
            queryParams: any(named: 'queryParams'),
          )).thenThrow(const ApiException(
        statusCode: 404,
        message: 'Conversation not found',
      ));

      expect(
        () => service.listMessages('conv-1'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // sendMessage
  // ---------------------------------------------------------------------------
  group('sendMessage', () {
    test('sends content and returns assistant response', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.chatBasePath}/conversations/conv-1/messages',
            data: any(named: 'data'),
          )).thenAnswer((_) async => {
            'data': {
              'id': 'msg-resp',
              'role': 'ASSISTANT',
              'content': 'The best soil for raised beds is...',
              'tokenCount': 150,
              'hasRagContext': true,
              'createdAt': '2026-03-16T10:01:00Z',
            },
          });

      final result = await service.sendMessage('conv-1', 'What soil is best?');

      expect(result.id, 'msg-resp');
      expect(result.role, 'ASSISTANT');
      expect(result.hasRagContext, isTrue);

      final captured = verify(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.chatBasePath}/conversations/conv-1/messages',
            data: captureAny(named: 'data'),
          )).captured;

      final sentData = captured.first as Map<String, dynamic>;
      expect(sentData['content'], 'What soil is best?');
      expect(sentData['stream'], false);
    });

    test('passes stream flag when true', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.chatBasePath}/conversations/conv-1/messages',
            data: any(named: 'data'),
          )).thenAnswer((_) async => {
            'data': {
              'id': 'msg-stream',
              'role': 'ASSISTANT',
              'content': 'Streaming response...',
              'tokenCount': 20,
              'hasRagContext': false,
              'createdAt': '2026-03-16T10:02:00Z',
            },
          });

      await service.sendMessage('conv-1', 'Hello', stream: true);

      final captured = verify(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.chatBasePath}/conversations/conv-1/messages',
            data: captureAny(named: 'data'),
          )).captured;

      final sentData = captured.first as Map<String, dynamic>;
      expect(sentData['stream'], true);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.chatBasePath}/conversations/conv-1/messages',
            data: any(named: 'data'),
          )).thenThrow(const ApiException(
        statusCode: 503,
        message: 'Model unavailable',
      ));

      expect(
        () => service.sendMessage('conv-1', 'Hello'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // editMessage
  // ---------------------------------------------------------------------------
  group('editMessage', () {
    test('calls PUT with correct path and data, returns MessageModel', () async {
      when(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.chatBasePath}/conversations/conv-1/messages/msg-1',
            data: any(named: 'data'),
          )).thenAnswer((_) async => {
            'data': {
              'id': 'msg-1',
              'role': 'USER',
              'content': 'Edited content',
              'tokenCount': 5,
              'hasRagContext': false,
              'createdAt': '2026-03-16T10:00:00Z',
            },
          });

      final result = await service.editMessage('conv-1', 'msg-1', 'Edited content');

      expect(result.id, 'msg-1');
      expect(result.content, 'Edited content');
      expect(result.role, 'USER');

      final captured = verify(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.chatBasePath}/conversations/conv-1/messages/msg-1',
            data: captureAny(named: 'data'),
          )).captured;

      final sentData = captured.first as Map<String, dynamic>;
      expect(sentData['content'], 'Edited content');
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.chatBasePath}/conversations/conv-1/messages/msg-1',
            data: any(named: 'data'),
          )).thenThrow(const ApiException(
        statusCode: 404,
        message: 'Message not found',
      ));

      expect(
        () => service.editMessage('conv-1', 'msg-1', 'New text'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // deleteMessage
  // ---------------------------------------------------------------------------
  group('deleteMessage', () {
    test('calls DELETE on correct path', () async {
      when(() => mockClient.delete(
            '${AppConstants.chatBasePath}/conversations/conv-1/messages/msg-2',
          )).thenAnswer((_) async {});

      await service.deleteMessage('conv-1', 'msg-2');

      verify(() => mockClient.delete(
            '${AppConstants.chatBasePath}/conversations/conv-1/messages/msg-2',
          )).called(1);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.delete(
            '${AppConstants.chatBasePath}/conversations/conv-1/messages/msg-2',
          )).thenThrow(const ApiException(
        statusCode: 404,
        message: 'Message not found',
      ));

      expect(
        () => service.deleteMessage('conv-1', 'msg-2'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // branchConversation
  // ---------------------------------------------------------------------------
  group('branchConversation', () {
    test('calls POST with correct path and returns ConversationModel', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.chatBasePath}/conversations/conv-1/branch/msg-3',
            data: any(named: 'data'),
          )).thenAnswer((_) async => {
            'data': {
              'id': 'conv-branch',
              'title': 'Branch of conversation',
              'isArchived': false,
              'messageCount': 3,
              'createdAt': '2026-03-16T14:00:00Z',
              'updatedAt': '2026-03-16T14:00:00Z',
            },
          });

      final result = await service.branchConversation('conv-1', 'msg-3');

      expect(result.id, 'conv-branch');
      expect(result.messageCount, 3);

      verify(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.chatBasePath}/conversations/conv-1/branch/msg-3',
            data: any(named: 'data'),
          )).called(1);
    });

    test('sends title in body when provided', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.chatBasePath}/conversations/conv-1/branch/msg-3',
            data: any(named: 'data'),
          )).thenAnswer((_) async => {
            'data': {
              'id': 'conv-branch-titled',
              'title': 'Custom Branch Title',
              'isArchived': false,
              'messageCount': 3,
            },
          });

      final result = await service.branchConversation(
        'conv-1',
        'msg-3',
        title: 'Custom Branch Title',
      );

      expect(result.title, 'Custom Branch Title');

      final captured = verify(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.chatBasePath}/conversations/conv-1/branch/msg-3',
            data: captureAny(named: 'data'),
          )).captured;

      final sentData = captured.first as Map<String, dynamic>;
      expect(sentData['title'], 'Custom Branch Title');
    });

    test('sends null data when title is omitted', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.chatBasePath}/conversations/conv-1/branch/msg-3',
            data: any(named: 'data'),
          )).thenAnswer((_) async => {
            'data': {
              'id': 'conv-branch-no-title',
              'title': null,
              'isArchived': false,
              'messageCount': 2,
            },
          });

      await service.branchConversation('conv-1', 'msg-3');

      final captured = verify(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.chatBasePath}/conversations/conv-1/branch/msg-3',
            data: captureAny(named: 'data'),
          )).captured;

      expect(captured.first, isNull);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.chatBasePath}/conversations/conv-1/branch/msg-3',
            data: any(named: 'data'),
          )).thenThrow(const ApiException(
        statusCode: 404,
        message: 'Message not found',
      ));

      expect(
        () => service.branchConversation('conv-1', 'msg-3'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ── Provider body tests ───────────────────────────────────────────────
  group('chatServiceProvider', () {
    test('creates ChatService from apiClientProvider', () {
      final mockClient = MockApiClient();
      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(mockClient)],
      );
      addTearDown(container.dispose);
      expect(container.read(chatServiceProvider), isA<ChatService>());
    });
  });

  group('conversationsProvider', () {
    test('returns conversations from service', () async {
      final mockClient = MockApiClient();
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.chatBasePath}/conversations',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': [
              {'id': 'conv-1', 'title': 'Test', 'lastMessageAt': '2026-03-16T12:00:00Z'},
            ],
          });
      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(mockClient)],
      );
      addTearDown(container.dispose);
      final convos = await container.read(conversationsProvider.future);
      expect(convos, hasLength(1));
    });
  });

  group('messagesProvider', () {
    test('returns messages for a conversation', () async {
      final mockClient = MockApiClient();
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.chatBasePath}/conversations/conv-1/messages',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': [
              {'id': 'm1', 'role': 'USER', 'content': 'Hello', 'hasRagContext': false},
            ],
          });
      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(mockClient)],
      );
      addTearDown(container.dispose);
      final msgs = await container.read(messagesProvider('conv-1').future);
      expect(msgs, hasLength(1));
    });
  });

  group('aiThinkingProvider', () {
    test('defaults to false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(aiThinkingProvider('conv-1')), isFalse);
    });
  });

  group('sidebarCollapsedProvider', () {
    test('defaults to false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(sidebarCollapsedProvider), isFalse);
    });
  });
}
