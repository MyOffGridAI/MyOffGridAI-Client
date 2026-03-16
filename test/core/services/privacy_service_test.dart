import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/api/myoffgridai_api_client.dart';
import 'package:myoffgridai_client/core/services/privacy_service.dart';

class MockApiClient extends Mock implements MyOffGridAIApiClient {}

void main() {
  late MockApiClient mockClient;
  late PrivacyService service;

  setUp(() {
    mockClient = MockApiClient();
    service = PrivacyService(client: mockClient);
  });

  group('getFortressStatus', () {
    test('returns parsed fortress status', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.privacyBasePath}/fortress/status',
          )).thenAnswer((_) async => {
            'data': {
              'enabled': true,
              'enabledAt': '2026-03-10T12:00:00Z',
              'enabledByUsername': 'admin',
              'verified': true,
            },
          });

      final result = await service.getFortressStatus();

      expect(result.enabled, isTrue);
      expect(result.enabledAt, '2026-03-10T12:00:00Z');
      expect(result.enabledByUsername, 'admin');
      expect(result.verified, isTrue);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.privacyBasePath}/fortress/status',
          )).thenThrow(const ApiException(
        statusCode: 500,
        message: 'Internal server error',
      ));

      expect(
        () => service.getFortressStatus(),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('enableFortress', () {
    test('calls POST on enable endpoint', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.privacyBasePath}/fortress/enable',
          )).thenAnswer((_) async => <String, dynamic>{});

      await service.enableFortress();

      verify(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.privacyBasePath}/fortress/enable',
          )).called(1);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.privacyBasePath}/fortress/enable',
          )).thenThrow(const ApiException(
        statusCode: 403,
        message: 'Only OWNER or ADMIN can enable fortress',
      ));

      expect(
        () => service.enableFortress(),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('disableFortress', () {
    test('calls POST on disable endpoint', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.privacyBasePath}/fortress/disable',
          )).thenAnswer((_) async => <String, dynamic>{});

      await service.disableFortress();

      verify(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.privacyBasePath}/fortress/disable',
          )).called(1);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.privacyBasePath}/fortress/disable',
          )).thenThrow(const ApiException(
        statusCode: 403,
        message: 'Only OWNER or ADMIN can disable fortress',
      ));

      expect(
        () => service.disableFortress(),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('getSovereigntyReport', () {
    test('returns parsed sovereignty report with all fields', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.privacyBasePath}/sovereignty-report',
          )).thenAnswer((_) async => {
            'data': {
              'generatedAt': '2026-03-16T12:00:00Z',
              'fortressStatus': {
                'enabled': true,
                'enabledAt': '2026-03-10T12:00:00Z',
                'enabledByUsername': 'admin',
                'verified': true,
              },
              'outboundTrafficVerification': 'NO_OUTBOUND_TRAFFIC',
              'dataInventory': {
                'conversationCount': 15,
                'messageCount': 230,
                'memoryCount': 42,
                'knowledgeDocumentCount': 8,
                'sensorCount': 6,
                'insightCount': 12,
              },
              'auditSummary': {
                'successCount': 500,
                'failureCount': 3,
                'deniedCount': 1,
                'windowStart': '2026-03-09T00:00:00Z',
                'windowEnd': '2026-03-16T00:00:00Z',
              },
              'encryptionStatus': 'AES_256_GCM',
              'telemetryStatus': 'DISABLED',
              'lastVerifiedAt': '2026-03-16T11:59:00Z',
            },
          });

      final result = await service.getSovereigntyReport();

      expect(result.generatedAt, '2026-03-16T12:00:00Z');
      expect(result.fortressStatus, isNotNull);
      expect(result.fortressStatus!.enabled, isTrue);
      expect(result.outboundTrafficVerification, 'NO_OUTBOUND_TRAFFIC');
      expect(result.dataInventory, isNotNull);
      expect(result.dataInventory!.conversationCount, 15);
      expect(result.dataInventory!.messageCount, 230);
      expect(result.dataInventory!.memoryCount, 42);
      expect(result.dataInventory!.knowledgeDocumentCount, 8);
      expect(result.dataInventory!.sensorCount, 6);
      expect(result.dataInventory!.insightCount, 12);
      expect(result.auditSummary, isNotNull);
      expect(result.auditSummary!.successCount, 500);
      expect(result.auditSummary!.failureCount, 3);
      expect(result.auditSummary!.deniedCount, 1);
      expect(result.encryptionStatus, 'AES_256_GCM');
      expect(result.telemetryStatus, 'DISABLED');
    });

    test('handles minimal sovereignty report', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.privacyBasePath}/sovereignty-report',
          )).thenAnswer((_) async => {
            'data': <String, dynamic>{},
          });

      final result = await service.getSovereigntyReport();

      expect(result.generatedAt, isNull);
      expect(result.fortressStatus, isNull);
      expect(result.dataInventory, isNull);
      expect(result.auditSummary, isNull);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.privacyBasePath}/sovereignty-report',
          )).thenThrow(const ApiException(
        statusCode: 500,
        message: 'Internal server error',
      ));

      expect(
        () => service.getSovereigntyReport(),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('getAuditLogs', () {
    test('returns parsed list of audit logs', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.privacyBasePath}/audit-logs',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': [
              {
                'id': 'log1',
                'userId': 'u1',
                'username': 'adam',
                'action': 'READ_CONVERSATION',
                'resourceType': 'CONVERSATION',
                'resourceId': 'conv-1',
                'httpMethod': 'GET',
                'requestPath': '/api/chat/conversations/conv-1',
                'outcome': 'SUCCESS',
                'responseStatus': 200,
                'durationMs': 45,
                'timestamp': '2026-03-16T10:00:00Z',
              },
            ],
          });

      final result = await service.getAuditLogs();

      expect(result, hasLength(1));
      expect(result[0].id, 'log1');
      expect(result[0].action, 'READ_CONVERSATION');
      expect(result[0].outcome, 'SUCCESS');
      expect(result[0].responseStatus, 200);
      expect(result[0].durationMs, 45);
    });

    test('passes default pagination params', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.privacyBasePath}/audit-logs',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {'data': <dynamic>[]});

      await service.getAuditLogs();

      final captured = verify(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.privacyBasePath}/audit-logs',
            queryParams: captureAny(named: 'queryParams'),
          )).captured;

      final params = captured.first as Map<String, dynamic>;
      expect(params['page'], 0);
      expect(params['size'], 20);
      expect(params.containsKey('outcome'), isFalse);
    });

    test('passes outcome filter and custom pagination', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.privacyBasePath}/audit-logs',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {'data': <dynamic>[]});

      await service.getAuditLogs(outcome: 'DENIED', page: 3, size: 50);

      final captured = verify(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.privacyBasePath}/audit-logs',
            queryParams: captureAny(named: 'queryParams'),
          )).captured;

      final params = captured.first as Map<String, dynamic>;
      expect(params['outcome'], 'DENIED');
      expect(params['page'], 3);
      expect(params['size'], 50);
    });

    test('returns empty list when data is null', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.privacyBasePath}/audit-logs',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {'data': null});

      final result = await service.getAuditLogs();

      expect(result, isEmpty);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.privacyBasePath}/audit-logs',
            queryParams: any(named: 'queryParams'),
          )).thenThrow(const ApiException(
        statusCode: 403,
        message: 'Forbidden',
      ));

      expect(
        () => service.getAuditLogs(),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('wipeSelfData', () {
    test('calls DELETE and returns result', () async {
      when(() => mockClient.delete(
            '${AppConstants.privacyBasePath}/wipe/self',
          )).thenAnswer((_) async {});

      final result = await service.wipeSelfData();

      expect(result.success, isTrue);
      expect(result.stepsCompleted, 0);
      verify(() => mockClient.delete(
            '${AppConstants.privacyBasePath}/wipe/self',
          )).called(1);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.delete(
            '${AppConstants.privacyBasePath}/wipe/self',
          )).thenThrow(const ApiException(
        statusCode: 500,
        message: 'Wipe operation failed',
      ));

      expect(
        () => service.wipeSelfData(),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
