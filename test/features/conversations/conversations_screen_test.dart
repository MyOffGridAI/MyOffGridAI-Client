import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/core/models/conversation_model.dart';
import 'package:myoffgridai_client/core/services/chat_service.dart';
import 'package:myoffgridai_client/features/conversations/conversations_screen.dart';

class MockChatService extends Mock implements ChatService {}

void main() {
  late MockChatService mockChatService;

  setUp(() {
    mockChatService = MockChatService();
    registerFallbackValue('');
  });

  Widget buildScreen({
    List<ConversationSummaryModel> conversations = const [],
    List<ConversationSummaryModel> archivedConversations = const [],
  }) {
    final router = GoRouter(
      initialLocation: '/conversations',
      routes: [
        GoRoute(
          path: '/conversations',
          builder: (context, state) => const ConversationsScreen(),
        ),
        GoRoute(
          path: '/chat/:id',
          builder: (context, state) => Text('Chat ${state.pathParameters['id']}'),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        conversationsProvider.overrideWith((ref) => conversations),
        archivedConversationsProvider
            .overrideWith((ref) => archivedConversations),
        chatServiceProvider.overrideWithValue(mockChatService),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('ConversationsScreen - AppBar', () {
    testWidgets('shows Conversations title in AppBar', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Conversations'), findsOneWidget);
    });

    testWidgets('shows search icon in AppBar', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('tapping search icon shows search field', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('tapping close icon hides search field', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Open search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Close search
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Conversations'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });
  });

  group('ConversationsScreen - Tabs', () {
    testWidgets('shows Active and Archived tabs', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Archived'), findsOneWidget);
    });

    testWidgets('tabs are hidden during search', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      expect(find.text('Active'), findsNothing);
      expect(find.text('Archived'), findsNothing);
    });
  });

  group('ConversationsScreen - Active Tab', () {
    testWidgets('shows active conversations list', (tester) async {
      await tester.pumpWidget(buildScreen(
        conversations: [
          const ConversationSummaryModel(
            id: 'c1',
            title: 'Weather Chat',
            isArchived: false,
            messageCount: 3,
            lastMessagePreview: 'How is the weather?',
            updatedAt: '2026-03-16T10:00:00Z',
          ),
          const ConversationSummaryModel(
            id: 'c2',
            title: 'Solar Setup',
            isArchived: false,
            messageCount: 10,
          ),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Weather Chat'), findsOneWidget);
      expect(find.text('Solar Setup'), findsOneWidget);
      expect(find.text('3 messages'), findsOneWidget);
    });

    testWidgets('shows "No conversations yet" empty state', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('No conversations yet'), findsOneWidget);
    });

    testWidgets('shows "Untitled" for conversation without title',
        (tester) async {
      await tester.pumpWidget(buildScreen(
        conversations: [
          const ConversationSummaryModel(
            id: 'c1',
            title: null,
            isArchived: false,
            messageCount: 0,
          ),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Untitled'), findsOneWidget);
    });
  });

  group('ConversationsScreen - Archived Tab', () {
    testWidgets('shows archived conversations', (tester) async {
      await tester.pumpWidget(buildScreen(
        archivedConversations: [
          const ConversationSummaryModel(
            id: 'a1',
            title: 'Old Chat',
            isArchived: true,
            messageCount: 5,
          ),
        ],
      ));
      await tester.pumpAndSettle();

      // Navigate to Archived tab
      await tester.tap(find.text('Archived'));
      await tester.pumpAndSettle();

      expect(find.text('Old Chat'), findsOneWidget);
    });

    testWidgets('shows "No archived conversations" empty state',
        (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Archived'));
      await tester.pumpAndSettle();

      expect(find.text('No archived conversations'), findsOneWidget);
    });
  });

  group('ConversationsScreen - Popup Menu', () {
    testWidgets('active tile shows Rename, Archive, Delete options',
        (tester) async {
      await tester.pumpWidget(buildScreen(
        conversations: [
          const ConversationSummaryModel(
            id: 'c1',
            title: 'Test Chat',
            isArchived: false,
            messageCount: 1,
          ),
        ],
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('Rename'), findsOneWidget);
      expect(find.text('Archive'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('archived tile shows Rename and Delete but no Archive',
        (tester) async {
      await tester.pumpWidget(buildScreen(
        archivedConversations: [
          const ConversationSummaryModel(
            id: 'a1',
            title: 'Archived Chat',
            isArchived: true,
            messageCount: 2,
          ),
        ],
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Archived'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('Rename'), findsOneWidget);
      expect(find.text('Archive'), findsNothing);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('Rename opens rename dialog', (tester) async {
      await tester.pumpWidget(buildScreen(
        conversations: [
          const ConversationSummaryModel(
            id: 'c1',
            title: 'Old Title',
            isArchived: false,
            messageCount: 1,
          ),
        ],
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();

      expect(find.text('Rename conversation'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('Delete opens confirmation dialog', (tester) async {
      await tester.pumpWidget(buildScreen(
        conversations: [
          const ConversationSummaryModel(
            id: 'c1',
            title: 'Doomed Chat',
            isArchived: false,
            messageCount: 1,
          ),
        ],
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Conversation'), findsOneWidget);
      expect(
        find.text(
            'This will permanently delete this conversation and all its messages.'),
        findsOneWidget,
      );
    });
  });

  group('ConversationsScreen - Navigation', () {
    testWidgets('tapping a conversation tile navigates to /chat/{id}',
        (tester) async {
      await tester.pumpWidget(buildScreen(
        conversations: [
          const ConversationSummaryModel(
            id: 'c1',
            title: 'Tappable Chat',
            isArchived: false,
            messageCount: 5,
          ),
        ],
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tappable Chat'));
      await tester.pumpAndSettle();

      expect(find.text('Chat c1'), findsOneWidget);
    });
  });

  group('ConversationsScreen - Search', () {
    testWidgets('search shows initial empty state', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      expect(find.text('Search conversations'), findsOneWidget);
    });

    testWidgets('search calls searchConversations and displays results',
        (tester) async {
      when(() => mockChatService.searchConversations(any())).thenAnswer(
        (_) async => [
          const ConversationSummaryModel(
            id: 'r1',
            title: 'Found Chat',
            isArchived: false,
            messageCount: 3,
          ),
        ],
      );

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Found');
      // Wait for debounce
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('Found Chat'), findsOneWidget);
      verify(() => mockChatService.searchConversations('Found')).called(1);
    });

    testWidgets('search shows no results message', (tester) async {
      when(() => mockChatService.searchConversations(any()))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Nothing');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text("No results for 'Nothing'"), findsOneWidget);
    });
  });
}
