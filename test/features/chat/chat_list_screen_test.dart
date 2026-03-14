import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/core/models/conversation_model.dart';
import 'package:myoffgridai_client/core/services/chat_service.dart';
import 'package:myoffgridai_client/features/chat/chat_list_screen.dart';

void main() {
  group('ChatListScreen', () {
    Widget buildScreen({List<ConversationSummaryModel> conversations = const []}) {
      return ProviderScope(
        overrides: [
          conversationsProvider.overrideWith((ref) => conversations),
        ],
        child: const MaterialApp(home: ChatListScreen()),
      );
    }

    testWidgets('shows empty state when no conversations', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('No conversations yet'), findsOneWidget);
    });

    testWidgets('displays conversations list', (tester) async {
      final conversations = [
        ConversationSummaryModel.fromJson({
          'id': '1',
          'title': 'First Chat',
          'isArchived': false,
          'messageCount': 3,
          'updatedAt': '2026-03-14T10:00:00Z',
          'lastMessagePreview': 'Hello there',
        }),
        ConversationSummaryModel.fromJson({
          'id': '2',
          'title': 'Second Chat',
          'isArchived': false,
          'messageCount': 1,
        }),
      ];

      await tester.pumpWidget(buildScreen(conversations: conversations));
      await tester.pumpAndSettle();

      expect(find.text('First Chat'), findsOneWidget);
      expect(find.text('Second Chat'), findsOneWidget);
    });

    testWidgets('shows FAB to create new conversation', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('shows app bar title', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Conversations'), findsOneWidget);
    });
  });
}
