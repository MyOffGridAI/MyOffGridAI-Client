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

    // ── Always visible ────────────────────────────────────────────────────
    group('always visible', () {
      testWidgets('buttons are visible immediately without hover',
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

        // No AnimatedOpacity wrapper — buttons are rendered directly
        expect(find.byType(AnimatedOpacity), findsNothing);
        // Buttons are findable and tappable
        expect(find.byIcon(Icons.copy), findsOneWidget);
        expect(find.byIcon(Icons.delete_outline), findsOneWidget);
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
