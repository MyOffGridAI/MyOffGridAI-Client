import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/features/books/kiwix_categories_screen.dart';

void main() {
  Widget buildScreen({GoRouter? router}) {
    if (router != null) {
      return MaterialApp.router(routerConfig: router);
    }
    return const MaterialApp(home: KiwixCategoriesScreen());
  }

  group('KiwixCategoriesScreen', () {
    testWidgets('shows app bar title', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Kiwix Categories'), findsOneWidget);
    });

    testWidgets('shows Wikipedia category', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Wikipedia'), findsOneWidget);
    });

    testWidgets('shows Gutenberg category', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Gutenberg'), findsOneWidget);
    });

    testWidgets('shows Stack Exchange category', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // May need to scroll to find it
      final gridView = find.byType(GridView);
      await tester.drag(gridView, const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.text('Stack Exchange'), findsOneWidget);
    });

    testWidgets('shows category icons', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.language), findsOneWidget);
      expect(find.byIcon(Icons.auto_stories), findsOneWidget);
    });

    testWidgets('shows category descriptions', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Encyclopedia'), findsOneWidget);
      expect(find.text('Project Gutenberg books'), findsOneWidget);
    });

    testWidgets('displays 17 categories in grid', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('tapping category navigates to category content screen',
        (tester) async {
      String? navigatedExtra;
      String? navigatedPath;

      final router = GoRouter(
        initialLocation: '/categories',
        routes: [
          GoRoute(
            path: '/categories',
            builder: (_, __) => const KiwixCategoriesScreen(),
          ),
          GoRoute(
            path: AppConstants.routeKiwixCategoryContent,
            builder: (_, state) {
              navigatedExtra = state.extra as String?;
              navigatedPath = state.matchedLocation;
              return const Scaffold(body: Text('Category Content'));
            },
          ),
        ],
      );

      await tester.pumpWidget(buildScreen(router: router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Wikipedia'));
      await tester.pumpAndSettle();

      expect(navigatedPath, AppConstants.routeKiwixCategoryContent);
      expect(navigatedExtra, 'wikipedia');
    });

    testWidgets('shows Wiktionary category', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final gridView = find.byType(GridView);
      await tester.drag(gridView, const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.text('Wiktionary'), findsOneWidget);
    });
  });
}
