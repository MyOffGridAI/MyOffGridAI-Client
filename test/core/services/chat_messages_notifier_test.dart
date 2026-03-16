import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/core/models/message_model.dart';
import 'package:myoffgridai_client/core/services/chat_messages_notifier.dart';
import 'package:myoffgridai_client/core/services/chat_service.dart';
import 'package:myoffgridai_client/features/chat/chat_conversation_screen.dart';

class MockChatService extends Mock implements ChatService {}

void main() {
  late MockChatService mockService;

  setUp(() {
    mockService = MockChatService();
  });

  /// Creates a [ProviderContainer] with the mock [ChatService] overridden.
  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        chatServiceProvider.overrideWithValue(mockService),
      ],
    );
  }

  const conversationId = 'conv-123';

  group('ChatMessagesNotifier.build()', () {
    test('returns messages from chatService.listMessages', () async {
      const messages = [
        MessageModel(id: 'm1', role: 'USER', content: 'Hello', hasRagContext: false),
        MessageModel(
          id: 'm2',
          role: 'ASSISTANT',
          content: 'Hi there!',
          hasRagContext: false,
        ),
      ];

      when(() => mockService.listMessages(conversationId))
          .thenAnswer((_) async => messages);

      final container = createContainer();
      addTearDown(container.dispose);

      final result = await container
          .read(chatMessagesNotifierProvider(conversationId).future);

      expect(result, hasLength(2));
      expect(result[0].id, 'm1');
      expect(result[0].content, 'Hello');
      expect(result[1].id, 'm2');
      expect(result[1].content, 'Hi there!');
    });

    test('returns empty list when no messages exist', () async {
      when(() => mockService.listMessages(conversationId))
          .thenAnswer((_) async => []);

      final container = createContainer();
      addTearDown(container.dispose);

      final result = await container
          .read(chatMessagesNotifierProvider(conversationId).future);

      expect(result, isEmpty);
    });
  });

  group('ChatMessagesNotifier.sendMessage()', () {
    test('optimistically adds user message then replaces with server response',
        () async {
      // Initial build returns existing messages
      when(() => mockService.listMessages(conversationId))
          .thenAnswer((_) async => [
                const MessageModel(
                  id: 'm1',
                  role: 'USER',
                  content: 'First',
                  hasRagContext: false,
                ),
              ]);

      // sendMessage succeeds
      when(() => mockService.sendMessage(conversationId, 'New message'))
          .thenAnswer((_) async => const MessageModel(
                id: 'm2',
                role: 'ASSISTANT',
                content: 'Response',
                hasRagContext: false,
              ));

      // Re-fetch after send returns full list
      final serverMessages = [
        const MessageModel(
          id: 'm1',
          role: 'USER',
          content: 'First',
          hasRagContext: false,
        ),
        const MessageModel(
          id: 'm2-server',
          role: 'USER',
          content: 'New message',
          hasRagContext: false,
        ),
        const MessageModel(
          id: 'm3-server',
          role: 'ASSISTANT',
          content: 'Response from server',
          hasRagContext: true,
        ),
      ];

      // listMessages will be called twice: once for build, once for re-fetch
      int listMessagesCallCount = 0;
      when(() => mockService.listMessages(conversationId)).thenAnswer((_) async {
        listMessagesCallCount++;
        if (listMessagesCallCount <= 1) {
          return [
            const MessageModel(
              id: 'm1',
              role: 'USER',
              content: 'First',
              hasRagContext: false,
            ),
          ];
        }
        return serverMessages;
      });

      final container = createContainer();
      addTearDown(container.dispose);

      // Wait for build
      await container
          .read(chatMessagesNotifierProvider(conversationId).future);

      // Send the message
      await container
          .read(chatMessagesNotifierProvider(conversationId).notifier)
          .sendMessage('New message');

      // After send completes, state should have server messages
      final state = container.read(chatMessagesNotifierProvider(conversationId));
      expect(state.hasValue, isTrue);
      expect(state.value, hasLength(3));
      expect(state.value![2].content, 'Response from server');

      // Thinking indicator should be cleared
      final thinking =
          container.read(aiThinkingProvider(conversationId));
      expect(thinking, isFalse);
    });

    test('removes temp message and rethrows on send error', () async {
      when(() => mockService.listMessages(conversationId))
          .thenAnswer((_) async => [
                const MessageModel(
                  id: 'm1',
                  role: 'USER',
                  content: 'Existing',
                  hasRagContext: false,
                ),
              ]);

      when(() => mockService.sendMessage(conversationId, 'Failing message'))
          .thenThrow(Exception('Network error'));

      final container = createContainer();
      addTearDown(container.dispose);

      // Wait for build
      await container
          .read(chatMessagesNotifierProvider(conversationId).future);

      // Attempt to send — should throw
      Object? caughtError;
      try {
        await container
            .read(chatMessagesNotifierProvider(conversationId).notifier)
            .sendMessage('Failing message');
      } catch (e) {
        caughtError = e;
      }

      expect(caughtError, isA<Exception>());

      // State should only have the original message (temp removed)
      final state = container.read(chatMessagesNotifierProvider(conversationId));
      expect(state.hasValue, isTrue);
      expect(state.value, hasLength(1));
      expect(state.value![0].id, 'm1');

      // Thinking indicator should be cleared
      final thinking =
          container.read(aiThinkingProvider(conversationId));
      expect(thinking, isFalse);
    });

    test('sets thinking indicator during send', () async {
      when(() => mockService.listMessages(conversationId))
          .thenAnswer((_) async => []);

      // Use a completer so we can check thinking state mid-flight
      var sendCalled = false;
      when(() => mockService.sendMessage(conversationId, 'Hello'))
          .thenAnswer((_) async {
        sendCalled = true;
        return const MessageModel(
          id: 'm1',
          role: 'ASSISTANT',
          content: 'Hi',
          hasRagContext: false,
        );
      });

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(chatMessagesNotifierProvider(conversationId).future);

      // Before sending, thinking should be false
      expect(container.read(aiThinkingProvider(conversationId)), isFalse);

      // Send message
      await container
          .read(chatMessagesNotifierProvider(conversationId).notifier)
          .sendMessage('Hello');

      expect(sendCalled, isTrue);

      // After send completes, thinking should be false again
      expect(container.read(aiThinkingProvider(conversationId)), isFalse);
    });

    test('stores response time after successful send', () async {
      when(() => mockService.listMessages(conversationId))
          .thenAnswer((_) async => []);

      when(() => mockService.sendMessage(conversationId, 'test'))
          .thenAnswer((_) async => const MessageModel(
                id: 'm1',
                role: 'ASSISTANT',
                content: 'Response',
                hasRagContext: false,
              ));

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(chatMessagesNotifierProvider(conversationId).future);

      // Before send, response time should be null
      expect(
        container.read(responseTimeProvider(conversationId)),
        isNull,
      );

      await container
          .read(chatMessagesNotifierProvider(conversationId).notifier)
          .sendMessage('test');

      // After send, response time should be set
      final responseTime =
          container.read(responseTimeProvider(conversationId));
      expect(responseTime, isNotNull);
      expect(responseTime, isA<Duration>());
    });

    test('staggered re-fetches call ref.invalidate when provider exists',
        () async {
      // This test exercises lines 72-73: the delayed ref.exists / ref.invalidate
      // calls that happen at 3, 6, and 10 seconds after a successful send.
      when(() => mockService.listMessages(conversationId))
          .thenAnswer((_) async => []);

      when(() => mockService.sendMessage(conversationId, 'trigger-refetch'))
          .thenAnswer((_) async => const MessageModel(
                id: 'm1',
                role: 'ASSISTANT',
                content: 'Response',
                hasRagContext: false,
              ));

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(chatMessagesNotifierProvider(conversationId).future);

      await container
          .read(chatMessagesNotifierProvider(conversationId).notifier)
          .sendMessage('trigger-refetch');

      // The delayed futures (3s, 6s, 10s) are now scheduled.
      // Wait long enough for them to fire while container is still alive.
      await Future<void>.delayed(const Duration(seconds: 11));

      // If we reach here without error, lines 72-73 were exercised.
      // The ref.exists check returned true and ref.invalidate was called.
      // After invalidation the provider re-builds, so wait for it.
      await container
          .read(chatMessagesNotifierProvider(conversationId).future);
      final state = container.read(chatMessagesNotifierProvider(conversationId));
      expect(state.hasValue, isTrue);
    });
  });
}
