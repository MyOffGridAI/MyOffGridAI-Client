import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/api/myoffgridai_api_client.dart';
import 'package:myoffgridai_client/core/services/sensor_service.dart';

class MockApiClient extends Mock implements MyOffGridAIApiClient {}

void main() {
  late MockApiClient mockClient;
  late SensorService service;

  setUp(() {
    mockClient = MockApiClient();
    service = SensorService(client: mockClient);
  });

  // ---------------------------------------------------------------------------
  // listSensors
  // ---------------------------------------------------------------------------
  group('listSensors', () {
    test('returns parsed list from API response', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.sensorsBasePath,
          )).thenAnswer((_) async => {
            'data': [
              {
                'id': 'sensor-1',
                'name': 'Greenhouse Temp',
                'type': 'TEMPERATURE',
                'portPath': '/dev/ttyUSB0',
                'baudRate': 9600,
                'dataFormat': 'JSON_LINE',
                'valueField': 'temp',
                'unit': 'C',
                'isActive': true,
                'pollIntervalSeconds': 30,
                'lowThreshold': 5.0,
                'highThreshold': 40.0,
                'createdAt': '2026-03-01T08:00:00Z',
                'updatedAt': '2026-03-16T10:00:00Z',
              },
              {
                'id': 'sensor-2',
                'name': 'Soil Moisture',
                'type': 'SOIL_MOISTURE',
                'portPath': '/dev/ttyUSB1',
                'baudRate': 115200,
                'dataFormat': 'CSV_LINE',
                'valueField': null,
                'unit': '%',
                'isActive': false,
                'pollIntervalSeconds': 60,
                'lowThreshold': 20.0,
                'highThreshold': null,
                'createdAt': '2026-03-05T12:00:00Z',
                'updatedAt': '2026-03-16T10:00:00Z',
              },
            ],
          });

      final result = await service.listSensors();

      expect(result, hasLength(2));
      expect(result[0].id, 'sensor-1');
      expect(result[0].name, 'Greenhouse Temp');
      expect(result[0].type, 'TEMPERATURE');
      expect(result[0].isActive, isTrue);
      expect(result[0].lowThreshold, 5.0);
      expect(result[0].highThreshold, 40.0);
      expect(result[1].id, 'sensor-2');
      expect(result[1].isActive, isFalse);
      expect(result[1].highThreshold, isNull);
    });

    test('returns empty list when data is null', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.sensorsBasePath,
          )).thenAnswer((_) async => {'data': null});

      final result = await service.listSensors();

      expect(result, isEmpty);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.sensorsBasePath,
          )).thenThrow(const ApiException(
        statusCode: 500,
        message: 'Internal server error',
      ));

      expect(
        () => service.listSensors(),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // getSensor
  // ---------------------------------------------------------------------------
  group('getSensor', () {
    test('returns SensorModel for given id', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.sensorsBasePath}/sensor-1',
          )).thenAnswer((_) async => {
            'data': {
              'id': 'sensor-1',
              'name': 'Greenhouse Temp',
              'type': 'TEMPERATURE',
              'portPath': '/dev/ttyUSB0',
              'baudRate': 9600,
              'dataFormat': 'JSON_LINE',
              'valueField': 'temp',
              'unit': 'C',
              'isActive': true,
              'pollIntervalSeconds': 30,
              'lowThreshold': 5.0,
              'highThreshold': 40.0,
              'createdAt': '2026-03-01T08:00:00Z',
              'updatedAt': '2026-03-16T10:00:00Z',
            },
          });

      final result = await service.getSensor('sensor-1');

      expect(result.id, 'sensor-1');
      expect(result.name, 'Greenhouse Temp');
      expect(result.baudRate, 9600);
      verify(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.sensorsBasePath}/sensor-1',
          )).called(1);
    });

    test('throws ApiException on 404', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.sensorsBasePath}/missing',
          )).thenThrow(const ApiException(
        statusCode: 404,
        message: 'Sensor not found',
      ));

      expect(
        () => service.getSensor('missing'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // createSensor
  // ---------------------------------------------------------------------------
  group('createSensor', () {
    test('sends all required fields and returns model', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            AppConstants.sensorsBasePath,
            data: any(named: 'data'),
          )).thenAnswer((_) async => {
            'data': {
              'id': 'sensor-new',
              'name': 'Wind Speed',
              'type': 'WIND_SPEED',
              'portPath': '/dev/ttyUSB2',
              'baudRate': 9600,
              'dataFormat': null,
              'valueField': null,
              'unit': 'km/h',
              'isActive': false,
              'pollIntervalSeconds': 60,
              'lowThreshold': null,
              'highThreshold': null,
              'createdAt': '2026-03-16T14:00:00Z',
              'updatedAt': '2026-03-16T14:00:00Z',
            },
          });

      final result = await service.createSensor(
        name: 'Wind Speed',
        type: 'WIND_SPEED',
        portPath: '/dev/ttyUSB2',
        pollIntervalSeconds: 60,
        unit: 'km/h',
      );

      expect(result.id, 'sensor-new');
      expect(result.name, 'Wind Speed');
      expect(result.type, 'WIND_SPEED');

      final captured = verify(() => mockClient.post<Map<String, dynamic>>(
            AppConstants.sensorsBasePath,
            data: captureAny(named: 'data'),
          )).captured;

      final sentData = captured.first as Map<String, dynamic>;
      expect(sentData['name'], 'Wind Speed');
      expect(sentData['type'], 'WIND_SPEED');
      expect(sentData['portPath'], '/dev/ttyUSB2');
      expect(sentData['pollIntervalSeconds'], 60);
      expect(sentData['unit'], 'km/h');
      // Optional fields not provided should be absent
      expect(sentData.containsKey('baudRate'), isFalse);
      expect(sentData.containsKey('dataFormat'), isFalse);
      expect(sentData.containsKey('valueField'), isFalse);
      expect(sentData.containsKey('lowThreshold'), isFalse);
      expect(sentData.containsKey('highThreshold'), isFalse);
    });

    test('includes optional fields when provided', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            AppConstants.sensorsBasePath,
            data: any(named: 'data'),
          )).thenAnswer((_) async => {
            'data': {
              'id': 'sensor-full',
              'name': 'Temp Sensor',
              'type': 'TEMPERATURE',
              'portPath': '/dev/ttyUSB0',
              'baudRate': 115200,
              'dataFormat': 'JSON_LINE',
              'valueField': 'temperature',
              'unit': 'F',
              'isActive': false,
              'pollIntervalSeconds': 15,
              'lowThreshold': 32.0,
              'highThreshold': 100.0,
              'createdAt': '2026-03-16T14:00:00Z',
              'updatedAt': '2026-03-16T14:00:00Z',
            },
          });

      await service.createSensor(
        name: 'Temp Sensor',
        type: 'TEMPERATURE',
        portPath: '/dev/ttyUSB0',
        baudRate: 115200,
        dataFormat: 'JSON_LINE',
        valueField: 'temperature',
        unit: 'F',
        pollIntervalSeconds: 15,
        lowThreshold: 32.0,
        highThreshold: 100.0,
      );

      final captured = verify(() => mockClient.post<Map<String, dynamic>>(
            AppConstants.sensorsBasePath,
            data: captureAny(named: 'data'),
          )).captured;

      final sentData = captured.first as Map<String, dynamic>;
      expect(sentData['baudRate'], 115200);
      expect(sentData['dataFormat'], 'JSON_LINE');
      expect(sentData['valueField'], 'temperature');
      expect(sentData['unit'], 'F');
      expect(sentData['lowThreshold'], 32.0);
      expect(sentData['highThreshold'], 100.0);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            AppConstants.sensorsBasePath,
            data: any(named: 'data'),
          )).thenThrow(const ApiException(
        statusCode: 400,
        message: 'Invalid port path',
      ));

      expect(
        () => service.createSensor(
          name: 'Bad Sensor',
          type: 'TEMPERATURE',
          portPath: '',
          pollIntervalSeconds: 30,
        ),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // deleteSensor
  // ---------------------------------------------------------------------------
  group('deleteSensor', () {
    test('calls DELETE on correct path', () async {
      when(() => mockClient.delete(
            '${AppConstants.sensorsBasePath}/sensor-1',
          )).thenAnswer((_) async {});

      await service.deleteSensor('sensor-1');

      verify(() => mockClient.delete(
            '${AppConstants.sensorsBasePath}/sensor-1',
          )).called(1);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.delete(
            '${AppConstants.sensorsBasePath}/sensor-1',
          )).thenThrow(const ApiException(
        statusCode: 409,
        message: 'Sensor is currently active',
      ));

      expect(
        () => service.deleteSensor('sensor-1'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // startSensor
  // ---------------------------------------------------------------------------
  group('startSensor', () {
    test('sends POST and returns updated model', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.sensorsBasePath}/sensor-1/start',
          )).thenAnswer((_) async => {
            'data': {
              'id': 'sensor-1',
              'name': 'Greenhouse Temp',
              'type': 'TEMPERATURE',
              'portPath': '/dev/ttyUSB0',
              'baudRate': 9600,
              'dataFormat': 'JSON_LINE',
              'valueField': 'temp',
              'unit': 'C',
              'isActive': true,
              'pollIntervalSeconds': 30,
              'lowThreshold': 5.0,
              'highThreshold': 40.0,
              'createdAt': '2026-03-01T08:00:00Z',
              'updatedAt': '2026-03-16T15:00:00Z',
            },
          });

      final result = await service.startSensor('sensor-1');

      expect(result.id, 'sensor-1');
      expect(result.isActive, isTrue);
      verify(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.sensorsBasePath}/sensor-1/start',
          )).called(1);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.sensorsBasePath}/sensor-1/start',
          )).thenThrow(const ApiException(
        statusCode: 500,
        message: 'Failed to open serial port',
      ));

      expect(
        () => service.startSensor('sensor-1'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // stopSensor
  // ---------------------------------------------------------------------------
  group('stopSensor', () {
    test('sends POST and returns updated model', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.sensorsBasePath}/sensor-1/stop',
          )).thenAnswer((_) async => {
            'data': {
              'id': 'sensor-1',
              'name': 'Greenhouse Temp',
              'type': 'TEMPERATURE',
              'portPath': '/dev/ttyUSB0',
              'baudRate': 9600,
              'dataFormat': 'JSON_LINE',
              'valueField': 'temp',
              'unit': 'C',
              'isActive': false,
              'pollIntervalSeconds': 30,
              'lowThreshold': 5.0,
              'highThreshold': 40.0,
              'createdAt': '2026-03-01T08:00:00Z',
              'updatedAt': '2026-03-16T15:30:00Z',
            },
          });

      final result = await service.stopSensor('sensor-1');

      expect(result.id, 'sensor-1');
      expect(result.isActive, isFalse);
      verify(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.sensorsBasePath}/sensor-1/stop',
          )).called(1);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.sensorsBasePath}/sensor-1/stop',
          )).thenThrow(const ApiException(
        statusCode: 404,
        message: 'Sensor not found',
      ));

      expect(
        () => service.stopSensor('sensor-1'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // getLatestReading
  // ---------------------------------------------------------------------------
  group('getLatestReading', () {
    test('returns SensorReadingModel when data exists', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.sensorsBasePath}/sensor-1/latest',
          )).thenAnswer((_) async => {
            'data': {
              'id': 'reading-1',
              'sensorId': 'sensor-1',
              'value': 23.5,
              'rawData': '{"temp":23.5}',
              'recordedAt': '2026-03-16T15:00:00Z',
            },
          });

      final result = await service.getLatestReading('sensor-1');

      expect(result, isNotNull);
      expect(result!.id, 'reading-1');
      expect(result.sensorId, 'sensor-1');
      expect(result.value, 23.5);
      expect(result.rawData, '{"temp":23.5}');
    });

    test('returns null when data is null', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.sensorsBasePath}/sensor-1/latest',
          )).thenAnswer((_) async => {'data': null});

      final result = await service.getLatestReading('sensor-1');

      expect(result, isNull);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.sensorsBasePath}/sensor-1/latest',
          )).thenThrow(const ApiException(
        statusCode: 404,
        message: 'Sensor not found',
      ));

      expect(
        () => service.getLatestReading('sensor-1'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // getHistory
  // ---------------------------------------------------------------------------
  group('getHistory', () {
    test('returns parsed reading list', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.sensorsBasePath}/sensor-1/history',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': [
              {
                'id': 'reading-1',
                'sensorId': 'sensor-1',
                'value': 22.0,
                'rawData': null,
                'recordedAt': '2026-03-16T14:00:00Z',
              },
              {
                'id': 'reading-2',
                'sensorId': 'sensor-1',
                'value': 23.5,
                'rawData': null,
                'recordedAt': '2026-03-16T15:00:00Z',
              },
            ],
          });

      final result = await service.getHistory('sensor-1');

      expect(result, hasLength(2));
      expect(result[0].id, 'reading-1');
      expect(result[0].value, 22.0);
      expect(result[1].value, 23.5);
    });

    test('passes hours and pagination query params', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.sensorsBasePath}/sensor-1/history',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {'data': <dynamic>[]});

      await service.getHistory('sensor-1', hours: 48, page: 2, size: 50);

      final captured = verify(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.sensorsBasePath}/sensor-1/history',
            queryParams: captureAny(named: 'queryParams'),
          )).captured;

      final params = captured.first as Map<String, dynamic>;
      expect(params['hours'], 48);
      expect(params['page'], 2);
      expect(params['size'], 50);
    });

    test('uses default values for hours, page, and size', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.sensorsBasePath}/sensor-1/history',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {'data': <dynamic>[]});

      await service.getHistory('sensor-1');

      final captured = verify(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.sensorsBasePath}/sensor-1/history',
            queryParams: captureAny(named: 'queryParams'),
          )).captured;

      final params = captured.first as Map<String, dynamic>;
      expect(params['hours'], 24);
      expect(params['page'], 0);
      expect(params['size'], 20);
    });

    test('returns empty list when data is null', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.sensorsBasePath}/sensor-1/history',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {'data': null});

      final result = await service.getHistory('sensor-1');

      expect(result, isEmpty);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.sensorsBasePath}/sensor-1/history',
            queryParams: any(named: 'queryParams'),
          )).thenThrow(const ApiException(
        statusCode: 500,
        message: 'Database error',
      ));

      expect(
        () => service.getHistory('sensor-1'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // updateThresholds
  // ---------------------------------------------------------------------------
  group('updateThresholds', () {
    test('sends thresholds and returns updated model', () async {
      when(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.sensorsBasePath}/sensor-1/thresholds',
            data: any(named: 'data'),
          )).thenAnswer((_) async => {
            'data': {
              'id': 'sensor-1',
              'name': 'Greenhouse Temp',
              'type': 'TEMPERATURE',
              'portPath': '/dev/ttyUSB0',
              'baudRate': 9600,
              'dataFormat': 'JSON_LINE',
              'valueField': 'temp',
              'unit': 'C',
              'isActive': true,
              'pollIntervalSeconds': 30,
              'lowThreshold': 0.0,
              'highThreshold': 45.0,
              'createdAt': '2026-03-01T08:00:00Z',
              'updatedAt': '2026-03-16T16:00:00Z',
            },
          });

      final result = await service.updateThresholds(
        'sensor-1',
        lowThreshold: 0.0,
        highThreshold: 45.0,
      );

      expect(result.id, 'sensor-1');
      expect(result.lowThreshold, 0.0);
      expect(result.highThreshold, 45.0);

      final captured = verify(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.sensorsBasePath}/sensor-1/thresholds',
            data: captureAny(named: 'data'),
          )).captured;

      final sentData = captured.first as Map<String, dynamic>;
      expect(sentData['lowThreshold'], 0.0);
      expect(sentData['highThreshold'], 45.0);
    });

    test('sends null thresholds when not provided', () async {
      when(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.sensorsBasePath}/sensor-1/thresholds',
            data: any(named: 'data'),
          )).thenAnswer((_) async => {
            'data': {
              'id': 'sensor-1',
              'name': 'Greenhouse Temp',
              'type': 'TEMPERATURE',
              'portPath': '/dev/ttyUSB0',
              'baudRate': 9600,
              'dataFormat': 'JSON_LINE',
              'valueField': 'temp',
              'unit': 'C',
              'isActive': true,
              'pollIntervalSeconds': 30,
              'lowThreshold': null,
              'highThreshold': null,
              'createdAt': '2026-03-01T08:00:00Z',
              'updatedAt': '2026-03-16T16:00:00Z',
            },
          });

      final result = await service.updateThresholds('sensor-1');

      expect(result.lowThreshold, isNull);
      expect(result.highThreshold, isNull);

      final captured = verify(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.sensorsBasePath}/sensor-1/thresholds',
            data: captureAny(named: 'data'),
          )).captured;

      final sentData = captured.first as Map<String, dynamic>;
      expect(sentData['lowThreshold'], isNull);
      expect(sentData['highThreshold'], isNull);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.sensorsBasePath}/sensor-1/thresholds',
            data: any(named: 'data'),
          )).thenThrow(const ApiException(
        statusCode: 400,
        message: 'Low threshold must be less than high threshold',
      ));

      expect(
        () => service.updateThresholds(
          'sensor-1',
          lowThreshold: 50.0,
          highThreshold: 10.0,
        ),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // testConnection
  // ---------------------------------------------------------------------------
  group('testConnection', () {
    test('sends portPath and baudRate, returns test result', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.sensorsBasePath}/test',
            data: any(named: 'data'),
          )).thenAnswer((_) async => {
            'data': {
              'success': true,
              'portPath': '/dev/ttyUSB0',
              'baudRate': 9600,
              'sampleData': '{"temp":22.5}',
              'message': 'Connection successful',
            },
          });

      final result = await service.testConnection('/dev/ttyUSB0', 9600);

      expect(result.success, isTrue);
      expect(result.portPath, '/dev/ttyUSB0');
      expect(result.baudRate, 9600);
      expect(result.sampleData, '{"temp":22.5}');
      expect(result.message, 'Connection successful');

      final captured = verify(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.sensorsBasePath}/test',
            data: captureAny(named: 'data'),
          )).captured;

      final sentData = captured.first as Map<String, dynamic>;
      expect(sentData['portPath'], '/dev/ttyUSB0');
      expect(sentData['baudRate'], 9600);
    });

    test('handles failed connection test', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.sensorsBasePath}/test',
            data: any(named: 'data'),
          )).thenAnswer((_) async => {
            'data': {
              'success': false,
              'portPath': '/dev/ttyUSB5',
              'baudRate': 9600,
              'sampleData': null,
              'message': 'Port not found',
            },
          });

      final result = await service.testConnection('/dev/ttyUSB5', 9600);

      expect(result.success, isFalse);
      expect(result.sampleData, isNull);
      expect(result.message, 'Port not found');
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.sensorsBasePath}/test',
            data: any(named: 'data'),
          )).thenThrow(const ApiException(
        statusCode: 500,
        message: 'Serial port service unavailable',
      ));

      expect(
        () => service.testConnection('/dev/ttyUSB0', 9600),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // listPorts
  // ---------------------------------------------------------------------------
  group('listPorts', () {
    test('returns list of port path strings', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.sensorsBasePath}/ports',
          )).thenAnswer((_) async => {
            'data': ['/dev/ttyUSB0', '/dev/ttyUSB1', '/dev/ttyACM0'],
          });

      final result = await service.listPorts();

      expect(result, hasLength(3));
      expect(result[0], '/dev/ttyUSB0');
      expect(result[1], '/dev/ttyUSB1');
      expect(result[2], '/dev/ttyACM0');
    });

    test('returns empty list when data is null', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.sensorsBasePath}/ports',
          )).thenAnswer((_) async => {'data': null});

      final result = await service.listPorts();

      expect(result, isEmpty);
    });

    test('returns empty list when no ports available', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.sensorsBasePath}/ports',
          )).thenAnswer((_) async => {'data': <dynamic>[]});

      final result = await service.listPorts();

      expect(result, isEmpty);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.sensorsBasePath}/ports',
          )).thenThrow(const ApiException(
        statusCode: 500,
        message: 'Cannot enumerate serial ports',
      ));

      expect(
        () => service.listPorts(),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
