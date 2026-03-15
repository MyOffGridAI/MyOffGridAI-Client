import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/core/auth/auth_state.dart';
import 'package:myoffgridai_client/core/models/user_model.dart';
import 'package:myoffgridai_client/features/chat/chat_list_screen.dart';

void main() {
  group('ChatListScreen', () {
    Widget buildScreen({UserModel? user}) {
      return ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => _FakeAuthNotifier(user)),
        ],
        child: const MaterialApp(home: ChatListScreen()),
      );
    }

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
