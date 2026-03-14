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
  });
}
