import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/features/chat/widgets/thinking_block.dart';

void main() {
  group('ThinkingBlock', () {
    // ── Collapsed state (default) ─────────────────────────────────────────
    group('collapsed state', () {
      testWidgets('shows "Thought process" text', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ThinkingBlock(content: 'Internal reasoning text'),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Thought process'), findsOneWidget);
      });

      testWidgets('shows expand_more icon', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ThinkingBlock(content: 'Some thinking'),
            ),
          ),
        );
        await tester.pump();

        expect(find.byIcon(Icons.expand_more), findsOneWidget);
      });

      testWidgets('does not show the full content text', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ThinkingBlock(content: 'Hidden reasoning details'),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Hidden reasoning details'), findsNothing);
      });

      testWidgets('shows psychology icon', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ThinkingBlock(content: 'Reasoning'),
            ),
          ),
        );
        await tester.pump();

        expect(find.byIcon(Icons.psychology), findsOneWidget);
      });
    });

    // ── thinkingTokenCount display ────────────────────────────────────────
    group('thinkingTokenCount', () {
      testWidgets('shows token count when thinkingTokenCount is provided',
          (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ThinkingBlock(
                content: 'Some reasoning',
                thinkingTokenCount: 42,
              ),
            ),
          ),
        );
        await tester.pump();

        expect(
          find.text('Thought process \u00b7 42 tokens'),
          findsOneWidget,
        );
      });

      testWidgets('shows plain label when thinkingTokenCount is null',
          (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ThinkingBlock(content: 'Reasoning'),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Thought process'), findsOneWidget);
      });
    });

    // ── Tapping to expand ─────────────────────────────────────────────────
    group('expand on tap', () {
      testWidgets('tapping collapsed block expands to show full content',
          (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ThinkingBlock(content: 'Detailed thinking text'),
            ),
          ),
        );
        await tester.pump();

        // Collapsed: content hidden
        expect(find.text('Detailed thinking text'), findsNothing);

        // Tap to expand
        await tester.tap(find.text('Thought process'));
        await tester.pump();

        // Expanded: content visible
        expect(find.text('Detailed thinking text'), findsOneWidget);
      });

      testWidgets('expanded state shows expand_less icon for collapsing',
          (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ThinkingBlock(content: 'Think'),
            ),
          ),
        );
        await tester.pump();

        // Tap to expand
        await tester.tap(find.text('Thought process'));
        await tester.pump();

        expect(find.byIcon(Icons.expand_less), findsOneWidget);
      });

      testWidgets('tapping expanded header collapses back', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ThinkingBlock(content: 'Collapsible reasoning'),
            ),
          ),
        );
        await tester.pump();

        // Expand
        await tester.tap(find.text('Thought process'));
        await tester.pump();

        expect(find.text('Collapsible reasoning'), findsOneWidget);

        // Collapse by tapping the header row in expanded state
        await tester.tap(find.text('Thought process'));
        await tester.pump();

        expect(find.text('Collapsible reasoning'), findsNothing);
      });
    });

    // ── Streaming state ───────────────────────────────────────────────────
    group('streaming state', () {
      testWidgets('shows "Thinking..." text with progress indicator',
          (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ThinkingBlock(
                content: 'Streaming thought',
                isStreaming: true,
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Thinking...'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('displays content during streaming', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ThinkingBlock(
                content: 'Live streaming content',
                isStreaming: true,
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Live streaming content'), findsOneWidget);
      });

      testWidgets('renders without crashing during animation',
          (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ThinkingBlock(
                content: 'Animation test',
                isStreaming: true,
              ),
            ),
          ),
        );

        // Pump multiple frames to exercise the pulse animation
        for (int i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 150));
        }

        expect(find.byType(ThinkingBlock), findsOneWidget);
      });
    });

    // ── Widget lifecycle ──────────────────────────────────────────────────
    group('widget lifecycle', () {
      testWidgets('transitions from streaming to collapsed when isStreaming becomes false',
          (tester) async {
        // Start streaming
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ThinkingBlock(
                content: 'Thought',
                isStreaming: true,
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Thinking...'), findsOneWidget);

        // Stop streaming
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ThinkingBlock(
                content: 'Thought',
                isStreaming: false,
              ),
            ),
          ),
        );
        await tester.pump();

        // Should collapse; "Thinking..." gone, "Thought process" chip shown
        expect(find.text('Thinking...'), findsNothing);
        expect(find.text('Thought process'), findsOneWidget);
      });
    });
  });
}
