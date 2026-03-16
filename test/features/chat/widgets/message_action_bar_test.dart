import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/core/models/message_model.dart';
import 'package:myoffgridai_client/features/chat/widgets/message_action_bar.dart';

void main() {
  /// Helper to build a user message.
  MessageModel userMessage() => const MessageModel(
        id: 'msg-user',
        role: 'USER',
        content: 'Hello',
        hasRagContext: false,
      );

  /// Helper to build an assistant message.
  MessageModel assistantMessage() => const MessageModel(
        id: 'msg-assistant',
        role: 'ASSISTANT',
        content: 'Hi there',
        hasRagContext: false,
      );

  group('MessageActionBar', () {
    // ── Button visibility per role ────────────────────────────────────────
    group('button visibility for user messages', () {
      testWidgets('shows copy, edit, branch, delete for user messages',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MessageActionBar(
                message: userMessage(),
                onCopy: () {},
                onEdit: () {},
                onDelete: () {},
                onBranch: () {},
              ),
            ),
          ),
        );

        // Buttons are rendered (even if invisible at opacity 0)
        expect(find.byIcon(Icons.copy), findsOneWidget);
        expect(find.byIcon(Icons.edit), findsOneWidget);
        expect(find.byIcon(Icons.delete_outline), findsOneWidget);
        expect(find.byIcon(Icons.call_split), findsOneWidget);
        // Regenerate is assistant-only
        expect(find.byIcon(Icons.refresh), findsNothing);
      });
    });

    group('button visibility for assistant messages', () {
      testWidgets(
          'shows copy, regenerate, branch, delete for assistant messages',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MessageActionBar(
                message: assistantMessage(),
                onCopy: () {},
                onRegenerate: () {},
                onDelete: () {},
                onBranch: () {},
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.copy), findsOneWidget);
        expect(find.byIcon(Icons.refresh), findsOneWidget);
        expect(find.byIcon(Icons.call_split), findsOneWidget);
        expect(find.byIcon(Icons.delete_outline), findsOneWidget);
        // Edit is user-only
        expect(find.byIcon(Icons.edit), findsNothing);
      });
    });

    // ── Opacity / hover behavior ──────────────────────────────────────────
    group('visibility on hover', () {
      testWidgets('buttons start at opacity 0', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MessageActionBar(
                message: userMessage(),
                onCopy: () {},
                onDelete: () {},
              ),
            ),
          ),
        );
        await tester.pump();

        final opacityWidget = tester.widget<AnimatedOpacity>(
          find.byType(AnimatedOpacity),
        );
        expect(opacityWidget.opacity, 0.0);
      });

      testWidgets('buttons become visible on mouse hover', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MessageActionBar(
                message: userMessage(),
                onCopy: () {},
                onDelete: () {},
              ),
            ),
          ),
        );
        await tester.pump();

        // Simulate mouse enter on the MouseRegion
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);

        // Move into the widget bounds
        final center = tester.getCenter(find.byType(MessageActionBar));
        await gesture.moveTo(center);
        await tester.pump();

        final opacityWidget = tester.widget<AnimatedOpacity>(
          find.byType(AnimatedOpacity),
        );
        expect(opacityWidget.opacity, 1.0);
      });

      testWidgets('buttons become visible on mouse exit (returns to hidden)',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MessageActionBar(
                message: userMessage(),
                onCopy: () {},
                onDelete: () {},
              ),
            ),
          ),
        );
        await tester.pump();

        // Simulate mouse enter then exit
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);

        // Move in
        final center = tester.getCenter(find.byType(MessageActionBar));
        await gesture.moveTo(center);
        await tester.pump();

        var opacity = tester.widget<AnimatedOpacity>(
          find.byType(AnimatedOpacity),
        );
        expect(opacity.opacity, 1.0);

        // Move out
        await gesture.moveTo(const Offset(-100, -100));
        await tester.pump();

        opacity = tester.widget<AnimatedOpacity>(
          find.byType(AnimatedOpacity),
        );
        expect(opacity.opacity, 0.0);
      });
    });

    // ── Callback firing ───────────────────────────────────────────────────
    group('callbacks fire on tap', () {
      testWidgets('onCopy fires when copy icon tapped', (tester) async {
        var called = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MessageActionBar(
                message: userMessage(),
                onCopy: () => called = true,
                onDelete: () {},
              ),
            ),
          ),
        );

        // Make visible first
        await tester.tap(find.byType(MessageActionBar));
        await tester.pump();
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.copy));
        expect(called, isTrue);
      });

      testWidgets('onEdit fires when edit icon tapped', (tester) async {
        var called = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MessageActionBar(
                message: userMessage(),
                onCopy: () {},
                onEdit: () => called = true,
                onDelete: () {},
              ),
            ),
          ),
        );

        await tester.tap(find.byType(MessageActionBar));
        await tester.pump();
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.edit));
        expect(called, isTrue);
      });

      testWidgets('onDelete fires when delete icon tapped', (tester) async {
        var called = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MessageActionBar(
                message: userMessage(),
                onCopy: () {},
                onDelete: () => called = true,
              ),
            ),
          ),
        );

        await tester.tap(find.byType(MessageActionBar));
        await tester.pump();
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.delete_outline));
        expect(called, isTrue);
      });

      testWidgets('onRegenerate fires when regenerate icon tapped',
          (tester) async {
        var called = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MessageActionBar(
                message: assistantMessage(),
                onCopy: () {},
                onRegenerate: () => called = true,
                onDelete: () {},
              ),
            ),
          ),
        );

        await tester.tap(find.byType(MessageActionBar));
        await tester.pump();
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.refresh));
        expect(called, isTrue);
      });

      testWidgets('onBranch fires when branch icon tapped', (tester) async {
        var called = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MessageActionBar(
                message: assistantMessage(),
                onCopy: () {},
                onBranch: () => called = true,
                onDelete: () {},
              ),
            ),
          ),
        );

        await tester.tap(find.byType(MessageActionBar));
        await tester.pump();
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.call_split));
        expect(called, isTrue);
      });
    });

    // ── Null callbacks hide buttons ───────────────────────────────────────
    group('null callbacks hide buttons', () {
      testWidgets('omitting onBranch hides branch button', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MessageActionBar(
                message: userMessage(),
                onCopy: () {},
                onDelete: () {},
                // onBranch is null
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.call_split), findsNothing);
      });

      testWidgets('omitting onCopy hides copy button', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MessageActionBar(
                message: userMessage(),
                onDelete: () {},
                // onCopy is null
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.copy), findsNothing);
      });

      testWidgets('omitting onDelete hides delete button', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MessageActionBar(
                message: userMessage(),
                onCopy: () {},
                // onDelete is null
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.delete_outline), findsNothing);
      });
    });
  });
}
