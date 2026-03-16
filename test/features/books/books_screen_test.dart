import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/core/api/myoffgridai_api_client.dart';
import 'package:myoffgridai_client/core/auth/auth_state.dart';
import 'package:myoffgridai_client/core/models/library_models.dart';
import 'package:myoffgridai_client/core/models/user_model.dart';
import 'package:myoffgridai_client/core/services/library_service.dart';
import 'package:myoffgridai_client/features/books/books_screen.dart';

class MockLibraryService extends Mock implements LibraryService {}

void main() {
  late MockLibraryService mockService;

  setUp(() {
    mockService = MockLibraryService();
  });

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

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Library'), findsOneWidget);
      expect(find.text('Kiwix'), findsOneWidget);
      expect(find.text('Gutenberg'), findsOneWidget);
    });

    testWidgets('shows app bar with title', (tester) async {
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

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Books'), findsOneWidget);
    });

    testWidgets('shows empty state when no ebooks', (tester) async {
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

      await tester.pumpWidget(buildScreen(user: owner));
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

      await tester.pumpWidget(buildScreen(user: member));
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

    testWidgets('Gutenberg tab shows search field', (tester) async {
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

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Tap on Gutenberg tab
      await tester.tap(find.text('Gutenberg'));
      await tester.pumpAndSettle();

      expect(find.text('Search Project Gutenberg...'), findsOneWidget);
    });

    testWidgets('Kiwix tab shows unavailable when server is down',
        (tester) async {
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

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Tap on Kiwix tab
      await tester.tap(find.text('Kiwix'));
      await tester.pumpAndSettle();

      expect(find.text('Kiwix Unavailable'), findsOneWidget);
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
