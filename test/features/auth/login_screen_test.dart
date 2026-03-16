import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
// ignore_for_file: unnecessary_underscores
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/myoffgridai_api_client.dart';
import 'package:myoffgridai_client/core/auth/secure_storage_service.dart';
import 'package:myoffgridai_client/features/auth/login_screen.dart';

class MockApiClient extends Mock implements MyOffGridAIApiClient {}

class _FakeSecureStorageService extends SecureStorageService {
  String _serverUrl = AppConstants.defaultServerUrl;
  String _theme = 'system';

  _FakeSecureStorageService() : super(storage: null);

  @override
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {}
  @override
  Future<String?> getAccessToken() async => null;
  @override
  Future<String?> getRefreshToken() async => null;
  @override
  Future<void> clearTokens() async {}
  @override
  Future<void> saveServerUrl(String url) async => _serverUrl = url;
  @override
  Future<String> getServerUrl() async => _serverUrl;
  @override
  Future<void> saveThemePreference(String theme) async => _theme = theme;
  @override
  Future<String> getThemePreference() async => _theme;
}

void main() {
  group('LoginScreen', () {
    late _FakeSecureStorageService fakeStorage;

    setUp(() {
      fakeStorage = _FakeSecureStorageService();
    });

    Widget buildLoginScreen() {
      final router = GoRouter(
        initialLocation: AppConstants.routeLogin,
        routes: [
          GoRoute(
            path: AppConstants.routeLogin,
            builder: (_, __) => const LoginScreen(),
          ),
          GoRoute(
            path: AppConstants.routeHome,
            builder: (_, __) =>
                const Scaffold(body: Text('Home')),
          ),
          GoRoute(
            path: AppConstants.routeRegister,
            builder: (_, __) =>
                const Scaffold(body: Text('Register')),
          ),
        ],
      );

      return ProviderScope(
        overrides: [
          secureStorageProvider.overrideWithValue(fakeStorage),
        ],
        child: MaterialApp.router(routerConfig: router),
      );
    }

    testWidgets('username and password fields present', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('shows MyOffGrid AI branding', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      expect(find.text('MyOffGrid AI'), findsOneWidget);
      expect(find.text('Your world, remembered.'), findsOneWidget);
    });

    testWidgets('shows server URL that is tappable', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Server:'),
        findsOneWidget,
      );
    });

    testWidgets('validates empty username', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      expect(find.text('Username is required'), findsOneWidget);
    });

    testWidgets('validates empty password', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'),
        'testuser',
      );
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('has create account link', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      expect(find.text('Create an account'), findsOneWidget);
    });

    testWidgets('shows person icon for username field', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });

    testWidgets('shows lock icon for password field', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('shows password visibility toggle', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      // Initially shows visibility_off (password is obscured)
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('toggles password visibility on icon tap', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      // Initially password is obscured
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);

      // Tap the visibility toggle
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pumpAndSettle();

      // Now visibility icon should show
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('navigate to register on create account tap', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create an account'));
      await tester.pumpAndSettle();

      expect(find.text('Register'), findsOneWidget);
    });

    testWidgets('shows server URL dialog on server URL tap', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Server:'));
      await tester.pumpAndSettle();

      expect(find.text('Server URL'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('shows both validation errors when all empty', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      expect(find.text('Username is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('successful login navigates to home', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'),
        'adam',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'pass',
      );

      await tester.tap(find.text('Login'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Login in fake notifier is a no-op, state returns data null (no error)
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('password onFieldSubmitted triggers login', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'),
        'adam',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'pass',
      );

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    });

    // Note: Login error handling (lines 64-71) requires overriding
    // authStateProvider with a notifier that sets state = AsyncError. In tests,
    // ref.read(authStateProvider) after notifier.login() does not see the
    // AsyncError set by the notifier in the same synchronous frame, causing the
    // screen to navigate to home instead of showing the error SnackBar.
    // These lines cannot be covered without modifying lib/ code.

    // Note: _showServerUrlDialog save flow (lines 108-114) requires
    // apiClientProvider.updateBaseUrl which has complex initialization
    // dependencies. These lines cannot be covered without modifying lib/ code.
  });
}
