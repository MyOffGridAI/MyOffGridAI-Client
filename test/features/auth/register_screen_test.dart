import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/auth/secure_storage_service.dart';
import 'package:myoffgridai_client/features/auth/register_screen.dart';

class _FakeSecureStorageService extends SecureStorageService {
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
  Future<void> saveServerUrl(String url) async {}
  @override
  Future<String> getServerUrl() async => AppConstants.defaultServerUrl;
  @override
  Future<void> saveThemePreference(String theme) async {}
  @override
  Future<String> getThemePreference() async => 'system';
}

void main() {
  group('RegisterScreen', () {
    Widget buildRegisterScreen() {
      final router = GoRouter(
        initialLocation: AppConstants.routeRegister,
        routes: [
          GoRoute(
            path: AppConstants.routeRegister,
            builder: (_, __) => const RegisterScreen(),
          ),
          GoRoute(
            path: AppConstants.routeLogin,
            builder: (_, __) =>
                const Scaffold(body: Text('Login')),
          ),
          GoRoute(
            path: AppConstants.routeHome,
            builder: (_, __) =>
                const Scaffold(body: Text('Home')),
          ),
        ],
      );

      return ProviderScope(
        overrides: [
          secureStorageProvider
              .overrideWithValue(_FakeSecureStorageService()),
        ],
        child: MaterialApp.router(routerConfig: router),
      );
    }

    testWidgets('all required fields are present', (tester) async {
      await tester.pumpWidget(buildRegisterScreen());
      await tester.pumpAndSettle();

      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Display Name'), findsOneWidget);
      expect(find.text('Email (optional)'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('Register'), findsOneWidget);
    });

    testWidgets('shows Create Account title', (tester) async {
      await tester.pumpWidget(buildRegisterScreen());
      await tester.pumpAndSettle();

      expect(find.text('Create Account'), findsOneWidget);
    });

    testWidgets('shows back arrow', (tester) async {
      await tester.pumpWidget(buildRegisterScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('shows field icons', (tester) async {
      await tester.pumpWidget(buildRegisterScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person_outline), findsOneWidget);
      expect(find.byIcon(Icons.badge_outlined), findsOneWidget);
      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
      // Two lock_outline: one for password, one for confirm password
      expect(find.byIcon(Icons.lock_outline), findsNWidgets(2));
    });

    testWidgets('validates empty username', (tester) async {
      await tester.pumpWidget(buildRegisterScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      expect(find.text('Username is required'), findsOneWidget);
    });

    testWidgets('validates username minimum length', (tester) async {
      await tester.pumpWidget(buildRegisterScreen());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'),
        'ab',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Display Name'),
        'Test User',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'pass',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm Password'),
        'pass',
      );

      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('at least ${AppConstants.usernameMinLength}'),
        findsOneWidget,
      );
    });

    testWidgets('validates required display name', (tester) async {
      await tester.pumpWidget(buildRegisterScreen());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'),
        'testuser',
      );

      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      expect(find.text('Display name is required'), findsOneWidget);
    });

    testWidgets('validates empty password', (tester) async {
      await tester.pumpWidget(buildRegisterScreen());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'),
        'testuser',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Display Name'),
        'Test User',
      );

      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('validates password minimum length', (tester) async {
      await tester.pumpWidget(buildRegisterScreen());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'),
        'testuser',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Display Name'),
        'Test User',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'ab',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm Password'),
        'ab',
      );

      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('at least ${AppConstants.passwordMinLength}'),
        findsOneWidget,
      );
    });

    testWidgets('password mismatch shows error', (tester) async {
      await tester.pumpWidget(buildRegisterScreen());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'),
        'testuser',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Display Name'),
        'Test User',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password1',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm Password'),
        'password2',
      );

      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('has back to login link', (tester) async {
      await tester.pumpWidget(buildRegisterScreen());
      await tester.pumpAndSettle();

      expect(find.text('Back to login'), findsOneWidget);
    });

    testWidgets('shows password visibility toggles', (tester) async {
      await tester.pumpWidget(buildRegisterScreen());
      await tester.pumpAndSettle();

      // Two visibility_off icons (password + confirm password)
      expect(find.byIcon(Icons.visibility_off), findsNWidgets(2));
    });

    testWidgets('toggles password visibility', (tester) async {
      await tester.pumpWidget(buildRegisterScreen());
      await tester.pumpAndSettle();

      // Tap the first visibility toggle (password field)
      await tester.tap(find.byIcon(Icons.visibility_off).first);
      await tester.pumpAndSettle();

      // Now one visibility_off (confirm) and one visibility (password)
      expect(find.byIcon(Icons.visibility), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('navigates to login on back to login tap', (tester) async {
      await tester.pumpWidget(buildRegisterScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Back to login'));
      await tester.pumpAndSettle();

      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('navigates to login on back arrow tap', (tester) async {
      await tester.pumpWidget(buildRegisterScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('toggles confirm password visibility', (tester) async {
      await tester.pumpWidget(buildRegisterScreen());
      await tester.pumpAndSettle();

      // Both visibility_off initially
      expect(find.byIcon(Icons.visibility_off), findsNWidgets(2));

      // Tap the second visibility toggle (confirm password field)
      await tester.tap(find.byIcon(Icons.visibility_off).last);
      await tester.pumpAndSettle();

      // Now one visibility_off (password) and one visibility (confirm)
      expect(find.byIcon(Icons.visibility), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('successful registration navigates to home', (tester) async {
      await tester.pumpWidget(buildRegisterScreen());
      await tester.pumpAndSettle();

      // Fill in all fields with valid data
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'),
        'testuser',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Display Name'),
        'Test User',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email (optional)'),
        'test@test.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm Password'),
        'password123',
      );

      await tester.tap(find.text('Register'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Should navigate to home (registration is a no-op in fake auth)
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('confirm password onFieldSubmitted triggers register',
        (tester) async {
      await tester.pumpWidget(buildRegisterScreen());
      await tester.pumpAndSettle();

      // Fill in valid data
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'),
        'testuser',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Display Name'),
        'Test User',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm Password'),
        'password123',
      );

      // Submit from confirm password field
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Should navigate to home
      expect(find.text('Home'), findsOneWidget);
    });

    // Note: Registration error handling (lines 58-65) requires overriding
    // authStateProvider with a notifier that sets state = AsyncError. In tests,
    // ref.read(authStateProvider) after notifier.register() does not see the
    // AsyncError set by the notifier in the same synchronous frame, causing the
    // screen to navigate to home instead of showing the error SnackBar.
    // These lines cannot be covered without modifying lib/ code.
  });
}
