import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/models/sensor_model.dart';
import 'package:myoffgridai_client/core/services/sensor_service.dart';
import 'package:myoffgridai_client/features/sensors/add_sensor_screen.dart';

class MockSensorService extends Mock implements SensorService {}

void main() {
  late MockSensorService mockService;

  setUp(() {
    mockService = MockSensorService();
    registerFallbackValue('');
    registerFallbackValue(0);
  });

  Widget buildScreen() {
    return ProviderScope(
      overrides: [
        sensorServiceProvider.overrideWithValue(mockService),
      ],
      child: const MaterialApp(home: AddSensorScreen()),
    );
  }

  group('AddSensorScreen', () {
    testWidgets('shows app bar title', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Add Sensor'), findsOneWidget);
    });

    testWidgets('shows sensor name field', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Sensor Name'), findsOneWidget);
    });

    testWidgets('shows sensor type dropdown', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Sensor Type'), findsOneWidget);
    });

    testWidgets('shows port path field', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Port Path'), findsOneWidget);
    });

    testWidgets('shows baud rate dropdown', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Baud Rate'), findsOneWidget);
    });

    testWidgets('shows unit field', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Unit (optional)'), findsOneWidget);
    });

    testWidgets('shows poll interval dropdown', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Poll Interval'), findsOneWidget);
    });

    testWidgets('shows test connection button', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Test Connection'), findsOneWidget);
      expect(find.byIcon(Icons.cable), findsOneWidget);
    });

    testWidgets('shows register button', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Register Sensor'), findsOneWidget);
    });
  });

  group('Form validation', () {
    testWidgets('validates empty name', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Register Sensor'));
      await tester.pumpAndSettle();

      expect(find.text('Name is required'), findsOneWidget);
    });

    testWidgets('validates empty port', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Fill in name to pass name validation
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Sensor Name'),
        'Test Sensor',
      );

      await tester.tap(find.text('Register Sensor'));
      await tester.pumpAndSettle();

      expect(find.text('Port is required'), findsOneWidget);
    });

    testWidgets('shows both errors when all empty', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Register Sensor'));
      await tester.pumpAndSettle();

      expect(find.text('Name is required'), findsOneWidget);
      expect(find.text('Port is required'), findsOneWidget);
    });
  });

  group('Test connection', () {
    testWidgets('calls testConnection on tap', (tester) async {
      when(() => mockService.testConnection(any(), any())).thenAnswer(
        (_) async => const SensorTestResultModel(
          success: true,
          portPath: '/dev/ttyUSB0',
          baudRate: 9600,
          message: 'Connection successful',
        ),
      );

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Port Path'),
        '/dev/ttyUSB0',
      );

      await tester.tap(find.text('Test Connection'));
      await tester.pumpAndSettle();

      verify(() => mockService.testConnection('/dev/ttyUSB0', 9600)).called(1);
    });

    testWidgets('shows success result', (tester) async {
      when(() => mockService.testConnection(any(), any())).thenAnswer(
        (_) async => const SensorTestResultModel(
          success: true,
          portPath: '/dev/ttyUSB0',
          baudRate: 9600,
          message: 'Connection successful',
        ),
      );

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Port Path'),
        '/dev/ttyUSB0',
      );

      await tester.tap(find.text('Test Connection'));
      await tester.pumpAndSettle();

      expect(find.text('Connection successful'), findsOneWidget);
    });

    testWidgets('shows failure result', (tester) async {
      when(() => mockService.testConnection(any(), any())).thenAnswer(
        (_) async => const SensorTestResultModel(
          success: false,
          portPath: '/dev/ttyUSB0',
          baudRate: 9600,
          message: 'Connection refused',
        ),
      );

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Port Path'),
        '/dev/ttyUSB0',
      );

      await tester.tap(find.text('Test Connection'));
      await tester.pumpAndSettle();

      expect(find.text('Connection refused'), findsOneWidget);
    });

    testWidgets('shows error on API exception', (tester) async {
      when(() => mockService.testConnection(any(), any())).thenThrow(
        const ApiException(statusCode: 500, message: 'Test failed'),
      );

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Port Path'),
        '/dev/ttyUSB0',
      );

      await tester.tap(find.text('Test Connection'));
      await tester.pumpAndSettle();

      expect(find.text('Test failed'), findsOneWidget);
    });

    testWidgets('does not test when port is empty', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Test Connection'));
      await tester.pumpAndSettle();

      verifyNever(() => mockService.testConnection(any(), any()));
    });
  });

  group('Dropdown changes', () {
    testWidgets('changing sensor type updates selection', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Open the sensor type dropdown
      await tester.tap(find.text('Sensor Type').last);
      await tester.pumpAndSettle();

      // Select HUMIDITY
      await tester.tap(find.text('HUMIDITY').last);
      await tester.pumpAndSettle();

      expect(find.text('HUMIDITY'), findsOneWidget);
    });

    testWidgets('changing baud rate updates selection', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Open the baud rate dropdown
      await tester.tap(find.text('Baud Rate').last);
      await tester.pumpAndSettle();

      // Select 19200
      await tester.tap(find.text('19200').last);
      await tester.pumpAndSettle();

      expect(find.text('19200'), findsOneWidget);
    });

    testWidgets('changing poll interval updates selection', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Open the poll interval dropdown
      await tester.tap(find.text('Poll Interval').last);
      await tester.pumpAndSettle();

      // Select 300s
      await tester.tap(find.text('300s').last);
      await tester.pumpAndSettle();

      expect(find.text('300s'), findsOneWidget);
    });
  });

  group('Save sensor', () {
    testWidgets('navigates to sensors on save success', (tester) async {
      when(() => mockService.createSensor(
            name: any(named: 'name'),
            type: any(named: 'type'),
            portPath: any(named: 'portPath'),
            baudRate: any(named: 'baudRate'),
            unit: any(named: 'unit'),
            pollIntervalSeconds: any(named: 'pollIntervalSeconds'),
          )).thenAnswer((_) async => SensorModel.fromJson({
            'id': 'new-1',
            'name': 'Test Sensor',
            'type': 'TEMPERATURE',
            'baudRate': 9600,
            'isActive': false,
            'pollIntervalSeconds': 60,
          }));

      final router = GoRouter(
        initialLocation: '/sensors/add',
        routes: [
          GoRoute(
            path: '/sensors/add',
            builder: (_, __) => const AddSensorScreen(),
          ),
          GoRoute(
            path: '/sensors',
            builder: (_, __) =>
                const Scaffold(body: Text('Sensors List')),
          ),
        ],
      );

      await tester.pumpWidget(ProviderScope(
        overrides: [
          sensorServiceProvider.overrideWithValue(mockService),
        ],
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Sensor Name'),
        'Test Sensor',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Port Path'),
        '/dev/ttyUSB0',
      );

      await tester.tap(find.text('Register Sensor'));
      await tester.pumpAndSettle();

      expect(find.text('Sensors List'), findsOneWidget);
    });

    testWidgets('shows error SnackBar on save failure', (tester) async {
      when(() => mockService.createSensor(
            name: any(named: 'name'),
            type: any(named: 'type'),
            portPath: any(named: 'portPath'),
            baudRate: any(named: 'baudRate'),
            unit: any(named: 'unit'),
            pollIntervalSeconds: any(named: 'pollIntervalSeconds'),
          )).thenThrow(
        const ApiException(statusCode: 400, message: 'Invalid sensor config'),
      );

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Sensor Name'),
        'Test Sensor',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Port Path'),
        '/dev/ttyUSB0',
      );

      await tester.tap(find.text('Register Sensor'));
      await tester.pumpAndSettle();

      expect(find.text('Invalid sensor config'), findsOneWidget);
    });
  });
}
