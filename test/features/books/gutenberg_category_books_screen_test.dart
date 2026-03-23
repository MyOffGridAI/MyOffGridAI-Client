import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/core/auth/auth_state.dart';
import 'package:myoffgridai_client/core/models/library_models.dart';
import 'package:myoffgridai_client/core/models/user_model.dart';
import 'package:myoffgridai_client/core/services/library_service.dart';
import 'package:myoffgridai_client/features/books/gutenberg_category_books_screen.dart';

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

  Widget buildScreen({
    String categoryName = 'Fiction',
    UserModel? user,
  }) {
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWith(() => _FakeAuthNotifier(user)),
        libraryServiceProvider.overrideWithValue(mockService),
      ],
      child: MaterialApp(
        home: GutenbergCategoryBooksScreen(categoryName: categoryName),
      ),
    );
  }

  group('GutenbergCategoryBooksScreen', () {
    testWidgets('shows category name in app bar', (tester) async {
      when(() => mockService.searchGutenberg(
            any(),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async =>
          const GutenbergSearchResultModel(count: 0, results: []));

      await tester.pumpWidget(buildScreen(categoryName: 'Science Fiction'));
      await tester.pumpAndSettle();

      expect(find.text('Science Fiction'), findsOneWidget);
    });

    testWidgets('shows empty state when no books found', (tester) async {
      when(() => mockService.searchGutenberg(
            any(),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async =>
          const GutenbergSearchResultModel(count: 0, results: []));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('No books found'), findsOneWidget);
    });

    testWidgets('shows book cards when data loaded', (tester) async {
      when(() => mockService.searchGutenberg(
            any(),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => const GutenbergSearchResultModel(
            count: 1,
            results: [
              GutenbergBookModel(
                id: 84,
                title: 'Frankenstein',
                authors: ['Shelley, Mary'],
                downloadCount: 30000,
              ),
            ],
          ));

      await tester.pumpWidget(buildScreen(user: ownerUser));
      await tester.pumpAndSettle();

      expect(find.text('Frankenstein'), findsOneWidget);
      expect(find.text('Shelley, Mary'), findsOneWidget);
    });

    testWidgets('shows import button for owner', (tester) async {
      when(() => mockService.searchGutenberg(
            any(),
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
      when(() => mockService.searchGutenberg(
            any(),
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
      when(() => mockService.searchGutenberg(
            any(),
            limit: any(named: 'limit'),
          )).thenThrow(Exception('Network error'));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Load Failed'), findsOneWidget);
    });

    testWidgets('tapping card opens detail bottom sheet', (tester) async {
      when(() => mockService.searchGutenberg(
            any(),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => const GutenbergSearchResultModel(
            count: 1,
            results: [
              GutenbergBookModel(
                id: 84,
                title: 'Frankenstein',
                authors: ['Shelley, Mary'],
                subjects: ['Horror', 'Science Fiction'],
                downloadCount: 30000,
              ),
            ],
          ));

      await tester.pumpWidget(buildScreen(user: ownerUser));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Frankenstein'));
      await tester.pumpAndSettle();

      expect(find.text('Subjects'), findsOneWidget);
      expect(find.text('Import to Library'), findsOneWidget);
    });

    testWidgets('searches with category name and limit 50', (tester) async {
      when(() => mockService.searchGutenberg(
            any(),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async =>
          const GutenbergSearchResultModel(count: 0, results: []));

      await tester.pumpWidget(buildScreen(categoryName: 'Poetry'));
      await tester.pumpAndSettle();

      verify(() => mockService.searchGutenberg(
            'Poetry',
            limit: 50,
          )).called(1);
    });

    testWidgets('import calls importGutenbergBook', (tester) async {
      when(() => mockService.searchGutenberg(
            any(),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => const GutenbergSearchResultModel(
            count: 1,
            results: [
              GutenbergBookModel(id: 84, title: 'Frankenstein'),
            ],
          ));
      when(() => mockService.importGutenbergBook(84))
          .thenAnswer((_) async => const EbookModel(
                id: 'e-new',
                title: 'Frankenstein',
                format: 'EPUB',
                fileSizeBytes: 2048,
              ));

      await tester.pumpWidget(buildScreen(user: ownerUser));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Import'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Import'));
      await tester.pumpAndSettle();

      verify(() => mockService.importGutenbergBook(84)).called(1);
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

  @override
  Future<UserModel?> loginWithBiometric() async => null;
}
