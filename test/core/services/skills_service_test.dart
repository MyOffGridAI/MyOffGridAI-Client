import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/api/myoffgridai_api_client.dart';
import 'package:myoffgridai_client/core/services/skills_service.dart';

class MockApiClient extends Mock implements MyOffGridAIApiClient {}

void main() {
  late MockApiClient mockClient;
  late SkillsService service;

  setUp(() {
    mockClient = MockApiClient();
    service = SkillsService(client: mockClient);
  });

  // ---------------------------------------------------------------------------
  // listSkills
  // ---------------------------------------------------------------------------
  group('listSkills', () {
    test('returns parsed list from API response', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.skillsBasePath,
          )).thenAnswer((_) async => {
            'data': [
              {
                'id': 'skill-1',
                'name': 'weather_check',
                'displayName': 'Check Weather',
                'description': 'Fetches current weather data',
                'version': '1.0.0',
                'author': 'system',
                'category': 'WEATHER',
                'isEnabled': true,
                'isBuiltIn': true,
                'parametersSchema': '{"type":"object"}',
                'createdAt': '2026-01-01T00:00:00Z',
                'updatedAt': '2026-03-16T10:00:00Z',
              },
              {
                'id': 'skill-2',
                'name': 'inventory_report',
                'displayName': 'Inventory Report',
                'description': 'Generates inventory summary',
                'version': '2.1.0',
                'author': 'system',
                'category': 'INVENTORY',
                'isEnabled': false,
                'isBuiltIn': false,
                'parametersSchema': null,
                'createdAt': '2026-02-01T00:00:00Z',
                'updatedAt': '2026-03-15T08:00:00Z',
              },
            ],
          });

      final result = await service.listSkills();

      expect(result, hasLength(2));
      expect(result[0].id, 'skill-1');
      expect(result[0].name, 'weather_check');
      expect(result[0].displayName, 'Check Weather');
      expect(result[0].isEnabled, isTrue);
      expect(result[0].isBuiltIn, isTrue);
      expect(result[1].id, 'skill-2');
      expect(result[1].isEnabled, isFalse);
      expect(result[1].isBuiltIn, isFalse);
    });

    test('returns empty list when data is null', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.skillsBasePath,
          )).thenAnswer((_) async => {'data': null});

      final result = await service.listSkills();

      expect(result, isEmpty);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.skillsBasePath,
          )).thenThrow(const ApiException(
        statusCode: 500,
        message: 'Internal server error',
      ));

      expect(
        () => service.listSkills(),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // getSkill
  // ---------------------------------------------------------------------------
  group('getSkill', () {
    test('returns SkillModel for given id', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.skillsBasePath}/skill-1',
          )).thenAnswer((_) async => {
            'data': {
              'id': 'skill-1',
              'name': 'weather_check',
              'displayName': 'Check Weather',
              'description': 'Fetches current weather data',
              'version': '1.0.0',
              'author': 'system',
              'category': 'WEATHER',
              'isEnabled': true,
              'isBuiltIn': true,
              'parametersSchema': '{"type":"object"}',
              'createdAt': '2026-01-01T00:00:00Z',
              'updatedAt': '2026-03-16T10:00:00Z',
            },
          });

      final result = await service.getSkill('skill-1');

      expect(result.id, 'skill-1');
      expect(result.name, 'weather_check');
      expect(result.category, 'WEATHER');
      verify(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.skillsBasePath}/skill-1',
          )).called(1);
    });

    test('throws ApiException on 404', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.skillsBasePath}/missing',
          )).thenThrow(const ApiException(
        statusCode: 404,
        message: 'Skill not found',
      ));

      expect(
        () => service.getSkill('missing'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // toggleSkill
  // ---------------------------------------------------------------------------
  group('toggleSkill', () {
    test('sends enabled flag and returns updated model', () async {
      when(() => mockClient.patch<Map<String, dynamic>>(
            '${AppConstants.skillsBasePath}/skill-2/toggle',
            data: any(named: 'data'),
          )).thenAnswer((_) async => {
            'data': {
              'id': 'skill-2',
              'name': 'inventory_report',
              'displayName': 'Inventory Report',
              'description': 'Generates inventory summary',
              'version': '2.1.0',
              'author': 'system',
              'category': 'INVENTORY',
              'isEnabled': true,
              'isBuiltIn': false,
              'parametersSchema': null,
              'createdAt': '2026-02-01T00:00:00Z',
              'updatedAt': '2026-03-16T15:00:00Z',
            },
          });

      final result = await service.toggleSkill('skill-2', true);

      expect(result.id, 'skill-2');
      expect(result.isEnabled, isTrue);

      final captured = verify(() => mockClient.patch<Map<String, dynamic>>(
            '${AppConstants.skillsBasePath}/skill-2/toggle',
            data: captureAny(named: 'data'),
          )).captured;

      final sentData = captured.first as Map<String, dynamic>;
      expect(sentData['enabled'], true);
    });

    test('can disable a skill', () async {
      when(() => mockClient.patch<Map<String, dynamic>>(
            '${AppConstants.skillsBasePath}/skill-1/toggle',
            data: any(named: 'data'),
          )).thenAnswer((_) async => {
            'data': {
              'id': 'skill-1',
              'name': 'weather_check',
              'displayName': 'Check Weather',
              'description': 'Fetches current weather data',
              'version': '1.0.0',
              'author': 'system',
              'category': 'WEATHER',
              'isEnabled': false,
              'isBuiltIn': true,
              'parametersSchema': '{"type":"object"}',
              'createdAt': '2026-01-01T00:00:00Z',
              'updatedAt': '2026-03-16T15:30:00Z',
            },
          });

      final result = await service.toggleSkill('skill-1', false);

      expect(result.isEnabled, isFalse);

      final captured = verify(() => mockClient.patch<Map<String, dynamic>>(
            '${AppConstants.skillsBasePath}/skill-1/toggle',
            data: captureAny(named: 'data'),
          )).captured;

      final sentData = captured.first as Map<String, dynamic>;
      expect(sentData['enabled'], false);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.patch<Map<String, dynamic>>(
            '${AppConstants.skillsBasePath}/skill-1/toggle',
            data: any(named: 'data'),
          )).thenThrow(const ApiException(
        statusCode: 404,
        message: 'Skill not found',
      ));

      expect(
        () => service.toggleSkill('skill-1', true),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // executeSkill
  // ---------------------------------------------------------------------------
  group('executeSkill', () {
    test('sends skillId and returns execution result', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.skillsBasePath}/execute',
            data: any(named: 'data'),
          )).thenAnswer((_) async => {
            'data': {
              'id': 'exec-1',
              'skillId': 'skill-1',
              'skillName': 'weather_check',
              'userId': 'user-1',
              'status': 'SUCCESS',
              'inputParams': '{"location":"home"}',
              'outputResult': '{"temp":22,"humidity":45}',
              'errorMessage': null,
              'startedAt': '2026-03-16T10:00:00Z',
              'completedAt': '2026-03-16T10:00:02Z',
              'durationMs': 2000,
            },
          });

      final result = await service.executeSkill(
        'skill-1',
        params: {'location': 'home'},
      );

      expect(result.id, 'exec-1');
      expect(result.skillId, 'skill-1');
      expect(result.status, 'SUCCESS');
      expect(result.isSuccess, isTrue);
      expect(result.durationMs, 2000);
    });

    test('sends skillId without params when params is null', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.skillsBasePath}/execute',
            data: any(named: 'data'),
          )).thenAnswer((_) async => {
            'data': {
              'id': 'exec-2',
              'skillId': 'skill-2',
              'skillName': 'inventory_report',
              'userId': 'user-1',
              'status': 'RUNNING',
              'inputParams': null,
              'outputResult': null,
              'errorMessage': null,
              'startedAt': '2026-03-16T10:01:00Z',
              'completedAt': null,
              'durationMs': null,
            },
          });

      final result = await service.executeSkill('skill-2');

      expect(result.isRunning, isTrue);

      final captured = verify(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.skillsBasePath}/execute',
            data: captureAny(named: 'data'),
          )).captured;

      final sentData = captured.first as Map<String, dynamic>;
      expect(sentData['skillId'], 'skill-2');
      expect(sentData.containsKey('params'), isFalse);
    });

    test('includes params when provided', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.skillsBasePath}/execute',
            data: any(named: 'data'),
          )).thenAnswer((_) async => {
            'data': {
              'id': 'exec-3',
              'skillId': 'skill-1',
              'skillName': 'weather_check',
              'userId': 'user-1',
              'status': 'SUCCESS',
              'inputParams': '{"location":"garden"}',
              'outputResult': '{"temp":25}',
              'errorMessage': null,
              'startedAt': '2026-03-16T10:02:00Z',
              'completedAt': '2026-03-16T10:02:01Z',
              'durationMs': 1000,
            },
          });

      await service.executeSkill('skill-1', params: {'location': 'garden'});

      final captured = verify(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.skillsBasePath}/execute',
            data: captureAny(named: 'data'),
          )).captured;

      final sentData = captured.first as Map<String, dynamic>;
      expect(sentData['skillId'], 'skill-1');
      expect(sentData['params'], {'location': 'garden'});
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.skillsBasePath}/execute',
            data: any(named: 'data'),
          )).thenThrow(const ApiException(
        statusCode: 503,
        message: 'Skill execution service unavailable',
      ));

      expect(
        () => service.executeSkill('skill-1'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // listExecutions
  // ---------------------------------------------------------------------------
  group('listExecutions', () {
    test('returns parsed list from API response', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.skillsBasePath}/executions',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': [
              {
                'id': 'exec-1',
                'skillId': 'skill-1',
                'skillName': 'weather_check',
                'userId': 'user-1',
                'status': 'SUCCESS',
                'inputParams': null,
                'outputResult': '{"temp":22}',
                'errorMessage': null,
                'startedAt': '2026-03-16T10:00:00Z',
                'completedAt': '2026-03-16T10:00:02Z',
                'durationMs': 2000,
              },
              {
                'id': 'exec-2',
                'skillId': 'skill-2',
                'skillName': 'inventory_report',
                'userId': 'user-1',
                'status': 'FAILED',
                'inputParams': null,
                'outputResult': null,
                'errorMessage': 'Timeout',
                'startedAt': '2026-03-16T09:00:00Z',
                'completedAt': '2026-03-16T09:00:30Z',
                'durationMs': 30000,
              },
            ],
          });

      final result = await service.listExecutions();

      expect(result, hasLength(2));
      expect(result[0].id, 'exec-1');
      expect(result[0].isSuccess, isTrue);
      expect(result[1].id, 'exec-2');
      expect(result[1].isFailed, isTrue);
      expect(result[1].errorMessage, 'Timeout');
    });

    test('passes pagination query params', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.skillsBasePath}/executions',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {'data': <dynamic>[]});

      await service.listExecutions(page: 3, size: 50);

      final captured = verify(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.skillsBasePath}/executions',
            queryParams: captureAny(named: 'queryParams'),
          )).captured;

      final params = captured.first as Map<String, dynamic>;
      expect(params['page'], 3);
      expect(params['size'], 50);
    });

    test('returns empty list when data is null', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.skillsBasePath}/executions',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {'data': null});

      final result = await service.listExecutions();

      expect(result, isEmpty);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.skillsBasePath}/executions',
            queryParams: any(named: 'queryParams'),
          )).thenThrow(const ApiException(
        statusCode: 500,
        message: 'Database error',
      ));

      expect(
        () => service.listExecutions(),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
