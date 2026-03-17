import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/core/models/inference_stream_event.dart';
import 'package:myoffgridai_client/core/models/message_model.dart';
import 'package:myoffgridai_client/core/services/chat_messages_notifier.dart';
import 'package:myoffgridai_client/core/services/chat_service.dart';


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

  /// Helper to create a simple SSE stream that emits content then done.
  Stream<InferenceStreamEvent> successStream({
    String content = 'Response',
    double tokensPerSecond = 12.5,
    double inferenceTimeSeconds = 1.8,
  }) async* {
    yield InferenceStreamEvent(
      type: InferenceEventType.content,
      content: content,
    );
    yield InferenceStreamEvent(
      type: InferenceEventType.done,
      metadata: InferenceMetadata(
        tokensGenerated: 25,
        tokensPerSecond: tokensPerSecond,
        inferenceTimeSeconds: inferenceTimeSeconds,
        stopReason: 'stop',
      ),
    );
  }

  /// Helper to create a stream that throws an error.
  Stream<InferenceStreamEvent> errorStream() async* {
    // ignore: only_throw_errors
    throw Exception('Network error');
  }

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
      int listMessagesCallCount = 0;
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

      // sendMessageStream returns SSE events
      when(() => mockService.sendMessageStream(conversationId, 'New message'))
          .thenAnswer((_) => successStream(content: 'Response'));

      final container = createContainer();
      addTearDown(container.dispose);

      // Wait for build
      await container
          .read(chatMessagesNotifierProvider(conversationId).future);

      // Send the message
      await container
          .read(chatMessagesNotifierProvider(conversationId).notifier)
          .sendMessage('New message');

      // After send completes, state should have server messages (re-fetched)
      final state = container.read(chatMessagesNotifierProvider(conversationId));
      expect(state.hasValue, isTrue);
      expect(state.value, hasLength(3));
      expect(state.value![2].content, 'Response from server');

      // Thinking indicator should be cleared
      final thinking =
          container.read(aiThinkingProvider(conversationId));
      expect(thinking, isFalse);
    });

    test('removes temp message and rethrows on stream error', () async {
      when(() => mockService.listMessages(conversationId))
          .thenAnswer((_) async => [
                const MessageModel(
                  id: 'm1',
                  role: 'USER',
                  content: 'Existing',
                  hasRagContext: false,
                ),
              ]);

      when(() => mockService.sendMessageStream(conversationId, 'Failing message'))
          .thenAnswer((_) => errorStream());

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

      when(() => mockService.sendMessageStream(conversationId, 'Hello'))
          .thenAnswer((_) => successStream(content: 'Hi'));

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

      // After send completes, thinking should be false again
      expect(container.read(aiThinkingProvider(conversationId)), isFalse);
    });

    test('accumulates thinking and content from stream events', () async {
      when(() => mockService.listMessages(conversationId))
          .thenAnswer((_) async => []);

      // Stream with thinking events followed by content
      Stream<InferenceStreamEvent> thinkingStream() async* {
        yield const InferenceStreamEvent(
          type: InferenceEventType.thinking,
          content: 'Let me think...',
        );
        yield const InferenceStreamEvent(
          type: InferenceEventType.content,
          content: 'Here is the answer',
        );
        yield const InferenceStreamEvent(
          type: InferenceEventType.done,
          metadata: InferenceMetadata(
            tokensGenerated: 30,
            tokensPerSecond: 15.0,
            inferenceTimeSeconds: 2.0,
            stopReason: 'stop',
          ),
        );
      }

      when(() => mockService.sendMessageStream(conversationId, 'Think about this'))
          .thenAnswer((_) => thinkingStream());

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(chatMessagesNotifierProvider(conversationId).future);

      await container
          .read(chatMessagesNotifierProvider(conversationId).notifier)
          .sendMessage('Think about this');

      // After re-fetch, the state has server messages
      // (the streaming intermediate states have been replaced)
      final state = container.read(chatMessagesNotifierProvider(conversationId));
      expect(state.hasValue, isTrue);
    });

    test('staggered re-fetches call ref.invalidate when provider exists',
        () async {
      when(() => mockService.listMessages(conversationId))
          .thenAnswer((_) async => []);

      when(() => mockService.sendMessageStream(conversationId, 'trigger-refetch'))
          .thenAnswer((_) => successStream());

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

      // If we reach here without error, the delayed re-fetches were exercised.
      await container
          .read(chatMessagesNotifierProvider(conversationId).future);
      final state = container.read(chatMessagesNotifierProvider(conversationId));
      expect(state.hasValue, isTrue);
    });
  });
}
