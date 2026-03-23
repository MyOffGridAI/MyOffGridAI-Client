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
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

class MockLibraryService extends Mock implements LibraryService {}

/// Fake [WebViewPlatform] for unit tests.
class _FakeWebViewPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements WebViewPlatform {
  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) =>
      _FakePlatformWebViewController(params);

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) =>
      _FakePlatformWebViewWidget(params);

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) =>
      _FakePlatformNavigationDelegate(params);
}

class _FakePlatformWebViewController extends Fake
    with MockPlatformInterfaceMixin
    implements PlatformWebViewController {
  _FakePlatformWebViewController(this.params);

  @override
  final PlatformWebViewControllerCreationParams params;

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}

  @override
  Future<void> setPlatformNavigationDelegate(
    PlatformNavigationDelegate handler,
  ) async {}

  @override
  Future<void> loadRequest(LoadRequestParams params) async {}

  @override
  Future<bool> canGoBack() async => false;

  @override
  Future<bool> canGoForward() async => false;

  @override
  Future<void> goBack() async {}

  @override
  Future<void> goForward() async {}
}

class _FakePlatformWebViewWidget extends Fake
    with MockPlatformInterfaceMixin
    implements PlatformWebViewWidget {
  _FakePlatformWebViewWidget(this.params);

  @override
  final PlatformWebViewWidgetCreationParams params;

  @override
  Widget build(BuildContext context) =>
      const SizedBox(key: Key('fake_webview'));
}

class _FakePlatformNavigationDelegate extends Fake
    with MockPlatformInterfaceMixin
    implements PlatformNavigationDelegate {
  _FakePlatformNavigationDelegate(this.params);

  @override
  final PlatformNavigationDelegateCreationParams params;

  @override
  Future<void> setOnNavigationRequest(
    NavigationRequestCallback onNavigationRequest,
  ) async {}

  @override
  Future<void> setOnPageFinished(PageEventCallback onPageFinished) async {}

  @override
  Future<void> setOnPageStarted(PageEventCallback onPageStarted) async {}

  @override
  Future<void> setOnProgress(ProgressCallback onProgress) async {}

  @override
  Future<void> setOnWebResourceError(
    WebResourceErrorCallback onWebResourceError,
  ) async {}

  @override
  Future<void> setOnUrlChange(UrlChangeCallback onUrlChange) async {}

  @override
  Future<void> setOnHttpAuthRequest(
    HttpAuthRequestCallback onHttpAuthRequest,
  ) async {}

  @override
  Future<void> setOnHttpError(
    HttpResponseErrorCallback onHttpError,
  ) async {}
}

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

  setUpAll(() {
    WebViewPlatform.instance = _FakeWebViewPlatform();
  });

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
    // Default stubs for Gutenberg providers triggered by adjacent-tab prebuild
    when(() => mockService.browseGutenberg(
          sort: any(named: 'sort'),
          limit: any(named: 'limit'),
        )).thenAnswer((_) async =>
        const GutenbergSearchResultModel(count: 0, results: []));
    when(() => mockService.searchGutenberg(
          any(),
          limit: any(named: 'limit'),
        )).thenAnswer((_) async =>
        const GutenbergSearchResultModel(count: 0, results: []));
  });

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

  group('Gutenberg tab - native UI', () {
    testWidgets('shows search bar on Gutenberg tab', (tester) async {
      stubDefaultMocks();
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gutenberg'));
      await tester.pumpAndSettle();

      expect(find.text('Search Gutenberg...'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('shows browse results as grid cards', (tester) async {
      stubDefaultMocks();
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

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gutenberg'));
      await tester.pumpAndSettle();

      expect(find.text('Pride and Prejudice'), findsOneWidget);
      expect(find.text('Austen, Jane'), findsOneWidget);
    });

    testWidgets('shows download count on book card', (tester) async {
      stubDefaultMocks();
      when(() => mockService.browseGutenberg(
            sort: any(named: 'sort'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => const GutenbergSearchResultModel(
            count: 1,
            results: [
              GutenbergBookModel(
                id: 1,
                title: 'Test Book',
                downloadCount: 50000,
              ),
            ],
          ));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gutenberg'));
      await tester.pumpAndSettle();

      expect(find.text('50.0K'), findsOneWidget);
    });

    testWidgets('shows placeholder icon when no cover image', (tester) async {
      stubDefaultMocks();
      when(() => mockService.browseGutenberg(
            sort: any(named: 'sort'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => const GutenbergSearchResultModel(
            count: 1,
            results: [
              GutenbergBookModel(id: 1, title: 'No Cover Book'),
            ],
          ));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gutenberg'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.auto_stories), findsWidgets);
    });

    testWidgets('search triggers search provider with query',
        (tester) async {
      stubDefaultMocks();
      when(() => mockService.searchGutenberg(
            'pride',
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => const GutenbergSearchResultModel(
            count: 1,
            results: [
              GutenbergBookModel(
                id: 1342,
                title: 'Pride and Prejudice',
                authors: ['Austen, Jane'],
              ),
            ],
          ));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gutenberg'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'pride');
      // Wait for debounce (500ms)
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      verify(() => mockService.searchGutenberg(
            'pride',
            limit: any(named: 'limit'),
          )).called(1);
    });

    testWidgets('import button visible for owner', (tester) async {
      stubDefaultMocks();
      when(() => mockService.browseGutenberg(
            sort: any(named: 'sort'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => const GutenbergSearchResultModel(
            count: 1,
            results: [
              GutenbergBookModel(id: 1, title: 'Book With Import'),
            ],
          ));

      await tester.pumpWidget(buildScreen(user: ownerUser));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gutenberg'));
      await tester.pumpAndSettle();

      expect(find.text('Import'), findsOneWidget);
    });

    testWidgets('import button hidden for member', (tester) async {
      stubDefaultMocks();
      when(() => mockService.browseGutenberg(
            sort: any(named: 'sort'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => const GutenbergSearchResultModel(
            count: 1,
            results: [
              GutenbergBookModel(id: 1, title: 'Book No Import'),
            ],
          ));

      await tester.pumpWidget(buildScreen(user: memberUser));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gutenberg'));
      await tester.pumpAndSettle();

      expect(find.text('Import'), findsNothing);
    });

    testWidgets('tapping import calls importGutenbergBook', (tester) async {
      stubDefaultMocks();
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

      await tester.tap(find.text('Gutenberg'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Import'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Import'));
      await tester.pumpAndSettle();

      verify(() => mockService.importGutenbergBook(42)).called(1);
      expect(find.text('"Importable Book" imported successfully'),
          findsOneWidget);
    });

    testWidgets('tapping card opens detail bottom sheet', (tester) async {
      stubDefaultMocks();
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

      await tester.tap(find.text('Gutenberg'));
      await tester.pumpAndSettle();

      // Tap the card (the title text)
      await tester.tap(find.text('Pride and Prejudice'));
      await tester.pumpAndSettle();

      // Detail sheet shows subjects
      expect(find.text('Subjects'), findsOneWidget);
      expect(find.text('Fiction'), findsOneWidget);
      expect(find.text('Romance'), findsOneWidget);
      expect(find.text('Import to Library'), findsOneWidget);
    });

    testWidgets('error state shows retry button', (tester) async {
      stubDefaultMocks();
      when(() => mockService.browseGutenberg(
            sort: any(named: 'sort'),
            limit: any(named: 'limit'),
          )).thenThrow(
          const ApiException(statusCode: 500, message: 'Server error'));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gutenberg'));
      await tester.pumpAndSettle();

      expect(find.text('Load Failed'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('empty browse shows empty state', (tester) async {
      stubDefaultMocks();

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gutenberg'));
      await tester.pumpAndSettle();

      expect(find.text('No books available'), findsOneWidget);
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

      await tester.pumpWidget(buildScreen(user: adminUser));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('member does not see delete option', (tester) async {
      stubEbooks([testEbook]);

      await tester.pumpWidget(buildScreen(user: memberUser));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.more_vert), findsNothing);
    });

    testWidgets('tapping delete shows confirmation dialog', (tester) async {
      stubEbooks([testEbook]);

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

      await tester.ensureVisible(find.byIcon(Icons.download));
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
                  speedBytesPerSecond: 524288,
                  estimatedSecondsRemaining: 60,
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
                  speedBytesPerSecond: 0,
                  estimatedSecondsRemaining: 0,
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

  @override
  Future<UserModel?> loginWithBiometric() async => null;
}
