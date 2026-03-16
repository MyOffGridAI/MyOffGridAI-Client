import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/models/sensor_model.dart';
import 'package:myoffgridai_client/core/services/sensor_service.dart';
import 'package:myoffgridai_client/features/sensors/sensors_screen.dart';

class MockSensorService extends Mock implements SensorService {}

void main() {
  late MockSensorService mockService;

  final activeTempSensor = SensorModel.fromJson({
    'id': '1',
    'name': 'Greenhouse Temp',
    'type': 'TEMPERATURE',
    'baudRate': 9600,
    'isActive': true,
    'pollIntervalSeconds': 30,
    'unit': '°C',
  });

  final inactiveSoilSensor = SensorModel.fromJson({
    'id': '2',
    'name': 'Soil Moisture',
    'type': 'SOIL_MOISTURE',
    'baudRate': 9600,
    'isActive': false,
    'pollIntervalSeconds': 60,
  });

  final humiditySensor = SensorModel.fromJson({
    'id': '3',
    'name': 'Humidity Monitor',
    'type': 'HUMIDITY',
    'baudRate': 9600,
    'isActive': true,
    'pollIntervalSeconds': 120,
    'unit': '%',
  });

  final pressureSensor = SensorModel.fromJson({
    'id': '4',
    'name': 'Barometer',
    'type': 'PRESSURE',
    'baudRate': 9600,
    'isActive': true,
    'pollIntervalSeconds': 300,
    'unit': 'hPa',
  });

  final windSensor = SensorModel.fromJson({
    'id': '5',
    'name': 'Wind Gauge',
    'type': 'WIND_SPEED',
    'baudRate': 9600,
    'isActive': false,
    'pollIntervalSeconds': 60,
  });

  final solarSensor = SensorModel.fromJson({
    'id': '6',
    'name': 'Solar Panel',
    'type': 'SOLAR_RADIATION',
    'baudRate': 9600,
    'isActive': true,
    'pollIntervalSeconds': 60,
  });

  setUp(() {
    mockService = MockSensorService();
    registerFallbackValue('');
  });

  Widget buildScreen({List<SensorModel> sensors = const []}) {
    return ProviderScope(
      overrides: [
        sensorsProvider.overrideWith((ref) => sensors),
        sensorServiceProvider.overrideWithValue(mockService),
      ],
      child: const MaterialApp(home: SensorsScreen()),
    );
  }

  group('SensorsScreen', () {
    testWidgets('shows empty state when no sensors', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('No sensors registered'), findsOneWidget);
    });

    testWidgets('displays sensor cards', (tester) async {
      await tester.pumpWidget(
          buildScreen(sensors: [activeTempSensor, inactiveSoilSensor]));
      await tester.pumpAndSettle();

      expect(find.text('Greenhouse Temp'), findsOneWidget);
      expect(find.text('Soil Moisture'), findsOneWidget);
    });

    testWidgets('shows add FAB', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('shows app bar title', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Sensors'), findsOneWidget);
    });

    testWidgets('shows toggle switch on sensor cards', (tester) async {
      await tester.pumpWidget(buildScreen(sensors: [activeTempSensor]));
      await tester.pumpAndSettle();

      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('switch is on for active sensor', (tester) async {
      await tester.pumpWidget(buildScreen(sensors: [activeTempSensor]));
      await tester.pumpAndSettle();

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isTrue);
    });

    testWidgets('switch is off for inactive sensor', (tester) async {
      await tester.pumpWidget(buildScreen(sensors: [inactiveSoilSensor]));
      await tester.pumpAndSettle();

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isFalse);
    });

    testWidgets('shows sensor type text', (tester) async {
      await tester.pumpWidget(buildScreen(sensors: [activeTempSensor]));
      await tester.pumpAndSettle();

      expect(find.text('TEMPERATURE'), findsOneWidget);
    });

    testWidgets('shows poll interval', (tester) async {
      await tester.pumpWidget(buildScreen(sensors: [activeTempSensor]));
      await tester.pumpAndSettle();

      expect(find.text('30s'), findsOneWidget);
    });

    testWidgets('shows unit when present', (tester) async {
      await tester.pumpWidget(buildScreen(sensors: [activeTempSensor]));
      await tester.pumpAndSettle();

      expect(find.text('°C'), findsOneWidget);
    });
  });

  group('SensorsScreen error state', () {
    testWidgets('shows API error message', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          sensorsProvider.overrideWith((ref) =>
              throw const ApiException(statusCode: 500, message: 'Server down')),
          sensorServiceProvider.overrideWithValue(mockService),
        ],
        child: const MaterialApp(home: SensorsScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load sensors'), findsOneWidget);
      expect(find.text('Server down'), findsOneWidget);
    });

    testWidgets('shows generic error for non-API exception', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          sensorsProvider.overrideWith((ref) => throw Exception('unknown')),
          sensorServiceProvider.overrideWithValue(mockService),
        ],
        child: const MaterialApp(home: SensorsScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('An unexpected error occurred.'), findsOneWidget);
    });

    testWidgets('shows retry button on error', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          sensorsProvider.overrideWith((ref) =>
              throw const ApiException(statusCode: 500, message: 'Error')),
          sensorServiceProvider.overrideWithValue(mockService),
        ],
        child: const MaterialApp(home: SensorsScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('Navigation', () {
    testWidgets('FAB navigates to add sensor', (tester) async {
      final router = GoRouter(
        initialLocation: '/sensors',
        routes: [
          GoRoute(
            path: '/sensors',
            builder: (_, __) => const SensorsScreen(),
          ),
          GoRoute(
            path: '/sensors/add',
            builder: (_, __) =>
                const Scaffold(body: Text('Add Sensor Screen')),
          ),
        ],
      );

      await tester.pumpWidget(ProviderScope(
        overrides: [
          sensorsProvider.overrideWith((ref) => <SensorModel>[]),
          sensorServiceProvider.overrideWithValue(mockService),
        ],
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('Add Sensor Screen'), findsOneWidget);
    });

    testWidgets('sensor card tap navigates to detail', (tester) async {
      final router = GoRouter(
        initialLocation: '/sensors',
        routes: [
          GoRoute(
            path: '/sensors',
            builder: (_, __) => const SensorsScreen(),
          ),
          GoRoute(
            path: '/sensors/:id',
            builder: (_, state) =>
                Scaffold(body: Text('Sensor ${state.pathParameters['id']}')),
          ),
        ],
      );

      await tester.pumpWidget(ProviderScope(
        overrides: [
          sensorsProvider.overrideWith((ref) => [activeTempSensor]),
          sensorServiceProvider.overrideWithValue(mockService),
        ],
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Greenhouse Temp'));
      await tester.pumpAndSettle();

      expect(find.text('Sensor 1'), findsOneWidget);
    });
  });

  group('Sensor type icons', () {
    testWidgets('shows thermostat icon for temperature', (tester) async {
      await tester.pumpWidget(buildScreen(sensors: [activeTempSensor]));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.thermostat), findsOneWidget);
    });

    testWidgets('shows grass icon for soil moisture', (tester) async {
      await tester.pumpWidget(buildScreen(sensors: [inactiveSoilSensor]));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.grass), findsOneWidget);
    });

    testWidgets('shows water_drop icon for humidity', (tester) async {
      await tester.pumpWidget(buildScreen(sensors: [humiditySensor]));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.water_drop), findsOneWidget);
    });

    testWidgets('shows compress icon for pressure', (tester) async {
      await tester.pumpWidget(buildScreen(sensors: [pressureSensor]));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.compress), findsOneWidget);
    });

    testWidgets('shows air icon for wind speed', (tester) async {
      await tester.pumpWidget(buildScreen(sensors: [windSensor]));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.air), findsOneWidget);
    });

    testWidgets('shows wb_sunny icon for solar radiation', (tester) async {
      await tester.pumpWidget(buildScreen(sensors: [solarSensor]));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.wb_sunny), findsOneWidget);
    });
  });

  group('Toggle sensor', () {
    testWidgets('calls stopSensor for active sensor on toggle',
        (tester) async {
      when(() => mockService.stopSensor('1')).thenAnswer(
        (_) async => SensorModel.fromJson({
          'id': '1',
          'name': 'Greenhouse Temp',
          'type': 'TEMPERATURE',
          'baudRate': 9600,
          'isActive': false,
          'pollIntervalSeconds': 30,
        }),
      );

      await tester.pumpWidget(buildScreen(sensors: [activeTempSensor]));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      verify(() => mockService.stopSensor('1')).called(1);
    });

    testWidgets('calls startSensor for inactive sensor on toggle',
        (tester) async {
      when(() => mockService.startSensor('2')).thenAnswer(
        (_) async => SensorModel.fromJson({
          'id': '2',
          'name': 'Soil Moisture',
          'type': 'SOIL_MOISTURE',
          'baudRate': 9600,
          'isActive': true,
          'pollIntervalSeconds': 60,
        }),
      );

      await tester.pumpWidget(buildScreen(sensors: [inactiveSoilSensor]));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      verify(() => mockService.startSensor('2')).called(1);
    });

    testWidgets('shows error on toggle failure', (tester) async {
      when(() => mockService.stopSensor('1')).thenThrow(
        const ApiException(statusCode: 500, message: 'Toggle failed'),
      );

      await tester.pumpWidget(buildScreen(sensors: [activeTempSensor]));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.text('Toggle failed'), findsOneWidget);
    });
  });

  group('Delete sensor', () {
    testWidgets('long press shows delete confirmation', (tester) async {
      await tester.pumpWidget(buildScreen(sensors: [activeTempSensor]));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Greenhouse Temp'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Sensor'), findsOneWidget);
    });

    testWidgets('calls deleteSensor on confirm', (tester) async {
      when(() => mockService.deleteSensor('1')).thenAnswer((_) async {});

      await tester.pumpWidget(buildScreen(sensors: [activeTempSensor]));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Greenhouse Temp'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      verify(() => mockService.deleteSensor('1')).called(1);
    });

    testWidgets('does not delete on cancel', (tester) async {
      await tester.pumpWidget(buildScreen(sensors: [activeTempSensor]));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Greenhouse Temp'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      verifyNever(() => mockService.deleteSensor(any()));
    });

    testWidgets('shows error on delete failure', (tester) async {
      when(() => mockService.deleteSensor('1')).thenThrow(
        const ApiException(statusCode: 500, message: 'Delete failed'),
      );

      await tester.pumpWidget(buildScreen(sensors: [activeTempSensor]));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Greenhouse Temp'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(find.text('Delete failed'), findsOneWidget);
    });
  });

  group('Loading state', () {
    testWidgets('shows loading indicator while sensors load', (tester) async {
      final completer = Completer<List<SensorModel>>();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          sensorsProvider.overrideWith((ref) => completer.future),
          sensorServiceProvider.overrideWithValue(mockService),
        ],
        child: const MaterialApp(home: SensorsScreen()),
      ));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);

      completer.complete(<SensorModel>[]);
    });
  });

  group('Error retry', () {
    testWidgets('retry button reloads sensors after error', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          sensorsProvider.overrideWith((ref) =>
              throw const ApiException(statusCode: 500, message: 'Error')),
          sensorServiceProvider.overrideWithValue(mockService),
        ],
        child: const MaterialApp(home: SensorsScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load sensors'), findsOneWidget);
    });
  });
}
