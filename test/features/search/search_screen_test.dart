import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/core/models/conversation_model.dart';
import 'package:myoffgridai_client/core/models/knowledge_document_model.dart';
import 'package:myoffgridai_client/core/models/memory_model.dart';
import 'package:myoffgridai_client/core/services/chat_service.dart';
import 'package:myoffgridai_client/core/services/knowledge_service.dart';
import 'package:myoffgridai_client/core/services/memory_service.dart';
import 'package:myoffgridai_client/features/search/search_screen.dart';

class MockChatService extends Mock implements ChatService {}

class MockMemoryService extends Mock implements MemoryService {}

class MockKnowledgeService extends Mock implements KnowledgeService {}

void main() {
  late MockChatService mockChatService;
  late MockMemoryService mockMemoryService;
  late MockKnowledgeService mockKnowledgeService;

  setUp(() {
    mockChatService = MockChatService();
    mockMemoryService = MockMemoryService();
    mockKnowledgeService = MockKnowledgeService();
  });

  Widget buildScreen() {
    final router = GoRouter(
      initialLocation: '/search',
      routes: [
        GoRoute(
          path: '/search',
          builder: (context, state) => const SearchScreen(),
        ),
        GoRoute(
          path: '/chat/:id',
          builder: (context, state) => const Scaffold(body: Text('Chat')),
        ),
        GoRoute(
          path: '/knowledge/:id',
          builder: (context, state) =>
              const Scaffold(body: Text('Knowledge')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        chatServiceProvider.overrideWithValue(mockChatService),
        memoryServiceProvider.overrideWithValue(mockMemoryService),
        knowledgeServiceProvider.overrideWithValue(mockKnowledgeService),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('SearchScreen', () {
    testWidgets('renders search bar with autofocus', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(
        find.text('Search conversations, memories, knowledge...'),
        findsOneWidget,
      );
    });

    testWidgets('shows three tabs', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Conversations'), findsOneWidget);
      expect(find.text('Memories'), findsOneWidget);
      expect(find.text('Knowledge'), findsOneWidget);
    });

    testWidgets('shows "Start typing to search" initially', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Start typing to search'), findsOneWidget);
    });

    testWidgets('shows progress indicator while searching', (tester) async {
      // Use a Completer to keep the search pending
      final conversationCompleter =
          Completer<List<ConversationSummaryModel>>();
      final memoryCompleter = Completer<List<MemorySearchResultModel>>();
      final knowledgeCompleter =
          Completer<List<KnowledgeSearchResultModel>>();

      when(() => mockChatService.searchConversations(any()))
          .thenAnswer((_) => conversationCompleter.future);
      when(() => mockMemoryService.search(any()))
          .thenAnswer((_) => memoryCompleter.future);
      when(() => mockKnowledgeService.search(any()))
          .thenAnswer((_) => knowledgeCompleter.future);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Type a query
      await tester.enterText(find.byType(TextField), 'test query');
      // Wait for debounce (300ms)
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete the searches to clean up
      conversationCompleter.complete([]);
      memoryCompleter.complete([]);
      knowledgeCompleter.complete([]);
      await tester.pump();
    });

    testWidgets('shows search results after search completes',
        (tester) async {
      when(() => mockChatService.searchConversations(any()))
          .thenAnswer((_) async => [
                const ConversationSummaryModel(
                  id: 'c1',
                  title: 'Test Conversation',
                  isArchived: false,
                  messageCount: 5,
                  lastMessagePreview: 'Hello world',
                  updatedAt: '2026-03-16T10:00:00Z',
                ),
              ]);
      when(() => mockMemoryService.search(any()))
          .thenAnswer((_) async => []);
      when(() => mockKnowledgeService.search(any()))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('Test Conversation'), findsOneWidget);
      expect(find.text('Hello world'), findsOneWidget);
    });

    testWidgets('shows empty state for conversations tab', (tester) async {
      when(() => mockChatService.searchConversations(any()))
          .thenAnswer((_) async => []);
      when(() => mockMemoryService.search(any()))
          .thenAnswer((_) async => []);
      when(() => mockKnowledgeService.search(any()))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'xyz');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('No matching conversations'), findsOneWidget);
    });

    testWidgets('shows memory results in memories tab', (tester) async {
      when(() => mockChatService.searchConversations(any()))
          .thenAnswer((_) async => []);
      when(() => mockMemoryService.search(any()))
          .thenAnswer((_) async => [
                const MemorySearchResultModel(
                  memory: MemoryModel(
                    id: 'm1',
                    content: 'User prefers dark mode',
                    importance: 'HIGH',
                    tags: 'preferences,ui',
                    accessCount: 3,
                  ),
                  similarityScore: 0.85,
                ),
              ]);
      when(() => mockKnowledgeService.search(any()))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'dark mode');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Tap Memories tab
      await tester.tap(find.text('Memories'));
      await tester.pumpAndSettle();

      expect(find.text('User prefers dark mode'), findsOneWidget);
      expect(find.textContaining('0.85'), findsOneWidget);
    });

    testWidgets('shows knowledge results in knowledge tab', (tester) async {
      when(() => mockChatService.searchConversations(any()))
          .thenAnswer((_) async => []);
      when(() => mockMemoryService.search(any()))
          .thenAnswer((_) async => []);
      when(() => mockKnowledgeService.search(any()))
          .thenAnswer((_) async => [
                const KnowledgeSearchResultModel(
                  chunkId: 'ch1',
                  documentId: 'doc1',
                  documentName: 'Solar Panel Manual',
                  content: 'Panel installation instructions...',
                  chunkIndex: 0,
                  similarityScore: 0.92,
                ),
              ]);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'solar');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Tap Knowledge tab
      await tester.tap(find.text('Knowledge'));
      await tester.pumpAndSettle();

      expect(find.text('Solar Panel Manual'), findsOneWidget);
      expect(find.text('Panel installation instructions...'), findsOneWidget);
      expect(find.textContaining('0.92'), findsOneWidget);
    });

    testWidgets('shows empty state for memories tab', (tester) async {
      when(() => mockChatService.searchConversations(any()))
          .thenAnswer((_) async => []);
      when(() => mockMemoryService.search(any()))
          .thenAnswer((_) async => []);
      when(() => mockKnowledgeService.search(any()))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'nothing');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Memories'));
      await tester.pumpAndSettle();

      expect(find.text('No matching memories'), findsOneWidget);
    });

    testWidgets('shows empty state for knowledge tab', (tester) async {
      when(() => mockChatService.searchConversations(any()))
          .thenAnswer((_) async => []);
      when(() => mockMemoryService.search(any()))
          .thenAnswer((_) async => []);
      when(() => mockKnowledgeService.search(any()))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'xyz');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Knowledge'));
      await tester.pumpAndSettle();

      expect(find.text('No matching knowledge'), findsOneWidget);
    });

    testWidgets('clears results when query is cleared', (tester) async {
      when(() => mockChatService.searchConversations(any()))
          .thenAnswer((_) async => [
                const ConversationSummaryModel(
                  id: 'c1',
                  title: 'Result',
                  isArchived: false,
                  messageCount: 1,
                ),
              ]);
      when(() => mockMemoryService.search(any()))
          .thenAnswer((_) async => []);
      when(() => mockKnowledgeService.search(any()))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('Result'), findsOneWidget);

      // Clear the query
      await tester.enterText(find.byType(TextField), '');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('Start typing to search'), findsOneWidget);
    });

    testWidgets('navigates to chat on conversation tap', (tester) async {
      when(() => mockChatService.searchConversations(any()))
          .thenAnswer((_) async => [
                const ConversationSummaryModel(
                  id: 'c1',
                  title: 'Test Conversation',
                  isArchived: false,
                  messageCount: 5,
                  lastMessagePreview: 'Hello world',
                  updatedAt: '2026-03-16T10:00:00Z',
                ),
              ]);
      when(() => mockMemoryService.search(any()))
          .thenAnswer((_) async => []);
      when(() => mockKnowledgeService.search(any()))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Test Conversation'));
      await tester.pumpAndSettle();

      // Should navigate to /chat/c1
      expect(find.text('Chat'), findsOneWidget);
    });

    testWidgets('navigates to knowledge on knowledge result tap',
        (tester) async {
      when(() => mockChatService.searchConversations(any()))
          .thenAnswer((_) async => []);
      when(() => mockMemoryService.search(any()))
          .thenAnswer((_) async => []);
      when(() => mockKnowledgeService.search(any()))
          .thenAnswer((_) async => [
                const KnowledgeSearchResultModel(
                  chunkId: 'ch1',
                  documentId: 'doc1',
                  documentName: 'Solar Panel Manual',
                  content: 'Panel installation instructions...',
                  chunkIndex: 0,
                  similarityScore: 0.92,
                ),
              ]);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'solar');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Tap Knowledge tab
      await tester.tap(find.text('Knowledge'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Solar Panel Manual'));
      await tester.pumpAndSettle();

      // Should navigate to /knowledge/doc1
      expect(find.text('Knowledge'), findsOneWidget);
    });

    testWidgets('handles search error gracefully', (tester) async {
      when(() => mockChatService.searchConversations(any()))
          .thenThrow(Exception('Network error'));
      when(() => mockMemoryService.search(any()))
          .thenAnswer((_) async => []);
      when(() => mockKnowledgeService.search(any()))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Should not crash — shows empty results or start typing
      expect(find.byType(SearchScreen), findsOneWidget);
    });
  });
}
