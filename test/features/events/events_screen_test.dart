import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/models/event_model.dart';
import 'package:myoffgridai_client/core/services/event_service.dart';
import 'package:myoffgridai_client/core/services/sensor_service.dart';
import 'package:myoffgridai_client/features/events/events_screen.dart';

class MockEventService extends Mock implements EventService {}

class MockSensorService extends Mock implements SensorService {}

void main() {
  late MockEventService mockService;

  final enabledEvent = ScheduledEventModel.fromJson({
    'id': '1',
    'name': 'Morning Report',
    'eventType': 'SCHEDULED',
    'isEnabled': true,
    'actionType': 'AI_PROMPT',
    'actionPayload': 'Summarize',
    'nextFireAt': '2026-03-17T08:00:00Z',
  });

  final disabledEvent = ScheduledEventModel.fromJson({
    'id': '2',
    'name': 'Temp Alert',
    'eventType': 'SENSOR_THRESHOLD',
    'isEnabled': false,
    'actionType': 'PUSH_NOTIFICATION',
    'actionPayload': 'Temperature too high',
  });

  final recurringEvent = ScheduledEventModel.fromJson({
    'id': '3',
    'name': 'Hourly Check',
    'eventType': 'RECURRING',
    'isEnabled': true,
    'actionType': 'AI_SUMMARY',
    'actionPayload': 'Status check',
  });

  late MockSensorService mockSensorService;

  setUp(() {
    mockService = MockEventService();
    mockSensorService = MockSensorService();
    registerFallbackValue('');
  });

  Widget buildScreen({List<ScheduledEventModel> events = const []}) {
    return ProviderScope(
      overrides: [
        eventsListProvider.overrideWith((ref) => events),
        eventServiceProvider.overrideWithValue(mockService),
      ],
      child: const MaterialApp(home: EventsScreen()),
    );
  }

  group('EventsScreen', () {
    testWidgets('shows empty state when no events', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('No events configured'), findsOneWidget);
    });

    testWidgets('displays event cards', (tester) async {
      await tester
          .pumpWidget(buildScreen(events: [enabledEvent, disabledEvent]));
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
      await tester.pumpWidget(buildScreen(events: [enabledEvent]));
      await tester.pumpAndSettle();

      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('switch is on for enabled event', (tester) async {
      await tester.pumpWidget(buildScreen(events: [enabledEvent]));
      await tester.pumpAndSettle();

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isTrue);
    });

    testWidgets('switch is off for disabled event', (tester) async {
      await tester.pumpWidget(buildScreen(events: [disabledEvent]));
      await tester.pumpAndSettle();

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isFalse);
    });

    testWidgets('shows event type badge', (tester) async {
      await tester.pumpWidget(buildScreen(events: [enabledEvent]));
      await tester.pumpAndSettle();

      expect(find.text('Scheduled'), findsOneWidget);
    });

    testWidgets('shows sensor threshold type', (tester) async {
      await tester.pumpWidget(buildScreen(events: [disabledEvent]));
      await tester.pumpAndSettle();

      expect(find.text('Sensor Threshold'), findsOneWidget);
    });

    testWidgets('shows recurring type', (tester) async {
      await tester.pumpWidget(buildScreen(events: [recurringEvent]));
      await tester.pumpAndSettle();

      expect(find.text('Recurring'), findsOneWidget);
    });

    testWidgets('shows action type label', (tester) async {
      await tester.pumpWidget(buildScreen(events: [enabledEvent]));
      await tester.pumpAndSettle();

      expect(find.text('AI Prompt'), findsOneWidget);
    });

    testWidgets('shows next fire time', (tester) async {
      await tester.pumpWidget(buildScreen(events: [enabledEvent]));
      await tester.pumpAndSettle();

      expect(find.textContaining('Next:'), findsOneWidget);
    });

    testWidgets('hides next fire time when null', (tester) async {
      await tester.pumpWidget(buildScreen(events: [disabledEvent]));
      await tester.pumpAndSettle();

      expect(find.textContaining('Next:'), findsNothing);
    });
  });

  group('EventsScreen error state', () {
    testWidgets('shows API error message', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          eventsListProvider.overrideWith((ref) =>
              throw const ApiException(statusCode: 500, message: 'Server down')),
          eventServiceProvider.overrideWithValue(mockService),
        ],
        child: const MaterialApp(home: EventsScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load events'), findsOneWidget);
      expect(find.text('Server down'), findsOneWidget);
    });

    testWidgets('shows generic error for non-API exception', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          eventsListProvider.overrideWith((ref) => throw Exception('unknown')),
          eventServiceProvider.overrideWithValue(mockService),
        ],
        child: const MaterialApp(home: EventsScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('An unexpected error occurred.'), findsOneWidget);
    });

    testWidgets('shows retry button on error', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          eventsListProvider.overrideWith((ref) =>
              throw const ApiException(statusCode: 500, message: 'Error')),
          eventServiceProvider.overrideWithValue(mockService),
        ],
        child: const MaterialApp(home: EventsScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('Create event dialog', () {
    testWidgets('FAB opens event dialog', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          eventsListProvider.overrideWith((ref) => <ScheduledEventModel>[]),
          eventServiceProvider.overrideWithValue(mockService),
          sensorsProvider.overrideWith((ref) => []),
          sensorServiceProvider.overrideWithValue(mockSensorService),
        ],
        child: const MaterialApp(home: EventsScreen()),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // The event dialog should be visible with form fields
      expect(find.text('Name'), findsOneWidget);
    });
  });

  group('Edit event dialog', () {
    testWidgets('edit option opens event dialog with existing data',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          eventsListProvider.overrideWith((ref) => [enabledEvent]),
          eventServiceProvider.overrideWithValue(mockService),
          sensorsProvider.overrideWith((ref) => []),
          sensorServiceProvider.overrideWithValue(mockSensorService),
        ],
        child: const MaterialApp(home: EventsScreen()),
      ));
      await tester.pumpAndSettle();

      // Open popup menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Tap Edit
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // The event dialog should be visible with existing event name
      expect(find.text('Morning Report'), findsWidgets);
    });
  });

  group('Toggle event', () {
    testWidgets('calls toggleEvent on switch tap', (tester) async {
      when(() => mockService.toggleEvent('1')).thenAnswer(
        (_) async => ScheduledEventModel.fromJson({
          'id': '1',
          'name': 'Morning Report',
          'eventType': 'SCHEDULED',
          'isEnabled': false,
          'actionType': 'AI_PROMPT',
          'actionPayload': 'Summarize',
        }),
      );

      await tester.pumpWidget(buildScreen(events: [enabledEvent]));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      verify(() => mockService.toggleEvent('1')).called(1);
    });

    testWidgets('shows error on toggle failure', (tester) async {
      when(() => mockService.toggleEvent('1')).thenThrow(
        const ApiException(statusCode: 500, message: 'Toggle failed'),
      );

      await tester.pumpWidget(buildScreen(events: [enabledEvent]));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.text('Toggle failed'), findsOneWidget);
    });
  });

  group('PopupMenu', () {
    testWidgets('shows Edit and Delete options', (tester) async {
      await tester.pumpWidget(buildScreen(events: [enabledEvent]));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });
  });

  group('Delete event', () {
    testWidgets('shows confirmation dialog', (tester) async {
      await tester.pumpWidget(buildScreen(events: [enabledEvent]));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Event'), findsOneWidget);
      expect(find.textContaining('"Morning Report"'), findsOneWidget);
    });

    testWidgets('calls deleteEvent on confirm', (tester) async {
      when(() => mockService.deleteEvent('1')).thenAnswer((_) async {});

      await tester.pumpWidget(buildScreen(events: [enabledEvent]));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      verify(() => mockService.deleteEvent('1')).called(1);
    });

    testWidgets('does not delete on cancel', (tester) async {
      await tester.pumpWidget(buildScreen(events: [enabledEvent]));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      verifyNever(() => mockService.deleteEvent(any()));
    });

    testWidgets('shows error on delete failure', (tester) async {
      when(() => mockService.deleteEvent('1')).thenThrow(
        const ApiException(statusCode: 500, message: 'Delete failed'),
      );

      await tester.pumpWidget(buildScreen(events: [enabledEvent]));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(find.text('Delete failed'), findsOneWidget);
    });
  });
}
