import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/core/models/privacy_models.dart';

void main() {
  group('FortressStatusModel', () {
    test('parses from JSON with all fields', () {
      final json = {
        'enabled': true,
        'enabledAt': '2026-03-14T10:00:00Z',
        'enabledByUsername': 'adam',
        'verified': true,
      };

      final model = FortressStatusModel.fromJson(json);

      expect(model.enabled, isTrue);
      expect(model.enabledAt, '2026-03-14T10:00:00Z');
      expect(model.enabledByUsername, 'adam');
      expect(model.verified, isTrue);
    });

    test('handles missing fields with defaults', () {
      final json = <String, dynamic>{};

      final model = FortressStatusModel.fromJson(json);

      expect(model.enabled, isFalse);
      expect(model.verified, isFalse);
    });
  });

  group('DataInventoryModel', () {
    test('parses from JSON', () {
      final json = {
        'conversationCount': 10,
        'messageCount': 50,
        'memoryCount': 5,
        'knowledgeDocumentCount': 3,
        'sensorCount': 2,
        'insightCount': 7,
      };

      final model = DataInventoryModel.fromJson(json);

      expect(model.conversationCount, 10);
      expect(model.messageCount, 50);
      expect(model.memoryCount, 5);
      expect(model.knowledgeDocumentCount, 3);
      expect(model.sensorCount, 2);
      expect(model.insightCount, 7);
    });

    test('handles missing fields with zero defaults', () {
      final json = <String, dynamic>{};

      final model = DataInventoryModel.fromJson(json);

      expect(model.conversationCount, 0);
      expect(model.messageCount, 0);
    });
  });

  group('AuditSummaryModel', () {
    test('parses from JSON', () {
      final json = {
        'successCount': 100,
        'failureCount': 5,
        'deniedCount': 2,
        'windowStart': '2026-03-01T00:00:00Z',
        'windowEnd': '2026-03-14T00:00:00Z',
      };

      final model = AuditSummaryModel.fromJson(json);

      expect(model.successCount, 100);
      expect(model.failureCount, 5);
      expect(model.deniedCount, 2);
    });
  });

  group('SovereigntyReportModel', () {
    test('parses from JSON with nested objects', () {
      final json = {
        'generatedAt': '2026-03-14T10:00:00Z',
        'fortressStatus': {
          'enabled': true,
          'verified': true,
        },
        'outboundTrafficVerification': 'NONE_DETECTED',
        'dataInventory': {
          'conversationCount': 5,
          'messageCount': 20,
          'memoryCount': 3,
          'knowledgeDocumentCount': 1,
          'sensorCount': 2,
          'insightCount': 4,
        },
        'auditSummary': {
          'successCount': 50,
          'failureCount': 1,
          'deniedCount': 0,
        },
        'encryptionStatus': 'AES-256',
        'telemetryStatus': 'DISABLED',
      };

      final model = SovereigntyReportModel.fromJson(json);

      expect(model.fortressStatus?.enabled, isTrue);
      expect(model.dataInventory?.conversationCount, 5);
      expect(model.auditSummary?.successCount, 50);
      expect(model.encryptionStatus, 'AES-256');
      expect(model.telemetryStatus, 'DISABLED');
    });

    test('handles all null nested objects', () {
      final json = <String, dynamic>{};

      final model = SovereigntyReportModel.fromJson(json);

      expect(model.fortressStatus, isNull);
      expect(model.dataInventory, isNull);
      expect(model.auditSummary, isNull);
    });
  });

  group('AuditLogModel', () {
    test('parses from JSON with all fields', () {
      final json = {
        'id': 'log-1',
        'userId': 'user-1',
        'username': 'adam',
        'action': 'LOGIN',
        'resourceType': 'AUTH',
        'resourceId': null,
        'httpMethod': 'POST',
        'requestPath': '/api/auth/login',
        'outcome': 'SUCCESS',
        'responseStatus': 200,
        'durationMs': 45,
        'timestamp': '2026-03-14T10:00:00Z',
      };

      final model = AuditLogModel.fromJson(json);

      expect(model.id, 'log-1');
      expect(model.username, 'adam');
      expect(model.action, 'LOGIN');
      expect(model.httpMethod, 'POST');
      expect(model.outcome, 'SUCCESS');
      expect(model.responseStatus, 200);
      expect(model.durationMs, 45);
    });
  });

  group('WipeResultModel', () {
    test('parses from JSON', () {
      final json = {
        'targetUserId': 'user-1',
        'stepsCompleted': 5,
        'completedAt': '2026-03-14T10:00:00Z',
        'success': true,
      };

      final model = WipeResultModel.fromJson(json);

      expect(model.targetUserId, 'user-1');
      expect(model.stepsCompleted, 5);
      expect(model.completedAt, '2026-03-14T10:00:00Z');
      expect(model.success, isTrue);
    });

    test('handles missing fields with defaults', () {
      final json = <String, dynamic>{};

      final model = WipeResultModel.fromJson(json);

      expect(model.targetUserId, isNull);
      expect(model.stepsCompleted, 0);
      expect(model.completedAt, isNull);
      expect(model.success, isFalse);
    });
  });

  group('AuditOutcome', () {
    test('all contains expected outcomes', () {
      expect(AuditOutcome.all, contains('SUCCESS'));
      expect(AuditOutcome.all, contains('FAILURE'));
      expect(AuditOutcome.all, contains('DENIED'));
      expect(AuditOutcome.all.length, 3);
    });
  });
}
