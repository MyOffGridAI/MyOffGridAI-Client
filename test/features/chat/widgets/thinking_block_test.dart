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

        expect(find.textContaining('Thought process'), findsOneWidget);
      });

      testWidgets('shows down-triangle character in collapsed chip',
          (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ThinkingBlock(content: 'Some thinking'),
            ),
          ),
        );
        await tester.pump();

        expect(find.textContaining('\u25be'), findsOneWidget);
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

      testWidgets('shows thought-balloon emoji', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ThinkingBlock(content: 'Reasoning'),
            ),
          ),
        );
        await tester.pump();

        expect(find.textContaining('\u{1F4AD}'), findsOneWidget);
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
          find.text('Thought process \u00b7 42 tokens \u25be'),
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

        expect(find.text('Thought process \u25be'), findsOneWidget);
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
        await tester.tap(find.textContaining('Thought process'));
        await tester.pump();

        // Expanded: content visible
        expect(find.text('Detailed thinking text'), findsOneWidget);
      });

      testWidgets('expanded state shows up-triangle for collapsing',
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
        await tester.tap(find.textContaining('Thought process'));
        await tester.pump();

        expect(find.textContaining('\u25b4'), findsOneWidget);
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
        await tester.tap(find.textContaining('Thought process'));
        await tester.pump();

        expect(find.text('Collapsible reasoning'), findsOneWidget);

        // Collapse by tapping the header in expanded state
        await tester.tap(find.textContaining('Thought process'));
        await tester.pump();

        expect(find.text('Collapsible reasoning'), findsNothing);
      });
    });

    // ── Streaming state ───────────────────────────────────────────────────
    group('streaming state', () {
      testWidgets('shows thought-balloon emoji and "Thinking..." with progress indicator',
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
        expect(find.textContaining('\u{1F4AD}'), findsOneWidget);
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

      testWidgets(
          'shows Thinking... header with spinner when content is empty and isStreaming',
          (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ThinkingBlock(
                content: '',
                isStreaming: true,
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Thinking...'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        // No content text area should be visible
        expect(find.byType(SingleChildScrollView), findsNothing);
      });

      testWidgets('hides content area when content is empty during streaming',
          (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ThinkingBlock(
                content: '',
                isStreaming: true,
              ),
            ),
          ),
        );
        await tester.pump();

        // ConstrainedBox wrapping the scroll view should not exist
        final constrainedBoxes = tester.widgetList<ConstrainedBox>(
          find.byType(ConstrainedBox),
        );
        final match = constrainedBoxes.where(
          (cb) => cb.constraints.maxHeight == 200,
        );
        expect(match, isEmpty);
      });

      testWidgets(
          'shows content area when content is non-empty during streaming',
          (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ThinkingBlock(
                content: 'Reasoning text',
                isStreaming: true,
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Reasoning text'), findsOneWidget);
        expect(find.byType(SingleChildScrollView), findsOneWidget);
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
          await tester.pump(const Duration(milliseconds: 120));
        }

        expect(find.byType(ThinkingBlock), findsOneWidget);
      });
    });

    // ── Widget lifecycle ──────────────────────────────────────────────────
    group('widget lifecycle', () {
      testWidgets(
          'transitions from streaming to collapsed after 500ms delay',
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

        // After stopping, the streaming UI disappears but the block
        // should still be expanded (showing full content) during grace period
        // Pump past the 500ms delay
        await tester.pump(const Duration(milliseconds: 500));

        // Should collapse; "Thinking..." gone, chip shown
        expect(find.text('Thinking...'), findsNothing);
        expect(find.textContaining('Thought process'), findsOneWidget);
      });

      testWidgets('remains expanded during 500ms grace period',
          (tester) async {
        // Start streaming
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ThinkingBlock(
                content: 'Grace period thought',
                isStreaming: true,
              ),
            ),
          ),
        );
        await tester.pump();

        // Stop streaming
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ThinkingBlock(
                content: 'Grace period thought',
                isStreaming: false,
              ),
            ),
          ),
        );
        await tester.pump();

        // At 250ms: still expanded (content visible)
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.text('Grace period thought'), findsOneWidget);

        // At 500ms: collapses
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.text('Grace period thought'), findsNothing);
        expect(find.textContaining('Thought process'), findsOneWidget);
      });

      testWidgets('auto-scrolls when content changes during streaming',
          (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ThinkingBlock(
                content: 'Short',
                isStreaming: true,
              ),
            ),
          ),
        );
        await tester.pump();

        // Update with longer content
        final longContent = 'Short\n' * 50;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ThinkingBlock(
                content: longContent,
                isStreaming: true,
              ),
            ),
          ),
        );
        await tester.pump();

        // Verify SingleChildScrollView exists (auto-scroll mechanism)
        expect(find.byType(SingleChildScrollView), findsOneWidget);
      });

      testWidgets('applies 200px max height during streaming',
          (tester) async {
        final manyLines = 'Line\n' * 100;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ThinkingBlock(
                content: manyLines,
                isStreaming: true,
              ),
            ),
          ),
        );
        await tester.pump();

        final constrainedBoxes = tester.widgetList<ConstrainedBox>(
          find.byType(ConstrainedBox),
        );
        final match = constrainedBoxes.where(
          (cb) => cb.constraints.maxHeight == 200,
        );
        expect(match, isNotEmpty);
      });

      testWidgets('user can expand collapsed chip after stream ends',
          (tester) async {
        // Start streaming
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ThinkingBlock(
                content: 'Re-expandable content',
                isStreaming: true,
              ),
            ),
          ),
        );
        await tester.pump();

        // Stop streaming and wait for collapse
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ThinkingBlock(
                content: 'Re-expandable content',
                isStreaming: false,
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 500));

        // Verify collapsed
        expect(find.textContaining('Thought process'), findsOneWidget);
        expect(find.text('Re-expandable content'), findsNothing);

        // Tap to expand
        await tester.tap(find.textContaining('Thought process'));
        await tester.pump();

        // Content visible again
        expect(find.text('Re-expandable content'), findsOneWidget);
      });
    });
  });
}
