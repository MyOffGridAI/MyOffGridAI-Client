import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/features/chat/widgets/inference_metadata_row.dart';

void main() {
  group('InferenceMetadataRow', () {
    testWidgets('shows inference time', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InferenceMetadataRow(
              inferenceTimeSeconds: 3.2,
            ),
          ),
        ),
      );

      expect(find.textContaining('3.2s'), findsOneWidget);
    });

    testWidgets('shows tokens per second', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InferenceMetadataRow(
              tokensPerSecond: 42.5,
            ),
          ),
        ),
      );

      expect(find.textContaining('42.5 tok/s'), findsOneWidget);
    });

    testWidgets('shows stop reason', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InferenceMetadataRow(
              stopReason: 'stop',
            ),
          ),
        ),
      );

      expect(find.textContaining('stop'), findsOneWidget);
    });

    testWidgets('shows all three values joined by dots', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InferenceMetadataRow(
              inferenceTimeSeconds: 2.1,
              tokensPerSecond: 55.0,
              stopReason: 'length',
            ),
          ),
        ),
      );

      // The widget joins parts with ' \u00b7 ' (middle dot)
      expect(find.text('2.1s \u00b7 55.0 tok/s \u00b7 length'), findsOneWidget);
    });

    testWidgets('shows speed icon when at least one value is present',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InferenceMetadataRow(
              tokensPerSecond: 30.0,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.speed), findsOneWidget);
    });

    testWidgets('returns SizedBox.shrink when all values are null',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InferenceMetadataRow(),
          ),
        ),
      );

      // Should render as SizedBox.shrink — no Row, no Text, no Icon
      expect(find.byType(Row), findsNothing);
      expect(find.byIcon(Icons.speed), findsNothing);
    });

    testWidgets('does not show empty stop reason', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InferenceMetadataRow(
              inferenceTimeSeconds: 1.5,
              stopReason: '',
            ),
          ),
        ),
      );

      // Only inference time shown, no dot separator for empty stopReason
      expect(find.text('1.5s'), findsOneWidget);
    });

    testWidgets('formats decimal values to one decimal place', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InferenceMetadataRow(
              inferenceTimeSeconds: 3.14159,
              tokensPerSecond: 42.678,
            ),
          ),
        ),
      );

      expect(find.textContaining('3.1s'), findsOneWidget);
      expect(find.textContaining('42.7 tok/s'), findsOneWidget);
    });
  });
}
