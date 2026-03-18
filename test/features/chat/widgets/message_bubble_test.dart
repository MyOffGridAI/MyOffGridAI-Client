import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/core/models/message_model.dart';
import 'package:myoffgridai_client/core/services/chat_service.dart';
import 'package:myoffgridai_client/features/chat/widgets/message_bubble.dart';
import 'package:myoffgridai_client/features/chat/widgets/thinking_block.dart';
import 'package:myoffgridai_client/features/chat/widgets/inference_metadata_row.dart';
import 'package:myoffgridai_client/features/chat/widgets/message_action_bar.dart';

void main() {
  const testConversationId = 'test-conv-1';

  Widget buildBubble({
    required MessageModel message,
    bool isStreaming = false,
    bool isThinking = false,
    String conversationId = testConversationId,
    ValueChanged<MessageModel>? onEdit,
    ValueChanged<MessageModel>? onDelete,
    ValueChanged<MessageModel>? onRegenerate,
    ValueChanged<MessageModel>? onBranch,
  }) {
    return ProviderScope(
      overrides: [
        aiThinkingProvider(conversationId).overrideWith(
          (ref) => isThinking,
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MessageBubble(
              message: message,
              conversationId: conversationId,
              isStreaming: isStreaming,
              onEdit: onEdit,
              onDelete: onDelete,
              onRegenerate: onRegenerate,
              onBranch: onBranch,
            ),
          ),
        ),
      ),
    );
  }

  group('MessageBubble', () {
    testWidgets('renders user message content', (tester) async {
      const msg = MessageModel(
        id: 'm1',
        role: 'USER',
        content: 'Hello AI',
        hasRagContext: false,
      );

      await tester.pumpWidget(buildBubble(message: msg));
      await tester.pump();

      expect(find.text('Hello AI'), findsOneWidget);
    });

    testWidgets('renders assistant message content', (tester) async {
      const msg = MessageModel(
        id: 'm2',
        role: 'ASSISTANT',
        content: 'Hello human',
        hasRagContext: false,
      );

      await tester.pumpWidget(buildBubble(message: msg));
      await tester.pump();

      expect(find.text('Hello human'), findsOneWidget);
    });

    testWidgets('shows RAG context indicator when hasRagContext is true',
        (tester) async {
      const msg = MessageModel(
        id: 'm3',
        role: 'ASSISTANT',
        content: 'Based on docs',
        hasRagContext: true,
      );

      await tester.pumpWidget(buildBubble(message: msg));
      await tester.pump();

      expect(find.byIcon(Icons.auto_stories), findsOneWidget);
      expect(find.text('Knowledge-enhanced'), findsOneWidget);
    });

    testWidgets('hides RAG context indicator when hasRagContext is false',
        (tester) async {
      const msg = MessageModel(
        id: 'm4',
        role: 'ASSISTANT',
        content: 'Normal response',
        hasRagContext: false,
      );

      await tester.pumpWidget(buildBubble(message: msg));
      await tester.pump();

      expect(find.byIcon(Icons.auto_stories), findsNothing);
    });

    testWidgets('shows ThinkingBlock for assistant with thinking content',
        (tester) async {
      const msg = MessageModel(
        id: 'm5',
        role: 'ASSISTANT',
        content: 'Answer',
        hasRagContext: false,
        thinkingContent: 'Let me think...',
      );

      await tester.pumpWidget(buildBubble(message: msg));
      await tester.pump();

      expect(find.byType(ThinkingBlock), findsOneWidget);
    });

    testWidgets('hides ThinkingBlock when thinkingContent is null',
        (tester) async {
      const msg = MessageModel(
        id: 'm6',
        role: 'ASSISTANT',
        content: 'Answer',
        hasRagContext: false,
      );

      await tester.pumpWidget(buildBubble(message: msg));
      await tester.pump();

      expect(find.byType(ThinkingBlock), findsNothing);
    });

    testWidgets(
        'hides ThinkingBlock for user messages even with thinking content',
        (tester) async {
      const msg = MessageModel(
        id: 'm7',
        role: 'USER',
        content: 'Question',
        hasRagContext: false,
        thinkingContent: 'Should not show',
      );

      await tester.pumpWidget(buildBubble(message: msg));
      await tester.pump();

      expect(find.byType(ThinkingBlock), findsNothing);
    });

    testWidgets('shows InferenceMetadataRow for assistant with metadata',
        (tester) async {
      const msg = MessageModel(
        id: 'm8',
        role: 'ASSISTANT',
        content: 'Response',
        hasRagContext: false,
        inferenceTimeSeconds: 2.5,
        tokensPerSecond: 14.3,
      );

      await tester.pumpWidget(buildBubble(message: msg));
      await tester.pump();

      expect(find.byType(InferenceMetadataRow), findsOneWidget);
    });

    testWidgets('hides InferenceMetadataRow during streaming',
        (tester) async {
      const msg = MessageModel(
        id: 'm9',
        role: 'ASSISTANT',
        content: 'Streaming...',
        hasRagContext: false,
        inferenceTimeSeconds: 1.0,
      );

      await tester.pumpWidget(
          buildBubble(message: msg, isStreaming: true));
      await tester.pump();

      expect(find.byType(InferenceMetadataRow), findsNothing);
    });

    testWidgets('shows MessageActionBar when not streaming', (tester) async {
      const msg = MessageModel(
        id: 'm10',
        role: 'ASSISTANT',
        content: 'Done',
        hasRagContext: false,
      );

      await tester.pumpWidget(buildBubble(
        message: msg,
        onDelete: (_) {},
      ));
      await tester.pump();

      expect(find.byType(MessageActionBar), findsOneWidget);
    });

    testWidgets('hides MessageActionBar during streaming', (tester) async {
      const msg = MessageModel(
        id: 'm11',
        role: 'ASSISTANT',
        content: 'Still going...',
        hasRagContext: false,
      );

      await tester.pumpWidget(
          buildBubble(message: msg, isStreaming: true));
      await tester.pump();

      expect(find.byType(MessageActionBar), findsNothing);
    });

    testWidgets('user message is right-aligned', (tester) async {
      const msg = MessageModel(
        id: 'm12',
        role: 'USER',
        content: 'Right side',
        hasRagContext: false,
      );

      await tester.pumpWidget(buildBubble(message: msg));
      await tester.pump();

      final align = tester.widget<Align>(find.byType(Align).first);
      expect(align.alignment, Alignment.centerRight);
    });

    testWidgets('assistant message is left-aligned', (tester) async {
      const msg = MessageModel(
        id: 'm13',
        role: 'ASSISTANT',
        content: 'Left side',
        hasRagContext: false,
      );

      await tester.pumpWidget(buildBubble(message: msg));
      await tester.pump();

      final align = tester.widget<Align>(find.byType(Align).first);
      expect(align.alignment, Alignment.centerLeft);
    });

    testWidgets('renders empty content without error', (tester) async {
      const msg = MessageModel(
        id: 'm14',
        role: 'ASSISTANT',
        content: '',
        hasRagContext: false,
      );

      await tester.pumpWidget(buildBubble(message: msg));
      await tester.pump();

      expect(find.byType(MessageBubble), findsOneWidget);
    });

    // ── aiThinkingProvider integration tests ────────────────────────────
    group('aiThinkingProvider integration', () {
      testWidgets(
          'passes isStreaming=true to ThinkingBlock when aiThinkingProvider=true and isStreaming=true',
          (tester) async {
        const msg = MessageModel(
          id: 'm20',
          role: 'ASSISTANT',
          content: '',
          hasRagContext: false,
          thinkingContent: 'Reasoning live...',
        );

        await tester.pumpWidget(buildBubble(
          message: msg,
          isStreaming: true,
          isThinking: true,
        ));
        await tester.pump();

        final thinkingBlock = tester.widget<ThinkingBlock>(
          find.byType(ThinkingBlock),
        );
        expect(thinkingBlock.isStreaming, isTrue);
      });

      testWidgets(
          'passes isStreaming=false to ThinkingBlock when aiThinkingProvider=false',
          (tester) async {
        const msg = MessageModel(
          id: 'm21',
          role: 'ASSISTANT',
          content: 'Done thinking',
          hasRagContext: false,
          thinkingContent: 'Reasoning complete',
        );

        await tester.pumpWidget(buildBubble(
          message: msg,
          isStreaming: true,
          isThinking: false,
        ));
        await tester.pump();

        final thinkingBlock = tester.widget<ThinkingBlock>(
          find.byType(ThinkingBlock),
        );
        expect(thinkingBlock.isStreaming, isFalse);
      });

      testWidgets(
          'passes isStreaming=false to ThinkingBlock when isStreaming=false even if aiThinkingProvider=true',
          (tester) async {
        const msg = MessageModel(
          id: 'm22',
          role: 'ASSISTANT',
          content: 'Response',
          hasRagContext: false,
          thinkingContent: 'Past thoughts',
        );

        await tester.pumpWidget(buildBubble(
          message: msg,
          isStreaming: false,
          isThinking: true,
        ));
        await tester.pump();

        final thinkingBlock = tester.widget<ThinkingBlock>(
          find.byType(ThinkingBlock),
        );
        expect(thinkingBlock.isStreaming, isFalse);
      });

      testWidgets('does not show ThinkingBlock when thinkingContent is null',
          (tester) async {
        const msg = MessageModel(
          id: 'm23',
          role: 'ASSISTANT',
          content: 'No thinking',
          hasRagContext: false,
        );

        await tester.pumpWidget(buildBubble(
          message: msg,
          isStreaming: true,
          isThinking: true,
        ));
        await tester.pump();

        expect(find.byType(ThinkingBlock), findsNothing);
      });

      testWidgets(
          'does not show ThinkingBlock when thinkingContent is empty string',
          (tester) async {
        const msg = MessageModel(
          id: 'm24',
          role: 'ASSISTANT',
          content: 'No thinking',
          hasRagContext: false,
          thinkingContent: '',
        );

        await tester.pumpWidget(buildBubble(
          message: msg,
          isStreaming: true,
          isThinking: true,
        ));
        await tester.pump();

        expect(find.byType(ThinkingBlock), findsNothing);
      });
    });
  });
}
