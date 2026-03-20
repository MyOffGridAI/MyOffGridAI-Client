import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/auth/auth_state.dart';
import 'package:myoffgridai_client/core/models/library_models.dart';
import 'package:myoffgridai_client/core/models/user_model.dart';
import 'package:myoffgridai_client/core/services/library_service.dart';
import 'package:myoffgridai_client/features/books/books_screen.dart';

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
    registerFallbackValue('');
    registerFallbackValue(0);
    // Default stubs for Kiwix providers triggered by adjacent-tab prebuild
    when(() => mockService.listZimFiles())
        .thenAnswer((_) async => <ZimFileModel>[]);
    when(() => mockService.listKiwixDownloads())
        .thenAnswer((_) async => <KiwixDownloadStatusModel>[]);
    when(() => mockService.browseKiwixCatalog(
          lang: any(named: 'lang'),
          category: any(named: 'category'),
          count: any(named: 'count'),
          start: any(named: 'start'),
        )).thenAnswer((_) async =>
        const KiwixCatalogSearchResultModel(totalCount: 0, entries: []));
  });

  void stubBrowse({
    GutenbergSearchResultModel? popular,
    GutenbergSearchResultModel? recent,
  }) {
    when(() => mockService.browseGutenberg(
          sort: 'popular',
          limit: any(named: 'limit'),
        )).thenAnswer((_) async =>
        popular ??
        const GutenbergSearchResultModel(count: 0, results: []));
    when(() => mockService.browseGutenberg(
          sort: 'descending',
          limit: any(named: 'limit'),
        )).thenAnswer((_) async =>
        recent ??
        const GutenbergSearchResultModel(count: 0, results: []));
  }

  void stubDefaultMocks() {
    when(() => mockService.listEbooks(
          search: any(named: 'search'),
          format: any(named: 'format'),
          page: any(named: 'page'),
          size: any(named: 'size'),
        )).thenAnswer((_) async => <EbookModel>[]);
    when(() => mockService.getKiwixStatus())
        .thenAnswer((_) async => const KiwixStatusModel(
              available: false,
              bookCount: 0,
            ));
    stubBrowse();
  }

  void stubEbooks(List<EbookModel> ebooks) {
    when(() => mockService.listEbooks(
          search: any(named: 'search'),
          format: any(named: 'format'),
          page: any(named: 'page'),
          size: any(named: 'size'),
        )).thenAnswer((_) async => ebooks);
    when(() => mockService.getKiwixStatus())
        .thenAnswer((_) async => const KiwixStatusModel(
              available: false,
              bookCount: 0,
            ));
  }

  void stubGutenberg(GutenbergSearchResultModel result) {
    when(() => mockService.searchGutenberg(any(), limit: any(named: 'limit')))
        .thenAnswer((_) async => result);
  }

  Widget buildScreen({UserModel? user}) {
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWith(() => _FakeAuthNotifier(user)),
        libraryServiceProvider.overrideWithValue(mockService),
      ],
      child: const MaterialApp(home: BooksScreen()),
    );
  }

  group('BooksScreen', () {
    testWidgets('shows three tabs', (tester) async {
      stubDefaultMocks();
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Library'), findsOneWidget);
      expect(find.text('Kiwix'), findsOneWidget);
      expect(find.text('Gutenberg'), findsOneWidget);
    });

    testWidgets('shows app bar with title', (tester) async {
      stubDefaultMocks();
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Books'), findsOneWidget);
    });

    testWidgets('shows empty state when no ebooks', (tester) async {
      stubDefaultMocks();
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('No eBooks yet'), findsOneWidget);
    });

    testWidgets('shows upload button for owner', (tester) async {
      final owner = UserModel(
        id: '1',
        username: 'owner',
        displayName: 'Owner',
        role: 'ROLE_OWNER',
        isActive: true,
      );

      stubDefaultMocks();
      await tester.pumpWidget(buildScreen(user: owner));
      await tester.pumpAndSettle();

      expect(find.text('Upload eBook'), findsOneWidget);
    });

    testWidgets('shows upload button for admin', (tester) async {
      final admin = UserModel(
        id: '1',
        username: 'admin',
        displayName: 'Admin',
        role: 'ROLE_ADMIN',
        isActive: true,
      );

      stubDefaultMocks();
      await tester.pumpWidget(buildScreen(user: admin));
      await tester.pumpAndSettle();

      expect(find.text('Upload eBook'), findsOneWidget);
    });

    testWidgets('hides upload button for member', (tester) async {
      final member = UserModel(
        id: '2',
        username: 'member',
        displayName: 'Member',
        role: 'ROLE_MEMBER',
        isActive: true,
      );

      stubDefaultMocks();
      await tester.pumpWidget(buildScreen(user: member));
      await tester.pumpAndSettle();

      expect(find.text('Upload eBook'), findsNothing);
    });

    testWidgets('hides upload button for child', (tester) async {
      final child = UserModel(
        id: '3',
        username: 'child',
        displayName: 'Child',
        role: 'ROLE_CHILD',
        isActive: true,
      );

      stubDefaultMocks();
      await tester.pumpWidget(buildScreen(user: child));
      await tester.pumpAndSettle();

      expect(find.text('Upload eBook'), findsNothing);
    });

    testWidgets('displays ebook list when data available', (tester) async {
      when(() => mockService.listEbooks(
            search: any(named: 'search'),
            format: any(named: 'format'),
            page: any(named: 'page'),
            size: any(named: 'size'),
          )).thenAnswer((_) async => [
            const EbookModel(
              id: 'e1',
              title: 'Pride and Prejudice',
              author: 'Jane Austen',
              format: 'EPUB',
              fileSizeBytes: 512000,
            ),
          ]);
      when(() => mockService.getKiwixStatus())
          .thenAnswer((_) async => const KiwixStatusModel(
                available: false,
                bookCount: 0,
              ));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Pride and Prejudice'), findsOneWidget);
    });

    testWidgets('displays ebook author', (tester) async {
      when(() => mockService.listEbooks(
            search: any(named: 'search'),
            format: any(named: 'format'),
            page: any(named: 'page'),
            size: any(named: 'size'),
          )).thenAnswer((_) async => [
            const EbookModel(
              id: 'e1',
              title: 'Pride and Prejudice',
              author: 'Jane Austen',
              format: 'EPUB',
              fileSizeBytes: 512000,
            ),
          ]);
      when(() => mockService.getKiwixStatus())
          .thenAnswer((_) async => const KiwixStatusModel(
                available: false,
                bookCount: 0,
              ));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.textContaining('Jane Austen'), findsOneWidget);
    });

    testWidgets('shows tab icons', (tester) async {
      stubDefaultMocks();
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Scope to Tab widgets so empty-state icons are not counted
      expect(
        find.descendant(of: find.byType(Tab), matching: find.byIcon(Icons.menu_book)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: find.byType(Tab), matching: find.byIcon(Icons.language)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: find.byType(Tab), matching: find.byIcon(Icons.auto_stories)),
        findsOneWidget,
      );
    });
  });

  group('Gutenberg tab', () {
    testWidgets('shows search field', (tester) async {
      stubDefaultMocks();
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Tap on Gutenberg tab
      await tester.tap(find.text('Gutenberg'));
      await tester.pumpAndSettle();

      expect(find.text('Search Project Gutenberg...'), findsOneWidget);
    });

    testWidgets('shows search icon', (tester) async {
      stubDefaultMocks();
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gutenberg'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.search), findsWidgets);
    });
  });

  group('Kiwix tab', () {
    testWidgets('shows stopped when server is down', (tester) async {
      stubDefaultMocks();
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Tap on Kiwix tab
      await tester.tap(find.text('Kiwix'));
      await tester.pumpAndSettle();

      expect(find.text('Kiwix Stopped'), findsOneWidget);
    });

    testWidgets('shows error view when kiwix status fails', (tester) async {
      stubDefaultMocks();
      when(() => mockService.getKiwixStatus())
          .thenThrow(const ApiException(
              statusCode: 500, message: 'Kiwix error'));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kiwix'));
      await tester.pumpAndSettle();

      expect(find.text('Status Check Failed'), findsOneWidget);
    });

    testWidgets('shows running but no open button when url is null',
        (tester) async {
      stubDefaultMocks();
      when(() => mockService.getKiwixStatus())
          .thenAnswer((_) async => const KiwixStatusModel(
                available: true,
                url: null,
                bookCount: 5,
              ));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kiwix'));
      await tester.pumpAndSettle();

      expect(find.text('Kiwix Running'), findsOneWidget);
      expect(find.text('Open Kiwix'), findsNothing);
    });
  });

  group('Library tab - eBook tiles', () {
    testWidgets('shows PDF format icon', (tester) async {
      stubEbooks([
        const EbookModel(
          id: 'e1',
          title: 'A PDF Book',
          format: 'PDF',
          fileSizeBytes: 100,
        ),
      ]);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
    });

    testWidgets('shows EPUB format icon', (tester) async {
      stubEbooks([
        const EbookModel(
          id: 'e1',
          title: 'An EPUB Book',
          format: 'EPUB',
          fileSizeBytes: 100,
        ),
      ]);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.auto_stories), findsWidgets);
    });

    testWidgets('shows TXT format icon', (tester) async {
      stubEbooks([
        const EbookModel(
          id: 'e1',
          title: 'A TXT File',
          format: 'TXT',
          fileSizeBytes: 100,
        ),
      ]);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.article), findsOneWidget);
    });

    testWidgets('shows HTML format icon', (tester) async {
      stubEbooks([
        const EbookModel(
          id: 'e1',
          title: 'An HTML Book',
          format: 'HTML',
          fileSizeBytes: 100,
        ),
      ]);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.code), findsOneWidget);
    });

    testWidgets('shows generic book icon for unknown format', (tester) async {
      stubEbooks([
        const EbookModel(
          id: 'e1',
          title: 'Unknown Format',
          format: 'MOBI',
          fileSizeBytes: 100,
        ),
      ]);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.book), findsOneWidget);
    });

    testWidgets('shows size in bytes for small files', (tester) async {
      stubEbooks([
        const EbookModel(
          id: 'e1',
          title: 'Tiny Book',
          format: 'TXT',
          fileSizeBytes: 500,
        ),
      ]);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.textContaining('500 B'), findsOneWidget);
    });

    testWidgets('shows size in KB for kilobyte files', (tester) async {
      stubEbooks([
        const EbookModel(
          id: 'e1',
          title: 'KB Book',
          format: 'TXT',
          fileSizeBytes: 5120,
        ),
      ]);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.textContaining('5.0 KB'), findsOneWidget);
    });

    testWidgets('shows size in MB for megabyte files', (tester) async {
      stubEbooks([
        const EbookModel(
          id: 'e1',
          title: 'MB Book',
          format: 'EPUB',
          fileSizeBytes: 2097152,
        ),
      ]);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.textContaining('2.0 MB'), findsOneWidget);
    });

    testWidgets('shows Gutenberg badge for imported books', (tester) async {
      stubEbooks([
        const EbookModel(
          id: 'e1',
          title: 'Gutenberg Classic',
          format: 'EPUB',
          fileSizeBytes: 1024,
          gutenbergId: '12345',
        ),
      ]);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.public), findsOneWidget);
    });

    testWidgets('hides Gutenberg badge for non-Gutenberg books',
        (tester) async {
      stubEbooks([
        const EbookModel(
          id: 'e1',
          title: 'My Book',
          format: 'EPUB',
          fileSizeBytes: 1024,
        ),
      ]);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.public), findsNothing);
    });
  });

  group('Library tab - error state', () {
    testWidgets('shows error view when ebooks fail to load', (tester) async {
      when(() => mockService.listEbooks(
            search: any(named: 'search'),
            format: any(named: 'format'),
            page: any(named: 'page'),
            size: any(named: 'size'),
          )).thenThrow(
              const ApiException(statusCode: 500, message: 'Load error'));
      when(() => mockService.getKiwixStatus())
          .thenAnswer((_) async => const KiwixStatusModel(
                available: false,
                bookCount: 0,
              ));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Load Failed'), findsOneWidget);
    });
  });

  group('Gutenberg tab - search', () {
    testWidgets('shows browse sections when no search query', (tester) async {
      stubDefaultMocks();
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gutenberg'));
      await tester.pumpAndSettle();

      expect(find.text('Popular Books'), findsOneWidget);
      expect(find.text('Newest Releases'), findsOneWidget);
    });

    testWidgets('submitting search triggers results', (tester) async {
      stubDefaultMocks();
      stubGutenberg(const GutenbergSearchResultModel(
        count: 1,
        results: [
          GutenbergBookModel(
            id: 100,
            title: 'Moby Dick',
            authors: ['Herman Melville'],
            languages: ['en'],
            downloadCount: 50000,
          ),
        ],
      ));

      await tester.pumpWidget(buildScreen(user: ownerUser));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gutenberg'));
      await tester.pumpAndSettle();

      // Enter search and submit
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'moby dick');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Moby Dick'), findsOneWidget);
      expect(find.textContaining('Herman Melville'), findsOneWidget);
      expect(find.textContaining('EN'), findsOneWidget);
      expect(find.textContaining('50000 downloads'), findsOneWidget);
    });

    testWidgets('shows no results state', (tester) async {
      stubDefaultMocks();
      stubGutenberg(const GutenbergSearchResultModel(
        count: 0,
        results: [],
      ));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gutenberg'));
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'xyznonexistent');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('No results'), findsOneWidget);
    });

    testWidgets('shows error view on search failure', (tester) async {
      stubDefaultMocks();
      when(() =>
              mockService.searchGutenberg(any(), limit: any(named: 'limit')))
          .thenThrow(const ApiException(
              statusCode: 500, message: 'Search error'));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gutenberg'));
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'test');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Search Failed'), findsOneWidget);
    });

    testWidgets('shows download icon for owner on Gutenberg results',
        (tester) async {
      stubDefaultMocks();
      stubGutenberg(const GutenbergSearchResultModel(
        count: 1,
        results: [
          GutenbergBookModel(
            id: 100,
            title: 'Test Book',
            authors: [],
            languages: [],
            downloadCount: 100,
          ),
        ],
      ));

      await tester.pumpWidget(buildScreen(user: ownerUser));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gutenberg'));
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'test');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.download), findsOneWidget);
    });

    testWidgets('hides download icon for member', (tester) async {
      stubDefaultMocks();
      stubGutenberg(const GutenbergSearchResultModel(
        count: 1,
        results: [
          GutenbergBookModel(
            id: 100,
            title: 'Test Book',
            authors: [],
            languages: [],
            downloadCount: 100,
          ),
        ],
      ));

      await tester.pumpWidget(buildScreen(user: memberUser));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gutenberg'));
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'test');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.download), findsNothing);
    });

    testWidgets('import calls importGutenbergBook on success',
        (tester) async {
      stubDefaultMocks();
      stubGutenberg(const GutenbergSearchResultModel(
        count: 1,
        results: [
          GutenbergBookModel(
            id: 42,
            title: 'Imported Book',
            authors: ['Author A'],
            languages: ['en'],
            downloadCount: 999,
          ),
        ],
      ));

      when(() => mockService.importGutenbergBook(42))
          .thenAnswer((_) async => const EbookModel(
                id: 'e99',
                title: 'Imported Book',
                format: 'EPUB',
                fileSizeBytes: 1024,
              ));

      await tester.pumpWidget(buildScreen(user: ownerUser));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gutenberg'));
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'imported');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Tap import button
      await tester.tap(find.byIcon(Icons.download));
      await tester.pumpAndSettle();

      verify(() => mockService.importGutenbergBook(42)).called(1);
      expect(
          find.text('"Imported Book" imported successfully'), findsOneWidget);
    });

    testWidgets('import shows error on failure', (tester) async {
      stubDefaultMocks();
      stubGutenberg(const GutenbergSearchResultModel(
        count: 1,
        results: [
          GutenbergBookModel(
            id: 42,
            title: 'Fail Book',
            authors: [],
            languages: [],
            downloadCount: 0,
          ),
        ],
      ));

      when(() => mockService.importGutenbergBook(42)).thenThrow(
          const ApiException(statusCode: 500, message: 'Import failed'));

      await tester.pumpWidget(buildScreen(user: ownerUser));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gutenberg'));
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'fail');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.download));
      await tester.pumpAndSettle();

      expect(find.text('Import failed'), findsOneWidget);
    });

    testWidgets('shows auto_stories icon for each Gutenberg result',
        (tester) async {
      stubDefaultMocks();
      stubGutenberg(const GutenbergSearchResultModel(
        count: 2,
        results: [
          GutenbergBookModel(
            id: 1,
            title: 'Book A',
            authors: [],
            languages: [],
            downloadCount: 10,
          ),
          GutenbergBookModel(
            id: 2,
            title: 'Book B',
            authors: [],
            languages: [],
            downloadCount: 20,
          ),
        ],
      ));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gutenberg'));
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'books');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // auto_stories from the tab icon + 2 from list items
      expect(find.byIcon(Icons.auto_stories), findsWidgets);
      expect(find.text('Book A'), findsOneWidget);
      expect(find.text('Book B'), findsOneWidget);
    });
  });

  // ── Library tab - delete ebook ──────────────────────────────────────────

  group('Library tab - delete ebook', () {
    const testEbook = EbookModel(
      id: 'e1',
      title: 'Deletable Book',
      author: 'Test Author',
      format: 'EPUB',
      fileSizeBytes: 1024,
    );

    testWidgets('owner sees delete option on eBook tile', (tester) async {
      stubEbooks([testEbook]);
      stubBrowse();
      await tester.pumpWidget(buildScreen(user: ownerUser));
      await tester.pumpAndSettle();

      // Verify popup menu button is present
      expect(find.byIcon(Icons.more_vert), findsOneWidget);

      // Tap the popup menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('admin sees delete option on eBook tile', (tester) async {
      const adminUser = UserModel(
        id: '3',
        username: 'admin',
        displayName: 'Admin',
        role: 'ROLE_ADMIN',
        isActive: true,
      );

      stubEbooks([testEbook]);
      stubBrowse();
      await tester.pumpWidget(buildScreen(user: adminUser));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('member does not see delete option', (tester) async {
      stubEbooks([testEbook]);
      stubBrowse();
      await tester.pumpWidget(buildScreen(user: memberUser));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.more_vert), findsNothing);
    });

    testWidgets('tapping delete shows confirmation dialog', (tester) async {
      stubEbooks([testEbook]);
      stubBrowse();
      await tester.pumpWidget(buildScreen(user: ownerUser));
      await tester.pumpAndSettle();

      // Tap popup menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Tap Delete option
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Confirmation dialog appears
      expect(find.text('Delete eBook'), findsOneWidget);
      expect(find.textContaining('Are you sure'), findsOneWidget);
    });

    testWidgets('confirming delete calls deleteEbook and refreshes list',
        (tester) async {
      stubEbooks([testEbook]);
      stubBrowse();
      when(() => mockService.deleteEbook('e1'))
          .thenAnswer((_) async {});

      await tester.pumpWidget(buildScreen(user: ownerUser));
      await tester.pumpAndSettle();

      // Open popup menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Tap Delete
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Confirm in dialog
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();

      verify(() => mockService.deleteEbook('e1')).called(1);
      expect(find.text('"Deletable Book" deleted'), findsOneWidget);
    });

    testWidgets('cancelling delete does not call deleteEbook',
        (tester) async {
      stubEbooks([testEbook]);
      stubBrowse();
      await tester.pumpWidget(buildScreen(user: ownerUser));
      await tester.pumpAndSettle();

      // Open popup menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Tap Delete
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Cancel in dialog
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      verifyNever(() => mockService.deleteEbook(any()));
    });

    testWidgets('delete error shows error snackbar', (tester) async {
      stubEbooks([testEbook]);
      stubBrowse();
      when(() => mockService.deleteEbook('e1'))
          .thenThrow(const ApiException(
              statusCode: 500, message: 'Delete failed'));

      await tester.pumpWidget(buildScreen(user: ownerUser));
      await tester.pumpAndSettle();

      // Open popup menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Tap Delete
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Confirm
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Delete failed'), findsOneWidget);
    });
  });

  // ── Retry callbacks ─────────────────────────────────────────────────────

  group('Library tab - error retry', () {
    testWidgets('tapping Retry on error view re-fetches ebooks',
        (tester) async {
      // First call: throws error. Second call: returns data.
      var callCount = 0;
      when(() => mockService.listEbooks(
            search: any(named: 'search'),
            format: any(named: 'format'),
            page: any(named: 'page'),
            size: any(named: 'size'),
          )).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          throw const ApiException(statusCode: 500, message: 'Load error');
        }
        return <EbookModel>[
          const EbookModel(
            id: 'e1',
            title: 'Recovered Book',
            format: 'EPUB',
            fileSizeBytes: 1024,
          ),
        ];
      });
      when(() => mockService.getKiwixStatus())
          .thenAnswer((_) async => const KiwixStatusModel(
                available: false,
                bookCount: 0,
              ));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Verify error state is shown
      expect(find.text('Load Failed'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Tap retry
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // Should now show the recovered data
      expect(find.text('Recovered Book'), findsOneWidget);
      expect(find.text('Load Failed'), findsNothing);
    });
  });

  group('Kiwix tab - error retry', () {
    testWidgets('tapping Retry on Kiwix error view re-fetches status',
        (tester) async {
      stubDefaultMocks();
      var callCount = 0;
      when(() => mockService.getKiwixStatus()).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          throw const ApiException(statusCode: 500, message: 'Kiwix error');
        }
        return const KiwixStatusModel(
          available: false,
          bookCount: 0,
        );
      });

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Navigate to Kiwix tab
      await tester.tap(find.text('Kiwix'));
      await tester.pumpAndSettle();

      // Verify error state
      expect(find.text('Status Check Failed'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Tap retry
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // After retry, Kiwix is stopped (not errored)
      expect(find.text('Kiwix Stopped'), findsOneWidget);
      expect(find.text('Status Check Failed'), findsNothing);
    });
  });

  group('Gutenberg tab - clear button', () {
    testWidgets('clear button resets search and shows initial state',
        (tester) async {
      stubDefaultMocks();
      stubGutenberg(const GutenbergSearchResultModel(
        count: 1,
        results: [
          GutenbergBookModel(
            id: 100,
            title: 'Some Book',
            authors: [],
            languages: [],
            downloadCount: 50,
          ),
        ],
      ));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Go to Gutenberg tab
      await tester.tap(find.text('Gutenberg'));
      await tester.pumpAndSettle();

      // Enter search text and submit
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'some book');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Verify results are shown
      expect(find.text('Some Book'), findsOneWidget);

      // Tap the clear button (Icons.clear)
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      // Should revert to browse view (no search results shown)
      expect(find.text('Popular Books'), findsOneWidget);
      expect(find.text('Some Book'), findsNothing);
    });
  });

  group('Gutenberg tab - search error retry', () {
    testWidgets('tapping Retry on search error re-fetches results',
        (tester) async {
      stubDefaultMocks();
      var searchCallCount = 0;
      when(() =>
              mockService.searchGutenberg(any(), limit: any(named: 'limit')))
          .thenAnswer((_) async {
        searchCallCount++;
        if (searchCallCount == 1) {
          throw const ApiException(
              statusCode: 500, message: 'Search error');
        }
        return const GutenbergSearchResultModel(
          count: 1,
          results: [
            GutenbergBookModel(
              id: 200,
              title: 'Recovered Search Result',
              authors: ['Author'],
              languages: ['en'],
              downloadCount: 100,
            ),
          ],
        );
      });

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Go to Gutenberg tab
      await tester.tap(find.text('Gutenberg'));
      await tester.pumpAndSettle();

      // Enter search and submit
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'search term');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Verify error state
      expect(find.text('Search Failed'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Tap retry
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // Should show recovered results
      expect(find.text('Recovered Search Result'), findsOneWidget);
      expect(find.text('Search Failed'), findsNothing);
    });
  });

  // ── Gutenberg tab - browse sections ────────────────────────────────────

  group('Gutenberg tab - browse sections', () {
    testWidgets('shows popular books in browse section', (tester) async {
      stubDefaultMocks();
      stubBrowse(
        popular: const GutenbergSearchResultModel(
          count: 1,
          results: [
            GutenbergBookModel(
              id: 1342,
              title: 'Pride and Prejudice',
              authors: ['Austen, Jane'],
              downloadCount: 80000,
            ),
          ],
        ),
      );

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gutenberg'));
      await tester.pumpAndSettle();

      expect(find.text('Popular Books'), findsOneWidget);
      expect(find.text('Pride and Prejudice'), findsOneWidget);
      expect(find.text('Austen, Jane'), findsOneWidget);
    });

    testWidgets('shows newest releases in browse section', (tester) async {
      stubDefaultMocks();
      stubBrowse(
        recent: const GutenbergSearchResultModel(
          count: 1,
          results: [
            GutenbergBookModel(
              id: 99999,
              title: 'Brand New Book',
              authors: ['Modern Author'],
              downloadCount: 10,
            ),
          ],
        ),
      );

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gutenberg'));
      await tester.pumpAndSettle();

      expect(find.text('Newest Releases'), findsOneWidget);
      expect(find.text('Brand New Book'), findsOneWidget);
    });

    testWidgets('browse section shows error independently', (tester) async {
      when(() => mockService.listEbooks(
            search: any(named: 'search'),
            format: any(named: 'format'),
            page: any(named: 'page'),
            size: any(named: 'size'),
          )).thenAnswer((_) async => <EbookModel>[]);
      when(() => mockService.getKiwixStatus())
          .thenAnswer((_) async => const KiwixStatusModel(
                available: false,
                bookCount: 0,
              ));
      when(() => mockService.browseGutenberg(
            sort: 'popular',
            limit: any(named: 'limit'),
          )).thenThrow(
          const ApiException(statusCode: 500, message: 'Popular error'));
      when(() => mockService.browseGutenberg(
            sort: 'descending',
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => const GutenbergSearchResultModel(
            count: 1,
            results: [
              GutenbergBookModel(
                id: 100,
                title: 'Recent Book',
                authors: [],
                downloadCount: 5,
              ),
            ],
          ));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gutenberg'));
      await tester.pumpAndSettle();

      // Popular section failed, newest loaded
      expect(find.text('Popular Books'), findsOneWidget);
      expect(find.text('Load Failed'), findsOneWidget);
      expect(find.text('Newest Releases'), findsOneWidget);
      expect(find.text('Recent Book'), findsOneWidget);
    });
  });

  // ── Gutenberg tab - debounced search ─────────────────────────────────

  group('Gutenberg tab - debounced search', () {
    testWidgets('typing triggers debounced search after 500ms',
        (tester) async {
      stubDefaultMocks();
      stubGutenberg(const GutenbergSearchResultModel(
        count: 1,
        results: [
          GutenbergBookModel(
            id: 200,
            title: 'Debounce Result',
            authors: ['Test Author'],
            languages: ['en'],
            downloadCount: 100,
          ),
        ],
      ));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gutenberg'));
      await tester.pumpAndSettle();

      // Type in search field (onChanged, not onSubmitted)
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'debounce');

      // Before debounce fires, browse view is still showing
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Popular Books'), findsOneWidget);

      // After debounce fires (500ms total)
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Debounce Result'), findsOneWidget);
    });

    testWidgets('Enter submits immediately without debounce wait',
        (tester) async {
      stubDefaultMocks();
      stubGutenberg(const GutenbergSearchResultModel(
        count: 1,
        results: [
          GutenbergBookModel(
            id: 300,
            title: 'Instant Result',
            authors: [],
            languages: [],
            downloadCount: 50,
          ),
        ],
      ));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gutenberg'));
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'instant');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Instant Result'), findsOneWidget);
    });
  });

  // ── EbookTile onTap navigation ────────────────────────────────────────

  group('Library tab - ebook tile navigation', () {
    testWidgets('tapping an ebook tile navigates to book reader route',
        (tester) async {
      // Track navigation
      String? navigatedTo;

      final testRouter = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const BooksScreen(),
          ),
          GoRoute(
            path: '/books/reader',
            builder: (context, state) {
              navigatedTo = '/books/reader';
              return const Scaffold(
                body: Center(child: Text('BOOK_READER')),
              );
            },
          ),
        ],
      );

      when(() => mockService.listEbooks(
            search: any(named: 'search'),
            format: any(named: 'format'),
            page: any(named: 'page'),
            size: any(named: 'size'),
          )).thenAnswer((_) async => [
            const EbookModel(
              id: 'e1',
              title: 'Tappable Book',
              author: 'Test Author',
              format: 'PDF',
              fileSizeBytes: 2048,
            ),
          ]);
      when(() => mockService.getKiwixStatus())
          .thenAnswer((_) async => const KiwixStatusModel(
                available: false,
                bookCount: 0,
              ));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider
                .overrideWith(() => _FakeAuthNotifier(memberUser)),
            libraryServiceProvider.overrideWithValue(mockService),
          ],
          child: MaterialApp.router(routerConfig: testRouter),
        ),
      );
      await tester.pumpAndSettle();

      // Verify the ebook tile is displayed
      expect(find.text('Tappable Book'), findsOneWidget);

      // Tap on the ebook tile
      await tester.tap(find.text('Tappable Book'));
      await tester.pumpAndSettle();

      // Verify navigation occurred
      expect(navigatedTo, '/books/reader');
      expect(find.text('BOOK_READER'), findsOneWidget);
    });
  });

  // ── Kiwix tab - status bar ────────────────────────────────────────────

  group('Kiwix tab - status bar', () {
    testWidgets('shows running when server is available', (tester) async {
      stubDefaultMocks();
      when(() => mockService.getKiwixStatus())
          .thenAnswer((_) async => const KiwixStatusModel(
                available: true,
                url: 'http://localhost:8888',
                bookCount: 3,
                processManaged: true,
              ));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kiwix'));
      await tester.pumpAndSettle();

      expect(find.text('Kiwix Running'), findsOneWidget);
      expect(find.text('Open Kiwix'), findsOneWidget);
    });

    testWidgets('owner sees start button when stopped and processManaged',
        (tester) async {
      stubDefaultMocks();
      when(() => mockService.getKiwixStatus())
          .thenAnswer((_) async => const KiwixStatusModel(
                available: false,
                bookCount: 0,
                processManaged: true,
              ));

      await tester.pumpWidget(buildScreen(user: ownerUser));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kiwix'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('owner sees stop button when running and processManaged',
        (tester) async {
      stubDefaultMocks();
      when(() => mockService.getKiwixStatus())
          .thenAnswer((_) async => const KiwixStatusModel(
                available: true,
                url: 'http://localhost:8888',
                bookCount: 2,
                processManaged: true,
              ));

      await tester.pumpWidget(buildScreen(user: ownerUser));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kiwix'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.stop), findsOneWidget);
    });

    testWidgets('member does not see start/stop button', (tester) async {
      stubDefaultMocks();
      when(() => mockService.getKiwixStatus())
          .thenAnswer((_) async => const KiwixStatusModel(
                available: false,
                bookCount: 0,
                processManaged: true,
              ));

      await tester.pumpWidget(buildScreen(user: memberUser));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kiwix'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.play_arrow), findsNothing);
      expect(find.byIcon(Icons.stop), findsNothing);
    });

    testWidgets('hides start/stop when processManaged is false',
        (tester) async {
      stubDefaultMocks();
      when(() => mockService.getKiwixStatus())
          .thenAnswer((_) async => const KiwixStatusModel(
                available: false,
                bookCount: 0,
                processManaged: false,
              ));

      await tester.pumpWidget(buildScreen(user: ownerUser));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kiwix'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.play_arrow), findsNothing);
    });

    testWidgets('tapping start calls startKiwix', (tester) async {
      stubDefaultMocks();
      when(() => mockService.getKiwixStatus())
          .thenAnswer((_) async => const KiwixStatusModel(
                available: false,
                bookCount: 0,
                processManaged: true,
              ));
      when(() => mockService.startKiwix()).thenAnswer((_) async {});

      await tester.pumpWidget(buildScreen(user: ownerUser));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kiwix'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pumpAndSettle();

      verify(() => mockService.startKiwix()).called(1);
    });

    testWidgets('tapping stop calls stopKiwix', (tester) async {
      stubDefaultMocks();
      when(() => mockService.getKiwixStatus())
          .thenAnswer((_) async => const KiwixStatusModel(
                available: true,
                url: 'http://localhost:8888',
                bookCount: 2,
                processManaged: true,
              ));
      when(() => mockService.stopKiwix()).thenAnswer((_) async {});

      await tester.pumpWidget(buildScreen(user: ownerUser));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kiwix'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.stop));
      await tester.pumpAndSettle();

      verify(() => mockService.stopKiwix()).called(1);
    });
  });

  // ── Kiwix tab - installation states ──────────────────────────────────

  group('Kiwix tab - installation states', () {
    testWidgets('shows installing spinner when installationStatus is INSTALLING',
        (tester) async {
      stubDefaultMocks();
      when(() => mockService.getKiwixStatus())
          .thenAnswer((_) async => const KiwixStatusModel(
                available: false,
                bookCount: 0,
                installationStatus: 'INSTALLING',
              ));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kiwix'));
      // Pump multiple frames to resolve FutureProvider; cannot use pumpAndSettle
      // because CircularProgressIndicator never settles.
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Installing Kiwix...'), findsOneWidget);
    });

    testWidgets('shows error and retry button when INSTALL_FAILED',
        (tester) async {
      stubDefaultMocks();
      when(() => mockService.getKiwixStatus())
          .thenAnswer((_) async => const KiwixStatusModel(
                available: false,
                bookCount: 0,
                installationStatus: 'INSTALL_FAILED',
                installationError: 'brew not found',
              ));

      await tester.pumpWidget(buildScreen(user: ownerUser));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kiwix'));
      await tester.pumpAndSettle();

      expect(find.text('Kiwix Install Failed'), findsOneWidget);
      expect(find.text('brew not found'), findsOneWidget);
      expect(find.text('Retry Install'), findsOneWidget);
    });

    testWidgets('shows install button when NOT_INSTALLED', (tester) async {
      stubDefaultMocks();
      when(() => mockService.getKiwixStatus())
          .thenAnswer((_) async => const KiwixStatusModel(
                available: false,
                bookCount: 0,
                installationStatus: 'NOT_INSTALLED',
              ));

      await tester.pumpWidget(buildScreen(user: ownerUser));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kiwix'));
      await tester.pumpAndSettle();

      expect(find.text('Kiwix not installed'), findsOneWidget);
      expect(find.text('Install'), findsOneWidget);
    });

    testWidgets('retry button calls installKiwix and refreshes status',
        (tester) async {
      stubDefaultMocks();
      when(() => mockService.getKiwixStatus())
          .thenAnswer((_) async => const KiwixStatusModel(
                available: false,
                bookCount: 0,
                installationStatus: 'INSTALL_FAILED',
                installationError: 'failed',
              ));
      when(() => mockService.installKiwix()).thenAnswer((_) async {});

      await tester.pumpWidget(buildScreen(user: ownerUser));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kiwix'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Retry Install'));
      await tester.pumpAndSettle();

      verify(() => mockService.installKiwix()).called(1);
    });
  });

  // ── Kiwix tab - ZIM files ─────────────────────────────────────────────

  group('Kiwix tab - ZIM files', () {
    testWidgets('shows empty message when no ZIM files', (tester) async {
      stubDefaultMocks();
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kiwix'));
      await tester.pumpAndSettle();

      expect(find.text('My ZIM Files'), findsOneWidget);
      expect(find.text('No ZIM files yet. Browse the catalog below.'),
          findsOneWidget);
    });

    testWidgets('displays ZIM file list', (tester) async {
      stubDefaultMocks();
      when(() => mockService.listZimFiles())
          .thenAnswer((_) async => [
                const ZimFileModel(
                  id: 'z1',
                  filename: 'wikipedia_en.zim',
                  displayName: 'Wikipedia EN',
                  category: 'reference',
                  language: 'eng',
                  fileSizeBytes: 90000000000,
                ),
              ]);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kiwix'));
      await tester.pumpAndSettle();

      expect(find.text('Wikipedia EN'), findsOneWidget);
    });

    testWidgets('owner sees delete button on ZIM file', (tester) async {
      stubDefaultMocks();
      when(() => mockService.listZimFiles())
          .thenAnswer((_) async => [
                const ZimFileModel(
                  id: 'z1',
                  filename: 'test.zim',
                  displayName: 'Test ZIM',
                  fileSizeBytes: 1024,
                ),
              ]);

      await tester.pumpWidget(buildScreen(user: ownerUser));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kiwix'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('member does not see delete button on ZIM file',
        (tester) async {
      stubDefaultMocks();
      when(() => mockService.listZimFiles())
          .thenAnswer((_) async => [
                const ZimFileModel(
                  id: 'z1',
                  filename: 'test.zim',
                  displayName: 'Test ZIM',
                  fileSizeBytes: 1024,
                ),
              ]);

      await tester.pumpWidget(buildScreen(user: memberUser));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kiwix'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delete), findsNothing);
    });

    testWidgets('tapping delete shows confirmation dialog', (tester) async {
      stubDefaultMocks();
      when(() => mockService.listZimFiles())
          .thenAnswer((_) async => [
                const ZimFileModel(
                  id: 'z1',
                  filename: 'test.zim',
                  displayName: 'Test ZIM',
                  fileSizeBytes: 1024,
                ),
              ]);

      await tester.pumpWidget(buildScreen(user: ownerUser));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kiwix'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      expect(find.text('Delete ZIM File'), findsOneWidget);
      expect(find.textContaining('Are you sure'), findsOneWidget);
    });

    testWidgets('confirming delete calls deleteZimFile', (tester) async {
      stubDefaultMocks();
      when(() => mockService.listZimFiles())
          .thenAnswer((_) async => [
                const ZimFileModel(
                  id: 'z1',
                  filename: 'test.zim',
                  displayName: 'Test ZIM',
                  fileSizeBytes: 1024,
                ),
              ]);
      when(() => mockService.deleteZimFile('z1'))
          .thenAnswer((_) async {});

      await tester.pumpWidget(buildScreen(user: ownerUser));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kiwix'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();

      verify(() => mockService.deleteZimFile('z1')).called(1);
    });
  });

  // ── Kiwix tab - catalog browse ────────────────────────────────────────

  group('Kiwix tab - catalog browse', () {
    testWidgets('shows browse catalog section title', (tester) async {
      stubDefaultMocks();
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kiwix'));
      await tester.pumpAndSettle();

      expect(find.text('Browse Catalog'), findsOneWidget);
      expect(find.text('Search Kiwix catalog...'), findsOneWidget);
    });

    testWidgets('shows catalog entries in browse cards', (tester) async {
      stubDefaultMocks();
      when(() => mockService.browseKiwixCatalog(
            lang: any(named: 'lang'),
            category: any(named: 'category'),
            count: any(named: 'count'),
            start: any(named: 'start'),
          )).thenAnswer((_) async =>
          const KiwixCatalogSearchResultModel(
            totalCount: 1,
            entries: [
              KiwixCatalogEntryModel(
                id: 'uuid1',
                title: 'Wikipedia English',
                language: 'eng',
                sizeBytes: 90000000000,
                downloadUrl: 'https://example.com/wiki.zim',
              ),
            ],
          ));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kiwix'));
      await tester.pumpAndSettle();

      expect(find.text('Wikipedia English'), findsOneWidget);
    });

    testWidgets('owner sees download button on catalog card', (tester) async {
      stubDefaultMocks();
      when(() => mockService.browseKiwixCatalog(
            lang: any(named: 'lang'),
            category: any(named: 'category'),
            count: any(named: 'count'),
            start: any(named: 'start'),
          )).thenAnswer((_) async =>
          const KiwixCatalogSearchResultModel(
            totalCount: 1,
            entries: [
              KiwixCatalogEntryModel(
                id: 'uuid1',
                title: 'Test ZIM',
                sizeBytes: 1024,
                downloadUrl: 'https://example.com/test.zim',
              ),
            ],
          ));

      await tester.pumpWidget(buildScreen(user: ownerUser));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kiwix'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.download), findsOneWidget);
    });

    testWidgets('member does not see download button', (tester) async {
      stubDefaultMocks();
      when(() => mockService.browseKiwixCatalog(
            lang: any(named: 'lang'),
            category: any(named: 'category'),
            count: any(named: 'count'),
            start: any(named: 'start'),
          )).thenAnswer((_) async =>
          const KiwixCatalogSearchResultModel(
            totalCount: 1,
            entries: [
              KiwixCatalogEntryModel(
                id: 'uuid1',
                title: 'Test ZIM',
                sizeBytes: 1024,
                downloadUrl: 'https://example.com/test.zim',
              ),
            ],
          ));

      await tester.pumpWidget(buildScreen(user: memberUser));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kiwix'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.download), findsNothing);
    });

    testWidgets('download button calls downloadFromCatalog', (tester) async {
      stubDefaultMocks();
      when(() => mockService.browseKiwixCatalog(
            lang: any(named: 'lang'),
            category: any(named: 'category'),
            count: any(named: 'count'),
            start: any(named: 'start'),
          )).thenAnswer((_) async =>
          const KiwixCatalogSearchResultModel(
            totalCount: 1,
            entries: [
              KiwixCatalogEntryModel(
                id: 'uuid1',
                title: 'Test ZIM',
                name: 'test',
                sizeBytes: 1024,
                downloadUrl: 'https://example.com/test.zim',
              ),
            ],
          ));
      when(() => mockService.downloadFromCatalog(
            downloadUrl: any(named: 'downloadUrl'),
            filename: any(named: 'filename'),
            displayName: any(named: 'displayName'),
            category: any(named: 'category'),
            language: any(named: 'language'),
            sizeBytes: any(named: 'sizeBytes'),
          )).thenAnswer((_) async => 'download-id-1');

      await tester.pumpWidget(buildScreen(user: ownerUser));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kiwix'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.download));
      await tester.pumpAndSettle();

      verify(() => mockService.downloadFromCatalog(
            downloadUrl: 'https://example.com/test.zim',
            filename: 'test.zim',
            displayName: 'Test ZIM',
            category: any(named: 'category'),
            language: any(named: 'language'),
            sizeBytes: 1024,
          )).called(1);
      expect(find.text('Downloading "Test ZIM"...'), findsOneWidget);
    });

    testWidgets('shows empty catalog message', (tester) async {
      stubDefaultMocks();
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kiwix'));
      await tester.pumpAndSettle();

      expect(find.text('No catalog entries available'), findsOneWidget);
    });
  });

  // ── Kiwix tab - active downloads ──────────────────────────────────────

  group('Kiwix tab - active downloads', () {
    testWidgets('shows active downloads with progress', (tester) async {
      stubDefaultMocks();
      when(() => mockService.listKiwixDownloads())
          .thenAnswer((_) async => [
                const KiwixDownloadStatusModel(
                  id: 'dl1',
                  filename: 'wikipedia.zim',
                  totalBytes: 1000000,
                  downloadedBytes: 450000,
                  percentComplete: 45,
                  status: 'DOWNLOADING',
                ),
              ]);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kiwix'));
      await tester.pumpAndSettle();

      expect(find.text('Active Downloads'), findsOneWidget);
      expect(find.text('wikipedia.zim'), findsOneWidget);
      expect(find.text('45%'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('hides active downloads when no active downloads',
        (tester) async {
      stubDefaultMocks();
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kiwix'));
      await tester.pumpAndSettle();

      expect(find.text('Active Downloads'), findsNothing);
    });

    testWidgets('hides completed downloads from active section',
        (tester) async {
      stubDefaultMocks();
      when(() => mockService.listKiwixDownloads())
          .thenAnswer((_) async => [
                const KiwixDownloadStatusModel(
                  id: 'dl1',
                  filename: 'done.zim',
                  totalBytes: 1000000,
                  downloadedBytes: 1000000,
                  percentComplete: 100,
                  status: 'COMPLETE',
                ),
              ]);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kiwix'));
      await tester.pumpAndSettle();

      expect(find.text('Active Downloads'), findsNothing);
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
