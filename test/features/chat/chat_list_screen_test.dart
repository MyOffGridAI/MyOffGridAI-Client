import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/auth/auth_state.dart';
import 'package:myoffgridai_client/core/models/conversation_model.dart';
import 'package:myoffgridai_client/core/models/user_model.dart';
import 'package:myoffgridai_client/core/services/chat_service.dart';
import 'package:myoffgridai_client/features/chat/chat_list_screen.dart';

class MockChatService extends Mock implements ChatService {}

void main() {
  late MockChatService mockService;

  setUp(() {
    mockService = MockChatService();
  });

  Widget buildScreen({UserModel? user}) {
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWith(() => _FakeAuthNotifier(user)),
        chatServiceProvider.overrideWithValue(mockService),
      ],
      child: const MaterialApp(home: ChatListScreen()),
    );
  }

  group('ChatListScreen', () {
    testWidgets('shows greeting with display name', (tester) async {
      final user = UserModel(
        id: '1',
        username: 'adam',
        displayName: 'Adam',
        role: 'ROLE_OWNER',
        isActive: true,
      );

      await tester.pumpWidget(buildScreen(user: user));
      await tester.pumpAndSettle();

      // Should contain the display name
      expect(find.textContaining('Adam'), findsOneWidget);
    });

    testWidgets('shows fallback greeting when no user', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Should show greeting with 'there' as fallback
      expect(find.textContaining('there'), findsOneWidget);
    });

    testWidgets('shows subtitle text', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('How can I help you today?'), findsOneWidget);
    });

    testWidgets('shows input field with hint', (tester) async {
      final user = UserModel(
        id: '1',
        username: 'adam',
        displayName: 'Adam',
        role: 'ROLE_OWNER',
        isActive: true,
      );

      await tester.pumpWidget(buildScreen(user: user));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Ask anything...'), findsOneWidget);
    });

    testWidgets('shows send button', (tester) async {
      final user = UserModel(
        id: '1',
        username: 'adam',
        displayName: 'Adam',
        role: 'ROLE_OWNER',
        isActive: true,
      );

      await tester.pumpWidget(buildScreen(user: user));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('shows time-appropriate greeting', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Should contain either Good morning, Good afternoon, or Good evening
      final greetingFinder = find.byWidgetPredicate((widget) {
        if (widget is Text && widget.data != null) {
          return widget.data!.contains('Good morning') ||
              widget.data!.contains('Good afternoon') ||
              widget.data!.contains('Good evening');
        }
        return false;
      });
      expect(greetingFinder, findsOneWidget);
    });

    testWidgets('does not send when input is empty', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      verifyNever(() => mockService.createConversation());
    });

    testWidgets('shows error on conversation creation failure',
        (tester) async {
      when(() => mockService.createConversation()).thenThrow(
        const ApiException(statusCode: 500, message: 'Server error'),
      );

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Hello AI');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      expect(find.text('Server error'), findsOneWidget);
    });

    testWidgets('shows greeting during auth loading state', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => _PendingAuthNotifier()),
          chatServiceProvider.overrideWithValue(mockService),
        ],
        child: const MaterialApp(home: ChatListScreen()),
      ));
      // Use pump() only -- pumpAndSettle won't work with never-completing future
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should show greeting without user name (just "Good xxx!")
      final greetingFinder = find.byWidgetPredicate((widget) {
        if (widget is Text && widget.data != null) {
          return widget.data!.contains('Good morning') ||
              widget.data!.contains('Good afternoon') ||
              widget.data!.contains('Good evening');
        }
        return false;
      });
      expect(greetingFinder, findsOneWidget);
    });

    testWidgets('shows greeting during auth error state', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => _ErrorAuthNotifier()),
          chatServiceProvider.overrideWithValue(mockService),
        ],
        child: const MaterialApp(home: ChatListScreen()),
      ));
      await tester.pumpAndSettle();

      // Should show greeting without user name
      final greetingFinder = find.byWidgetPredicate((widget) {
        if (widget is Text && widget.data != null) {
          return widget.data!.contains('Good morning') ||
              widget.data!.contains('Good afternoon') ||
              widget.data!.contains('Good evening');
        }
        return false;
      });
      expect(greetingFinder, findsOneWidget);
    });

    testWidgets('successful conversation creation navigates to chat',
        (tester) async {
      when(() => mockService.createConversation()).thenAnswer(
        (_) async => const ConversationModel(
          id: 'new-conv-1',
          isArchived: false,
          messageCount: 0,
        ),
      );

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const ChatListScreen(),
          ),
          GoRoute(
            path: '/chat/:id',
            builder: (_, state) =>
                Scaffold(body: Text('Chat ${state.pathParameters['id']}')),
          ),
        ],
      );

      await tester.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => _FakeAuthNotifier(null)),
          chatServiceProvider.overrideWithValue(mockService),
          conversationsProvider.overrideWith((ref) => []),
        ],
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Hello AI');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      expect(find.text('Chat new-conv-1'), findsOneWidget);
    });

    testWidgets('Enter key submits message', (tester) async {
      when(() => mockService.createConversation()).thenAnswer(
        (_) async => const ConversationModel(
          id: 'conv-enter',
          isArchived: false,
          messageCount: 0,
        ),
      );

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const ChatListScreen(),
          ),
          GoRoute(
            path: '/chat/:id',
            builder: (_, state) =>
                Scaffold(body: Text('Chat ${state.pathParameters['id']}')),
          ),
        ],
      );

      await tester.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => _FakeAuthNotifier(null)),
          chatServiceProvider.overrideWithValue(mockService),
          conversationsProvider.overrideWith((ref) => []),
        ],
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.text('Chat conv-enter'), findsOneWidget);
    });

    testWidgets('shows generic error on non-API exception', (tester) async {
      when(() => mockService.createConversation())
          .thenThrow(Exception('network down'));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Hello AI');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      expect(find.text('Failed to start conversation'), findsOneWidget);
    });
  });
}

class _FakeAuthNotifier extends AsyncNotifier<UserModel?>
    implements AuthNotifier {
  final UserModel? _user;
  _FakeAuthNotifier(this._user);

  @override
  Future<UserModel?> build() async => _user;

  @override
  Future<void> login(String username, String password) async {}

  @override
  Future<void> register({
    required String username,
    required String displayName,
    required String password,
    String? email,
  }) async {}

  @override
  Future<void> logout() async {}
}

class _PendingAuthNotifier extends AsyncNotifier<UserModel?>
    implements AuthNotifier {
  @override
  Future<UserModel?> build() {
    // Return a future that never completes to keep loading state
    return Completer<UserModel?>().future;
  }

  @override
  Future<void> login(String username, String password) async {}

  @override
  Future<void> register({
    required String username,
    required String displayName,
    required String password,
    String? email,
  }) async {}

  @override
  Future<void> logout() async {}
}

class _ErrorAuthNotifier extends AsyncNotifier<UserModel?>
    implements AuthNotifier {
  @override
  Future<UserModel?> build() async {
    throw Exception('auth error');
  }

  @override
  Future<void> login(String username, String password) async {}

  @override
  Future<void> register({
    required String username,
    required String displayName,
    required String password,
    String? email,
  }) async {}

  @override
  Future<void> logout() async {}
}
