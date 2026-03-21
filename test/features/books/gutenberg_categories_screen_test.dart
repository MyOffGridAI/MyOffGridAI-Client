import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/features/books/gutenberg_categories_screen.dart';

void main() {
  Widget buildScreen({GoRouter? router}) {
    if (router != null) {
      return MaterialApp.router(routerConfig: router);
    }
    return const MaterialApp(home: GutenbergCategoriesScreen());
  }

  group('GutenbergCategoriesScreen', () {
    testWidgets('shows app bar title', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Gutenberg Categories'), findsOneWidget);
    });

    testWidgets('shows Literature group header', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Literature'), findsOneWidget);
    });

    testWidgets('shows History group header', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('History'), findsOneWidget);
    });

    testWidgets('shows Science & Technology group header', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Scroll down to reveal the Science & Technology group
      final listView = find.byType(ListView);
      await tester.drag(listView, const Offset(0, -800));
      await tester.pumpAndSettle();

      expect(find.text('Science & Technology'), findsOneWidget);
    });

    testWidgets('shows Literature sub-categories', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Adventure'), findsOneWidget);
      expect(find.text('Fiction'), findsOneWidget);
      expect(find.text('Poetry'), findsOneWidget);
      expect(find.text('Science Fiction'), findsOneWidget);
    });

    testWidgets('shows category card icons', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.explore), findsOneWidget);
      expect(find.byIcon(Icons.menu_book), findsOneWidget);
    });

    testWidgets('tapping category navigates to category books screen',
        (tester) async {
      String? navigatedExtra;
      String? navigatedPath;

      final router = GoRouter(
        initialLocation: '/categories',
        routes: [
          GoRoute(
            path: '/categories',
            builder: (_, __) => const GutenbergCategoriesScreen(),
          ),
          GoRoute(
            path: AppConstants.routeGutenbergCategoryBooks,
            builder: (_, state) {
              navigatedExtra = state.extra as String?;
              navigatedPath = state.matchedLocation;
              return const Scaffold(body: Text('Category Books'));
            },
          ),
        ],
      );

      await tester.pumpWidget(buildScreen(router: router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Adventure'));
      await tester.pumpAndSettle();

      expect(navigatedPath, AppConstants.routeGutenbergCategoryBooks);
      expect(navigatedExtra, 'Adventure');
    });

    testWidgets('shows all 8 group headers when scrolled', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final listView = find.byType(ListView);
      expect(listView, findsOneWidget);

      // First visible groups
      expect(find.text('Literature'), findsOneWidget);

      // Scroll to reveal all groups
      await tester.drag(listView, const Offset(0, -1000));
      await tester.pumpAndSettle();

      await tester.drag(listView, const Offset(0, -1000));
      await tester.pumpAndSettle();

      await tester.drag(listView, const Offset(0, -1000));
      await tester.pumpAndSettle();

      await tester.drag(listView, const Offset(0, -1000));
      await tester.pumpAndSettle();

      expect(find.text('Education & Reference'), findsOneWidget);
    });

    testWidgets('shows dividers between groups', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byType(Divider), findsWidgets);
    });
  });
}
