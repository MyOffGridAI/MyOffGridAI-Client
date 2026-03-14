import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/shared/widgets/empty_state_view.dart';

void main() {
  group('EmptyStateView', () {
    testWidgets('renders icon and title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateView(
              icon: Icons.inbox,
              title: 'No items',
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.inbox), findsOneWidget);
      expect(find.text('No items'), findsOneWidget);
    });

    testWidgets('renders optional subtitle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateView(
              icon: Icons.inbox,
              title: 'No items',
              subtitle: 'Add some items to get started',
            ),
          ),
        ),
      );
      expect(find.text('Add some items to get started'), findsOneWidget);
    });

    testWidgets('hides subtitle when not provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateView(
              icon: Icons.inbox,
              title: 'No items',
            ),
          ),
        ),
      );
      // Only icon and title text widgets
      expect(find.byType(Text), findsOneWidget);
    });
  });
}
