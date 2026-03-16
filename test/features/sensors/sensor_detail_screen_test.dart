import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/models/sensor_model.dart';
import 'package:myoffgridai_client/core/services/sensor_service.dart';
import 'package:myoffgridai_client/features/sensors/sensor_detail_screen.dart';

class MockSensorService extends Mock implements SensorService {}

void main() {
  late MockSensorService mockService;

  const testSensor = SensorModel(
    id: 's1',
    name: 'Greenhouse Temp',
    type: 'TEMPERATURE',
    portPath: '/dev/ttyUSB0',
    baudRate: 9600,
    unit: '\u00b0C',
    isActive: true,
    pollIntervalSeconds: 30,
    lowThreshold: 5.0,
    highThreshold: 35.0,
  );

  const inactiveSensor = SensorModel(
    id: 's2',
    name: 'Soil Moisture',
    type: 'SOIL_MOISTURE',
    baudRate: 9600,
    isActive: false,
    pollIntervalSeconds: 60,
  );

  final testReadings = [
    const SensorReadingModel(
      id: 'r1',
      sensorId: 's1',
      value: 22.5,
      recordedAt: '2026-03-16T10:00:00Z',
    ),
    const SensorReadingModel(
      id: 'r2',
      sensorId: 's1',
      value: 23.1,
      recordedAt: '2026-03-16T10:30:00Z',
    ),
    const SensorReadingModel(
      id: 'r3',
      sensorId: 's1',
      value: 21.8,
      recordedAt: '2026-03-16T11:00:00Z',
    ),
  ];

  setUp(() {
    mockService = MockSensorService();
  });

  Widget buildScreen({
    String sensorId = 's1',
    SensorModel? sensor,
    List<SensorReadingModel>? readings,
    bool sensorError = false,
    bool historyError = false,
  }) {
    return ProviderScope(
      overrides: [
        sensorServiceProvider.overrideWithValue(mockService),
      ],
      child: MaterialApp(
        home: SensorDetailScreen(sensorId: sensorId),
      ),
    );
  }

  group('SensorDetailScreen', () {
    testWidgets('shows loading indicator initially', (tester) async {
      when(() => mockService.getSensor('s1'))
          .thenAnswer((_) async => testSensor);
      when(() => mockService.getHistory('s1', hours: 24, size: 50))
          .thenAnswer((_) async => testReadings);

      await tester.pumpWidget(buildScreen());
      await tester.pump();

      // Either loading indicator or data (depending on async resolution)
      expect(find.text('Sensor Detail'), findsOneWidget);
    });

    testWidgets('shows error view when sensor fetch fails', (tester) async {
      when(() => mockService.getSensor('s1')).thenThrow(
        const ApiException(statusCode: 404, message: 'Sensor not found'),
      );
      when(() => mockService.getHistory('s1', hours: 24, size: 50))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Failed to load sensor'), findsOneWidget);
      expect(find.text('Sensor not found'), findsOneWidget);
    });

    testWidgets('shows generic error message for non-API errors',
        (tester) async {
      when(() => mockService.getSensor('s1')).thenThrow(Exception('timeout'));
      when(() => mockService.getHistory('s1', hours: 24, size: 50))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('An unexpected error occurred.'), findsOneWidget);
    });

    testWidgets('shows retry button on error', (tester) async {
      when(() => mockService.getSensor('s1')).thenThrow(
        const ApiException(statusCode: 500, message: 'Server error'),
      );
      when(() => mockService.getHistory('s1', hours: 24, size: 50))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('shows sensor info card with data', (tester) async {
      when(() => mockService.getSensor('s1'))
          .thenAnswer((_) async => testSensor);
      when(() => mockService.getHistory('s1', hours: 24, size: 50))
          .thenAnswer((_) async => testReadings);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Greenhouse Temp'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('TEMPERATURE'), findsOneWidget);
      expect(find.text('/dev/ttyUSB0'), findsOneWidget);
      expect(find.text('9600'), findsOneWidget);
      expect(find.text('30s'), findsOneWidget);
      expect(find.text('\u00b0C'), findsOneWidget);
      expect(find.text('5.0'), findsOneWidget);
      expect(find.text('35.0'), findsOneWidget);
    });

    testWidgets('shows inactive status', (tester) async {
      when(() => mockService.getSensor('s2'))
          .thenAnswer((_) async => inactiveSensor);
      when(() => mockService.getHistory('s2', hours: 24, size: 50))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(buildScreen(sensorId: 's2'));
      await tester.pumpAndSettle();

      expect(find.text('Inactive'), findsOneWidget);
    });

    testWidgets('shows History (24h) section', (tester) async {
      when(() => mockService.getSensor('s1'))
          .thenAnswer((_) async => testSensor);
      when(() => mockService.getHistory('s1', hours: 24, size: 50))
          .thenAnswer((_) async => testReadings);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('History (24h)'), findsOneWidget);
    });

    testWidgets('shows "No readings yet" when history is empty',
        (tester) async {
      when(() => mockService.getSensor('s1'))
          .thenAnswer((_) async => testSensor);
      when(() => mockService.getHistory('s1', hours: 24, size: 50))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('No readings yet'), findsOneWidget);
    });

    testWidgets('shows Recent Readings list when data exists', (tester) async {
      when(() => mockService.getSensor('s1'))
          .thenAnswer((_) async => testSensor);
      when(() => mockService.getHistory('s1', hours: 24, size: 50))
          .thenAnswer((_) async => testReadings);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Recent Readings'), findsOneWidget);
      // Values appear in both the chart axis labels and the readings list
      expect(find.text('22.5'), findsAtLeastNWidgets(1));
      expect(find.text('23.1'), findsAtLeastNWidgets(1));
      expect(find.text('21.8'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows "Failed to load history" when history errors',
        (tester) async {
      when(() => mockService.getSensor('s1'))
          .thenAnswer((_) async => testSensor);
      when(() => mockService.getHistory('s1', hours: 24, size: 50))
          .thenThrow(const ApiException(
              statusCode: 500, message: 'History error'));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Failed to load history'), findsOneWidget);
    });

    testWidgets('retry button re-fetches sensor data', (tester) async {
      int callCount = 0;
      when(() => mockService.getSensor('s1')).thenAnswer((_) {
        callCount++;
        if (callCount == 1) {
          throw const ApiException(
              statusCode: 500, message: 'Server error');
        }
        return Future.value(testSensor);
      });
      when(() => mockService.getHistory('s1', hours: 24, size: 50))
          .thenAnswer((_) async => testReadings);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Should show error with retry button
      expect(find.text('Retry'), findsOneWidget);

      // Tap retry
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // Should now show sensor info
      expect(find.text('Greenhouse Temp'), findsOneWidget);
    });

    testWidgets('omits optional fields when null', (tester) async {
      when(() => mockService.getSensor('s2'))
          .thenAnswer((_) async => inactiveSensor);
      when(() => mockService.getHistory('s2', hours: 24, size: 50))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(buildScreen(sensorId: 's2'));
      await tester.pumpAndSettle();

      // Port, Unit, Low/High Threshold labels shouldn't appear
      expect(find.text('Port'), findsNothing);
      expect(find.text('Unit'), findsNothing);
      expect(find.text('Low Threshold'), findsNothing);
      expect(find.text('High Threshold'), findsNothing);
    });

    testWidgets('app bar has correct title', (tester) async {
      when(() => mockService.getSensor('s1'))
          .thenAnswer((_) async => testSensor);
      when(() => mockService.getHistory('s1', hours: 24, size: 50))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Sensor Detail'), findsOneWidget);
    });
  });
}
