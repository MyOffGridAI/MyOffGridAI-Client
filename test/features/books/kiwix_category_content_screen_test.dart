import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/core/auth/auth_state.dart';
import 'package:myoffgridai_client/core/models/library_models.dart';
import 'package:myoffgridai_client/core/models/user_model.dart';
import 'package:myoffgridai_client/core/services/library_service.dart';
import 'package:myoffgridai_client/features/books/kiwix_category_content_screen.dart';

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
    String categoryName = 'wikipedia',
    UserModel? user,
  }) {
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWith(() => _FakeAuthNotifier(user)),
        libraryServiceProvider.overrideWithValue(mockService),
      ],
      child: MaterialApp(
        home: KiwixCategoryContentScreen(categoryName: categoryName),
      ),
    );
  }

  group('KiwixCategoryContentScreen', () {
    testWidgets('shows category name in app bar', (tester) async {
      when(() => mockService.browseKiwixCatalog(
            lang: any(named: 'lang'),
            category: any(named: 'category'),
            count: any(named: 'count'),
            start: any(named: 'start'),
          )).thenAnswer((_) async =>
          const KiwixCatalogSearchResultModel(totalCount: 0, entries: []));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Wikipedia'), findsOneWidget);
    });

    testWidgets('formats multi-word category name', (tester) async {
      when(() => mockService.browseKiwixCatalog(
            lang: any(named: 'lang'),
            category: any(named: 'category'),
            count: any(named: 'count'),
            start: any(named: 'start'),
          )).thenAnswer((_) async =>
          const KiwixCatalogSearchResultModel(totalCount: 0, entries: []));

      await tester.pumpWidget(
          buildScreen(categoryName: 'stack_exchange'));
      await tester.pumpAndSettle();

      expect(find.text('Stack Exchange'), findsOneWidget);
    });

    testWidgets('shows empty state when no entries', (tester) async {
      when(() => mockService.browseKiwixCatalog(
            lang: any(named: 'lang'),
            category: any(named: 'category'),
            count: any(named: 'count'),
            start: any(named: 'start'),
          )).thenAnswer((_) async =>
          const KiwixCatalogSearchResultModel(totalCount: 0, entries: []));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('No entries found'), findsOneWidget);
    });

    testWidgets('shows catalog entries when data loaded', (tester) async {
      when(() => mockService.browseKiwixCatalog(
            lang: any(named: 'lang'),
            category: any(named: 'category'),
            count: any(named: 'count'),
            start: any(named: 'start'),
          )).thenAnswer((_) async => const KiwixCatalogSearchResultModel(
            totalCount: 1,
            entries: [
              KiwixCatalogEntryModel(
                id: 'wiki-en',
                title: 'Wikipedia English',
                sizeBytes: 95000000000,
                downloadUrl: 'https://example.com/test.zim',
              ),
            ],
          ));

      await tester.pumpWidget(buildScreen(user: ownerUser));
      await tester.pumpAndSettle();

      expect(find.text('Wikipedia English'), findsOneWidget);
    });

    testWidgets('shows download button for owner', (tester) async {
      when(() => mockService.browseKiwixCatalog(
            lang: any(named: 'lang'),
            category: any(named: 'category'),
            count: any(named: 'count'),
            start: any(named: 'start'),
          )).thenAnswer((_) async => const KiwixCatalogSearchResultModel(
            totalCount: 1,
            entries: [
              KiwixCatalogEntryModel(
                id: 'test',
                title: 'Test Entry',
                sizeBytes: 1024,
                downloadUrl: 'https://example.com/test.zim',
              ),
            ],
          ));

      await tester.pumpWidget(buildScreen(user: ownerUser));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.download), findsOneWidget);
    });

    testWidgets('hides download button for member', (tester) async {
      when(() => mockService.browseKiwixCatalog(
            lang: any(named: 'lang'),
            category: any(named: 'category'),
            count: any(named: 'count'),
            start: any(named: 'start'),
          )).thenAnswer((_) async => const KiwixCatalogSearchResultModel(
            totalCount: 1,
            entries: [
              KiwixCatalogEntryModel(
                id: 'test',
                title: 'Test Entry',
                sizeBytes: 1024,
                downloadUrl: 'https://example.com/test.zim',
              ),
            ],
          ));

      await tester.pumpWidget(buildScreen(user: memberUser));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.download), findsNothing);
    });

    testWidgets('shows error state with retry', (tester) async {
      when(() => mockService.browseKiwixCatalog(
            lang: any(named: 'lang'),
            category: any(named: 'category'),
            count: any(named: 'count'),
            start: any(named: 'start'),
          )).thenThrow(Exception('Network error'));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Load Failed'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('shows language dropdown', (tester) async {
      when(() => mockService.browseKiwixCatalog(
            lang: any(named: 'lang'),
            category: any(named: 'category'),
            count: any(named: 'count'),
            start: any(named: 'start'),
          )).thenAnswer((_) async =>
          const KiwixCatalogSearchResultModel(totalCount: 0, entries: []));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.translate), findsOneWidget);
    });

    testWidgets('fetches with category parameter', (tester) async {
      when(() => mockService.browseKiwixCatalog(
            lang: any(named: 'lang'),
            category: any(named: 'category'),
            count: any(named: 'count'),
            start: any(named: 'start'),
          )).thenAnswer((_) async =>
          const KiwixCatalogSearchResultModel(totalCount: 0, entries: []));

      await tester.pumpWidget(buildScreen(categoryName: 'ted'));
      await tester.pumpAndSettle();

      verify(() => mockService.browseKiwixCatalog(
            category: 'ted',
            lang: null,
            count: 50,
            start: 0,
          )).called(1);
    });

    testWidgets('shows grid view for entries', (tester) async {
      when(() => mockService.browseKiwixCatalog(
            lang: any(named: 'lang'),
            category: any(named: 'category'),
            count: any(named: 'count'),
            start: any(named: 'start'),
          )).thenAnswer((_) async => const KiwixCatalogSearchResultModel(
            totalCount: 2,
            entries: [
              KiwixCatalogEntryModel(
                id: '1',
                title: 'Entry 1',
                sizeBytes: 1024,
              ),
              KiwixCatalogEntryModel(
                id: '2',
                title: 'Entry 2',
                sizeBytes: 2048,
              ),
            ],
          ));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('Entry 1'), findsOneWidget);
      expect(find.text('Entry 2'), findsOneWidget);
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
