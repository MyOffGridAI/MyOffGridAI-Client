import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/core/models/message_model.dart';
import 'package:myoffgridai_client/core/services/chat_messages_notifier.dart';
import 'package:myoffgridai_client/features/chat/chat_conversation_screen.dart';

void main() {
  group('ChatConversationScreen', () {
    Widget buildScreen({
      String conversationId = 'conv-1',
      List<MessageModel> messages = const [],
    }) {
      return ProviderScope(
        overrides: [
          chatMessagesNotifierProvider.overrideWith(
            () => _FakeChatMessagesNotifier(messages),
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

    testWidgets('shows empty state text', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(
        find.text('Send a message to start the conversation'),
        findsOneWidget,
      );
    });
  });
}

class _FakeChatMessagesNotifier extends ChatMessagesNotifier {
  final List<MessageModel> _messages;

  _FakeChatMessagesNotifier(this._messages);

  @override
  Future<List<MessageModel>> build(String arg) async => _messages;
}
