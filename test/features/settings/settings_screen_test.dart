import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/core/auth/auth_state.dart';
import 'package:myoffgridai_client/core/models/system_models.dart';
import 'package:myoffgridai_client/core/models/user_model.dart';
import 'package:myoffgridai_client/core/services/system_service.dart';
import 'package:myoffgridai_client/core/services/user_service.dart';
import 'package:myoffgridai_client/features/settings/settings_screen.dart';

void main() {
  group('SettingsScreen', () {
    Widget buildScreen({
      UserModel? user,
      List<UserModel> users = const [],
    }) {
      final effectiveUser = user ??
          UserModel.fromJson({
            'id': 'u1',
            'username': 'owner@test.com',
            'displayName': 'Owner',
            'role': 'ROLE_OWNER',
            'isActive': true,
          });

      return ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => _FakeAuthNotifier(effectiveUser)),
          usersListProvider.overrideWith((ref) => users),
          aiSettingsProvider.overrideWith((ref) => AiSettingsModel(
                modelName: 'test-model',
                temperature: 0.7,
                similarityThreshold: 0.45,
                memoryTopK: 5,
                ragMaxContextTokens: 2048,
                contextSize: 4096,
                contextMessageLimit: 20,
              )),
          storageSettingsProvider.overrideWith((ref) => StorageSettingsModel(
                knowledgeStoragePath: '/tmp/test',
                maxUploadSizeMb: 25,
                totalSpaceMb: 1024,
                usedSpaceMb: 256,
                freeSpaceMb: 768,
              )),
          ollamaModelsProvider.overrideWith((ref) => <OllamaModelInfoModel>[]),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      );
    }

    testWidgets('shows 4 tabs', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('General'), findsOneWidget);
      expect(find.text('Users'), findsOneWidget);
      expect(find.text('AI & Memory'), findsOneWidget);
      expect(find.text('File Storage'), findsOneWidget);
    });

    testWidgets('Users tab shows Register button for OWNER', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Tap Users tab
      await tester.tap(find.text('Users'));
      await tester.pumpAndSettle();

      expect(find.text('Register New User'), findsOneWidget);
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
    required String password,
    String? displayName,
    String? email,
  }) async {}

  @override
  Future<void> logout() async {}
}
