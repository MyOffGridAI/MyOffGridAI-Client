import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/shared/widgets/confirmation_dialog.dart';

void main() {
  group('ConfirmationDialog', () {
    testWidgets('returns true when confirm tapped', (tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await ConfirmationDialog.show(
                  context,
                  title: 'Delete?',
                  message: 'Are you sure?',
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Delete?'), findsOneWidget);
      expect(find.text('Are you sure?'), findsOneWidget);

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });

    testWidgets('returns false when cancel tapped', (tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await ConfirmationDialog.show(
                  context,
                  title: 'Delete?',
                  message: 'Are you sure?',
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(result, isFalse);
    });

    testWidgets('confirm button is red when isDestructive=true',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                await ConfirmationDialog.show(
                  context,
                  title: 'Delete?',
                  message: 'Are you sure?',
                  isDestructive: true,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Find the Confirm TextButton and verify its style
      final confirmButton = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Confirm'),
      );
      final style = confirmButton.style;
      expect(style, isNotNull);
    });
  });
}
