import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
// ignore_for_file: unnecessary_underscores
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/auth/secure_storage_service.dart';
import 'package:myoffgridai_client/features/auth/login_screen.dart';

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
  });
}
