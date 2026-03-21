import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/core/auth/auth_state.dart';
import 'package:myoffgridai_client/core/models/library_models.dart';
import 'package:myoffgridai_client/core/models/user_model.dart';
import 'package:myoffgridai_client/core/services/library_service.dart';
import 'package:myoffgridai_client/features/books/gutenberg_top100_screen.dart';

class MockLibraryService extends Mock implements LibraryService {}

void main() {
  late MockLibraryService mockService;

  const ownerUser = UserModel(
    id: '1',
    username: 'owner',
    displayName: 'Owner',
    role: 'ROLE_OWNER',
    isActive: true,
  );

  const memberUser = UserModel(
    id: '2',
    username: 'member',
    displayName: 'Member',
    role: 'ROLE_MEMBER',
    isActive: true,
  );

  setUp(() {
    mockService = MockLibraryService();
  });

  Widget buildScreen({UserModel? user}) {
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWith(() => _FakeAuthNotifier(user)),
        libraryServiceProvider.overrideWithValue(mockService),
      ],
      child: const MaterialApp(home: GutenbergTop100Screen()),
    );
  }

  group('GutenbergTop100Screen', () {
    testWidgets('shows app bar title', (tester) async {
      when(() => mockService.browseGutenberg(
            sort: any(named: 'sort'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async =>
          const GutenbergSearchResultModel(count: 0, results: []));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Top 100 Gutenberg Books'), findsOneWidget);
    });

    testWidgets('shows empty state when no books', (tester) async {
      when(() => mockService.browseGutenberg(
            sort: any(named: 'sort'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async =>
          const GutenbergSearchResultModel(count: 0, results: []));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('No books available'), findsOneWidget);
    });

    testWidgets('shows book cards when data loaded', (tester) async {
      when(() => mockService.browseGutenberg(
            sort: any(named: 'sort'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => const GutenbergSearchResultModel(
            count: 1,
            results: [
              GutenbergBookModel(
                id: 1342,
                title: 'Pride and Prejudice',
                authors: ['Austen, Jane'],
                downloadCount: 50000,
              ),
            ],
          ));

      await tester.pumpWidget(buildScreen(user: ownerUser));
      await tester.pumpAndSettle();

      expect(find.text('Pride and Prejudice'), findsOneWidget);
      expect(find.text('Austen, Jane'), findsOneWidget);
    });

    testWidgets('shows import button for owner', (tester) async {
      when(() => mockService.browseGutenberg(
            sort: any(named: 'sort'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => const GutenbergSearchResultModel(
            count: 1,
            results: [
              GutenbergBookModel(id: 1, title: 'Test Book'),
            ],
          ));

      await tester.pumpWidget(buildScreen(user: ownerUser));
      await tester.pumpAndSettle();

      expect(find.text('Import'), findsOneWidget);
    });

    testWidgets('hides import button for member', (tester) async {
      when(() => mockService.browseGutenberg(
            sort: any(named: 'sort'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => const GutenbergSearchResultModel(
            count: 1,
            results: [
              GutenbergBookModel(id: 1, title: 'Test Book'),
            ],
          ));

      await tester.pumpWidget(buildScreen(user: memberUser));
      await tester.pumpAndSettle();

      expect(find.text('Import'), findsNothing);
    });

    testWidgets('shows error state with retry', (tester) async {
      when(() => mockService.browseGutenberg(
            sort: any(named: 'sort'),
            limit: any(named: 'limit'),
          )).thenThrow(Exception('Network error'));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Load Failed'), findsOneWidget);
    });

    testWidgets('tapping card opens detail bottom sheet', (tester) async {
      when(() => mockService.browseGutenberg(
            sort: any(named: 'sort'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => const GutenbergSearchResultModel(
            count: 1,
            results: [
              GutenbergBookModel(
                id: 1342,
                title: 'Pride and Prejudice',
                authors: ['Austen, Jane'],
                subjects: ['Fiction', 'Romance'],
                downloadCount: 50000,
              ),
            ],
          ));

      await tester.pumpWidget(buildScreen(user: ownerUser));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pride and Prejudice'));
      await tester.pumpAndSettle();

      expect(find.text('Subjects'), findsOneWidget);
      expect(find.text('Import to Library'), findsOneWidget);
    });

    testWidgets('import calls importGutenbergBook', (tester) async {
      when(() => mockService.browseGutenberg(
            sort: any(named: 'sort'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => const GutenbergSearchResultModel(
            count: 1,
            results: [
              GutenbergBookModel(id: 42, title: 'Importable Book'),
            ],
          ));
      when(() => mockService.importGutenbergBook(42))
          .thenAnswer((_) async => const EbookModel(
                id: 'e-new',
                title: 'Importable Book',
                format: 'EPUB',
                fileSizeBytes: 1024,
              ));

      await tester.pumpWidget(buildScreen(user: ownerUser));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Import'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Import'));
      await tester.pumpAndSettle();

      verify(() => mockService.importGutenbergBook(42)).called(1);
    });

    testWidgets('fetches with limit 100', (tester) async {
      when(() => mockService.browseGutenberg(
            sort: any(named: 'sort'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async =>
          const GutenbergSearchResultModel(count: 0, results: []));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      verify(() => mockService.browseGutenberg(
            sort: 'popular',
            limit: 100,
          )).called(1);
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
