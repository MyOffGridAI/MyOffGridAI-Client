import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/features/chat/widgets/thinking_indicator.dart';

void main() {
  Widget buildWidget() {
    return const MaterialApp(
      home: Scaffold(
        body: ThinkingIndicatorBubble(),
      ),
    );
  }

  group('ThinkingIndicatorBubble', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byType(ThinkingIndicatorBubble), findsOneWidget);
    });

    testWidgets('renders three animated dots', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      // There should be 3 dot containers (the child: Container with
      // BoxShape.circle)
      final dots = find.descendant(
        of: find.byType(ThinkingIndicatorBubble),
        matching: find.byWidgetPredicate((w) {
          if (w is Container && w.decoration is BoxDecoration) {
            final dec = w.decoration as BoxDecoration;
            return dec.shape == BoxShape.circle;
          }
          return false;
        }),
      );

      expect(dots, findsNWidgets(3));
    });

    testWidgets('is left-aligned', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      final align = tester.widget<Align>(find.byType(Align));
      expect(align.alignment, Alignment.centerLeft);
    });

    testWidgets('contains a row for dots', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      // There should be a Row inside the bubble
      expect(
        find.descendant(
          of: find.byType(ThinkingIndicatorBubble),
          matching: find.byType(Row),
        ),
        findsOneWidget,
      );
    });

    testWidgets('animates over time without errors', (tester) async {
      await tester.pumpWidget(buildWidget());

      // Pump several frames to exercise the animation
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }

      // Widget still renders
      expect(find.byType(ThinkingIndicatorBubble), findsOneWidget);
    });

    testWidgets('has rounded container decoration', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      // The outer container has a rounded border
      final container = tester.widgetList<Container>(find.byType(Container))
          .where((c) =>
              c.decoration is BoxDecoration &&
              (c.decoration as BoxDecoration).borderRadius != null)
          .toList();

      expect(container, isNotEmpty);
    });
  });
}
