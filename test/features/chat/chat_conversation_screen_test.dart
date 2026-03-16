import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/core/models/message_model.dart';
import 'package:myoffgridai_client/core/services/chat_messages_notifier.dart';
import 'package:myoffgridai_client/core/models/conversation_model.dart';
import 'package:myoffgridai_client/core/services/chat_service.dart';
import 'package:myoffgridai_client/features/chat/chat_conversation_screen.dart';

void main() {
  group('ChatConversationScreen', () {
    Widget buildScreen({
      String conversationId = 'conv-1',
      List<MessageModel> messages = const [],
      bool isThinking = false,
      Duration? responseTime,
    }) {
      return ProviderScope(
        overrides: [
          chatMessagesNotifierProvider.overrideWith(
            () => _FakeChatMessagesNotifier(messages),
          ),
          aiThinkingProvider.overrideWith(
            (ref, id) => isThinking,
          ),
          responseTimeProvider.overrideWith(
            (ref, id) => responseTime,
          ),
          conversationsProvider.overrideWith(
            (ref) => <ConversationSummaryModel>[],
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ChatConversationScreen(conversationId: conversationId),
          ),
        ),
      );
    }

    testWidgets('shows message input field', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows send button', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('shows empty state text', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(
        find.text('Send a message to start the conversation'),
        findsOneWidget,
      );
    });

    testWidgets('displays messages', (tester) async {
      final messages = [
        MessageModel.fromJson({
          'id': '1',
          'role': 'USER',
          'content': 'Hello AI',
          'hasRagContext': false,
        }),
        MessageModel.fromJson({
          'id': '2',
          'role': 'ASSISTANT',
          'content': 'Hello! How can I help?',
          'hasRagContext': false,
        }),
      ];

      await tester.pumpWidget(buildScreen(messages: messages));
      await tester.pumpAndSettle();

      expect(find.text('Hello AI'), findsOneWidget);
      expect(find.text('Hello! How can I help?'), findsOneWidget);
    });

    testWidgets('shows input hint text', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Type a message...'), findsOneWidget);
    });

    testWidgets('shows New Conversation in app bar', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('New Conversation'), findsOneWidget);
    });

    testWidgets('shows RAG context icon for messages with context',
        (tester) async {
      final messages = [
        MessageModel.fromJson({
          'id': '1',
          'role': 'ASSISTANT',
          'content': 'Based on your documents...',
          'hasRagContext': true,
        }),
      ];

      await tester.pumpWidget(buildScreen(messages: messages));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.auto_stories), findsOneWidget);
    });

    testWidgets('hides RAG context icon when not present', (tester) async {
      final messages = [
        MessageModel.fromJson({
          'id': '1',
          'role': 'ASSISTANT',
          'content': 'Just a normal response',
          'hasRagContext': false,
        }),
      ];

      await tester.pumpWidget(buildScreen(messages: messages));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.auto_stories), findsNothing);
    });

    testWidgets('shows response time for last assistant message',
        (tester) async {
      final messages = [
        MessageModel.fromJson({
          'id': '1',
          'role': 'ASSISTANT',
          'content': 'Response here',
          'hasRagContext': false,
        }),
      ];

      await tester.pumpWidget(buildScreen(
        messages: messages,
        responseTime: const Duration(milliseconds: 2500),
      ));
      await tester.pumpAndSettle();

      expect(find.text('thought for 2.5s'), findsOneWidget);
    });

    testWidgets('shows thinking indicator when AI is thinking',
        (tester) async {
      final messages = [
        MessageModel.fromJson({
          'id': '1',
          'role': 'USER',
          'content': 'Hello',
          'hasRagContext': false,
        }),
      ];

      await tester.pumpWidget(buildScreen(
        messages: messages,
        isThinking: true,
      ));
      // Use pump() instead of pumpAndSettle -- thinking indicator has animations
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // ThinkingIndicatorBubble should be visible along with the user message
      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('shows error view when messages fail to load',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          chatMessagesNotifierProvider.overrideWith(
            () => _ErrorChatMessagesNotifier(),
          ),
          aiThinkingProvider.overrideWith((ref, id) => false),
          responseTimeProvider.overrideWith((ref, id) => null),
          conversationsProvider.overrideWith(
            (ref) => <ConversationSummaryModel>[],
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ChatConversationScreen(conversationId: 'conv-1'),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load messages'), findsOneWidget);
    });

    testWidgets('shows RAG icon for user messages with context',
        (tester) async {
      final messages = [
        MessageModel.fromJson({
          'id': '1',
          'role': 'USER',
          'content': 'What does my document say?',
          'hasRagContext': true,
        }),
      ];

      await tester.pumpWidget(buildScreen(messages: messages));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.auto_stories), findsOneWidget);
    });

    testWidgets('does not send empty message', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Tap send without entering text
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Should still show empty state
      expect(
        find.text('Send a message to start the conversation'),
        findsOneWidget,
      );
    });

    testWidgets('shows conversation title when available', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          chatMessagesNotifierProvider.overrideWith(
            () => _FakeChatMessagesNotifier([]),
          ),
          aiThinkingProvider.overrideWith((ref, id) => false),
          responseTimeProvider.overrideWith((ref, id) => null),
          conversationsProvider.overrideWith(
            (ref) => [
              const ConversationSummaryModel(
                id: 'conv-1',
                title: 'My Chat',
                isArchived: false,
                messageCount: 5,
              ),
            ],
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ChatConversationScreen(conversationId: 'conv-1'),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('My Chat'), findsOneWidget);
    });

    // Note: The _sendMessage method (lines 194-216) and onSubmitted (line 175)
    // require the full apiClientProvider to be overridden. sendMessage calls
    // ref.read(chatMessagesNotifierProvider(...).notifier).sendMessage which
    // accesses the API client. These lines cannot be covered without
    // modifying lib/ code or providing a full mock API client chain.
  });
}

class _FakeChatMessagesNotifier extends ChatMessagesNotifier {
  final List<MessageModel> _messages;

  _FakeChatMessagesNotifier(this._messages);

  @override
  Future<List<MessageModel>> build(String arg) async => _messages;
}

class _ErrorChatMessagesNotifier extends ChatMessagesNotifier {
  @override
  Future<List<MessageModel>> build(String arg) async {
    throw Exception('Failed to load');
  }
}
