import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/core/models/event_model.dart';
import 'package:myoffgridai_client/core/services/event_service.dart';
import 'package:myoffgridai_client/features/events/events_screen.dart';

void main() {
  group('EventsScreen', () {
    Widget buildScreen({List<ScheduledEventModel> events = const []}) {
      return ProviderScope(
        overrides: [
          eventsListProvider.overrideWith((ref) => events),
        ],
        child: const MaterialApp(home: EventsScreen()),
      );
    }

    testWidgets('shows empty state when no events', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('No events configured'), findsOneWidget);
    });

    testWidgets('displays event cards', (tester) async {
      final events = [
        ScheduledEventModel.fromJson({
          'id': '1',
          'name': 'Morning Report',
          'eventType': 'SCHEDULED',
          'isEnabled': true,
          'actionType': 'AI_PROMPT',
          'actionPayload': 'Summarize',
        }),
        ScheduledEventModel.fromJson({
          'id': '2',
          'name': 'Temp Alert',
          'eventType': 'SENSOR_THRESHOLD',
          'isEnabled': false,
          'actionType': 'PUSH_NOTIFICATION',
          'actionPayload': 'Temperature too high',
        }),
      ];

      await tester.pumpWidget(buildScreen(events: events));
      await tester.pumpAndSettle();

      expect(find.text('Morning Report'), findsOneWidget);
      expect(find.text('Temp Alert'), findsOneWidget);
    });

    testWidgets('shows add FAB', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('shows app bar title', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Events'), findsOneWidget);
    });

    testWidgets('shows toggle switch on event cards', (tester) async {
      final events = [
        ScheduledEventModel.fromJson({
          'id': '1',
          'name': 'Test',
          'eventType': 'SCHEDULED',
          'isEnabled': true,
          'actionType': 'AI_PROMPT',
          'actionPayload': 'Test',
        }),
      ];

      await tester.pumpWidget(buildScreen(events: events));
      await tester.pumpAndSettle();

      expect(find.byType(Switch), findsOneWidget);
    });
  });
}
