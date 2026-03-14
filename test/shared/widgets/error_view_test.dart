import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/shared/widgets/error_view.dart';

void main() {
  group('ErrorView', () {
    testWidgets('shows retry button when callback provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorView(
              title: 'Error',
              message: 'Something went wrong',
              onRetry: () {},
            ),
          ),
        ),
      );
      expect(find.text('Error'), findsOneWidget);
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('hides retry button when callback is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorView(
              title: 'Error',
              message: 'Something went wrong',
            ),
          ),
        ),
      );
      expect(find.text('Error'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('retry callback fires on tap', (tester) async {
      bool retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorView(
              title: 'Error',
              message: 'Something went wrong',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
    });

    testWidgets('shows error icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorView(
              title: 'Error',
              message: 'msg',
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });
}
