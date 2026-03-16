import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/providers.dart';
import 'package:myoffgridai_client/features/auth/device_not_setup_screen.dart';

void main() {
  group('DeviceNotSetupScreen', () {
    Widget buildScreen({bool initialized = false}) {
      final router = GoRouter(
        initialLocation: AppConstants.routeDeviceNotSetup,
        routes: [
          GoRoute(
            path: AppConstants.routeDeviceNotSetup,
            builder: (_, __) => const DeviceNotSetupScreen(),
          ),
          GoRoute(
            path: AppConstants.routeLogin,
            builder: (_, __) =>
                const Scaffold(body: Text('Login')),
          ),
        ],
      );

      return ProviderScope(
        overrides: [
          systemStatusProvider.overrideWith(
            (ref) async => SystemStatusDto(initialized: initialized),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      );
    }

    testWidgets('shows setup instructions', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('MyOffGrid AI Not Set Up'), findsOneWidget);
      expect(find.textContaining('WiFi settings'), findsOneWidget);
      expect(find.textContaining('MyOffGridAI-Setup'), findsOneWidget);
      expect(find.textContaining('setup page'), findsOneWidget);
      expect(find.textContaining('configure your device'), findsOneWidget);
    });

    testWidgets('retry button is present', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('shows wifi icon', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.wifi_tethering), findsOneWidget);
    });

    testWidgets('shows numbered steps', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('retry navigates to login when initialized', (tester) async {
      await tester.pumpWidget(buildScreen(initialized: true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('retry stays on screen when not initialized', (tester) async {
      await tester.pumpWidget(buildScreen(initialized: false));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('MyOffGrid AI Not Set Up'), findsOneWidget);
    });

    testWidgets('retry stays on screen when status check throws',
        (tester) async {
      final router = GoRouter(
        initialLocation: AppConstants.routeDeviceNotSetup,
        routes: [
          GoRoute(
            path: AppConstants.routeDeviceNotSetup,
            builder: (_, __) => const DeviceNotSetupScreen(),
          ),
          GoRoute(
            path: AppConstants.routeLogin,
            builder: (_, __) =>
                const Scaffold(body: Text('Login')),
          ),
        ],
      );

      await tester.pumpWidget(ProviderScope(
        overrides: [
          systemStatusProvider.overrideWith(
            (ref) async => throw Exception('network error'),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // Should stay on setup screen
      expect(find.text('MyOffGrid AI Not Set Up'), findsOneWidget);
    });
  });
}
