import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/models/privacy_models.dart';
import 'package:myoffgridai_client/core/services/privacy_service.dart';
import 'package:myoffgridai_client/features/privacy/privacy_screen.dart';

class MockPrivacyService extends Mock implements PrivacyService {}

void main() {
  late MockPrivacyService mockService;

  setUp(() {
    mockService = MockPrivacyService();
  });

  Widget buildScreen({
    FortressStatusModel? fortress,
    SovereigntyReportModel? report,
    List<AuditLogModel>? logs,
  }) {
    return ProviderScope(
      overrides: [
        fortressStatusProvider.overrideWith((ref) =>
            fortress ??
            const FortressStatusModel(enabled: true, verified: true)),
        privacyServiceProvider.overrideWithValue(mockService),
      ],
      child: const MaterialApp(home: PrivacyScreen()),
    );
  }

  group('PrivacyScreen tabs', () {
    testWidgets('shows tab bar with three tabs', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Fortress'), findsOneWidget);
      expect(find.text('Sovereignty'), findsOneWidget);
      expect(find.text('Audit Log'), findsOneWidget);
    });

    testWidgets('shows app bar title', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Privacy Fortress'), findsOneWidget);
    });
  });

  group('Fortress tab', () {
    testWidgets('shows fortress enabled state', (tester) async {
      await tester.pumpWidget(buildScreen(
        fortress: const FortressStatusModel(enabled: true, verified: true),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Fortress ENABLED'), findsOneWidget);
      expect(find.byIcon(Icons.shield), findsOneWidget);
    });

    testWidgets('shows fortress disabled state', (tester) async {
      await tester.pumpWidget(buildScreen(
        fortress: const FortressStatusModel(enabled: false, verified: false),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Fortress DISABLED'), findsOneWidget);
      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
    });

    testWidgets('shows verified chip when verified', (tester) async {
      await tester.pumpWidget(buildScreen(
        fortress: const FortressStatusModel(enabled: true, verified: true),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Verified'), findsOneWidget);
      expect(find.byIcon(Icons.verified), findsOneWidget);
    });

    testWidgets('hides verified chip when not verified', (tester) async {
      await tester.pumpWidget(buildScreen(
        fortress: const FortressStatusModel(enabled: true, verified: false),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Verified'), findsNothing);
    });

    testWidgets('shows enabled by username', (tester) async {
      await tester.pumpWidget(buildScreen(
        fortress: const FortressStatusModel(
          enabled: true,
          verified: true,
          enabledByUsername: 'adam',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Enabled by: adam'), findsOneWidget);
    });

    testWidgets('shows Disable button when enabled', (tester) async {
      await tester.pumpWidget(buildScreen(
        fortress: const FortressStatusModel(enabled: true, verified: true),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Disable'), findsOneWidget);
      expect(find.byIcon(Icons.lock_open), findsOneWidget);
    });

    testWidgets('shows Enable button when disabled', (tester) async {
      await tester.pumpWidget(buildScreen(
        fortress: const FortressStatusModel(enabled: false, verified: false),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Enable'), findsOneWidget);
      expect(find.byIcon(Icons.lock), findsOneWidget);
    });

    testWidgets('shows wipe data option', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Wipe My Data'), findsOneWidget);
    });

    testWidgets('toggle fortress shows confirmation dialog', (tester) async {
      await tester.pumpWidget(buildScreen(
        fortress: const FortressStatusModel(enabled: true, verified: true),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Disable'));
      await tester.pumpAndSettle();

      expect(find.text('Disable Fortress?'), findsOneWidget);
      expect(
          find.text(
              'Disabling the fortress will allow outbound network traffic.'),
          findsOneWidget);
    });

    testWidgets('enable fortress shows confirmation dialog', (tester) async {
      await tester.pumpWidget(buildScreen(
        fortress: const FortressStatusModel(enabled: false, verified: false),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Enable'));
      await tester.pumpAndSettle();

      expect(find.text('Enable Fortress?'), findsOneWidget);
      expect(
          find.text(
              'Enabling the fortress will block all outbound network traffic.'),
          findsOneWidget);
    });

    testWidgets('calls disableFortress on confirm', (tester) async {
      when(() => mockService.disableFortress()).thenAnswer((_) async {});

      await tester.pumpWidget(buildScreen(
        fortress: const FortressStatusModel(enabled: true, verified: true),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Disable'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      verify(() => mockService.disableFortress()).called(1);
    });

    testWidgets('calls enableFortress on confirm', (tester) async {
      when(() => mockService.enableFortress()).thenAnswer((_) async {});

      await tester.pumpWidget(buildScreen(
        fortress: const FortressStatusModel(enabled: false, verified: false),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Enable'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      verify(() => mockService.enableFortress()).called(1);
    });

    testWidgets('does not toggle on cancel', (tester) async {
      await tester.pumpWidget(buildScreen(
        fortress: const FortressStatusModel(enabled: true, verified: true),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Disable'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      verifyNever(() => mockService.disableFortress());
      verifyNever(() => mockService.enableFortress());
    });

    testWidgets('shows error on toggle failure', (tester) async {
      when(() => mockService.disableFortress()).thenThrow(
        const ApiException(statusCode: 500, message: 'Toggle failed'),
      );

      await tester.pumpWidget(buildScreen(
        fortress: const FortressStatusModel(enabled: true, verified: true),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Disable'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(find.text('Toggle failed'), findsOneWidget);
    });

    testWidgets('wipe data shows confirmation', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Wipe My Data'));
      await tester.pumpAndSettle();

      expect(find.text('Wipe All Data?'), findsOneWidget);
      expect(
          find.text(
              'This will permanently delete ALL of your data. This action cannot be undone.'),
          findsOneWidget);
    });

    testWidgets('calls wipeSelfData on confirm', (tester) async {
      when(() => mockService.wipeSelfData()).thenAnswer((_) async =>
          const WipeResultModel(stepsCompleted: 5, success: true));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Wipe My Data'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      verify(() => mockService.wipeSelfData()).called(1);
      expect(find.text('Data wiped successfully'), findsOneWidget);
    });

    testWidgets('shows error on wipe failure', (tester) async {
      when(() => mockService.wipeSelfData()).thenThrow(
        const ApiException(statusCode: 500, message: 'Wipe failed'),
      );

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Wipe My Data'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(find.text('Wipe failed'), findsOneWidget);
    });

    testWidgets('does not wipe on cancel', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Wipe My Data'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      verifyNever(() => mockService.wipeSelfData());
    });

    testWidgets('shows loading indicator while fortress loads',
        (tester) async {
      // Use a Completer so the provider stays in loading state
      final completer = Completer<FortressStatusModel>();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          fortressStatusProvider.overrideWith((ref) => completer.future),
          privacyServiceProvider.overrideWithValue(mockService),
        ],
        child: const MaterialApp(home: PrivacyScreen()),
      ));
      await tester.pump();

      // Should show loading state (CircularProgressIndicator from LoadingIndicator)
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('shows error view when fortress status fails',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          fortressStatusProvider.overrideWith((ref) =>
              throw const ApiException(
                  statusCode: 500, message: 'Fortress error')),
          privacyServiceProvider.overrideWithValue(mockService),
        ],
        child: const MaterialApp(home: PrivacyScreen()),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Failed to load fortress status'), findsOneWidget);
      expect(find.text('Fortress error'), findsOneWidget);
    });

    testWidgets('shows generic error for non-API fortress error',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          fortressStatusProvider
              .overrideWith((ref) => throw Exception('Unknown')),
          privacyServiceProvider.overrideWithValue(mockService),
        ],
        child: const MaterialApp(home: PrivacyScreen()),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Failed to load fortress status'), findsOneWidget);
      expect(find.text('An unexpected error occurred.'), findsOneWidget);
    });
  });

  group('Sovereignty tab', () {
    testWidgets('shows sovereignty tab content with data inventory',
        (tester) async {
      when(() => mockService.getSovereigntyReport()).thenAnswer(
        (_) async => const SovereigntyReportModel(
          dataInventory: DataInventoryModel(
            conversationCount: 10,
            messageCount: 50,
            memoryCount: 5,
            knowledgeDocumentCount: 3,
            sensorCount: 2,
            insightCount: 7,
          ),
          encryptionStatus: 'ENCRYPTED',
          telemetryStatus: 'DISABLED',
          outboundTrafficVerification: 'BLOCKED',
        ),
      );

      await tester.pumpWidget(ProviderScope(
        overrides: [
          fortressStatusProvider.overrideWith((ref) =>
              const FortressStatusModel(enabled: true, verified: true)),
          privacyServiceProvider.overrideWithValue(mockService),
        ],
        child: const MaterialApp(home: PrivacyScreen()),
      ));
      await tester.pumpAndSettle();

      // Tap Sovereignty tab
      await tester.tap(find.text('Sovereignty'));
      await tester.pumpAndSettle();

      expect(find.text('Data Inventory'), findsOneWidget);
      expect(find.text('Conversations'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('Messages'), findsOneWidget);
      expect(find.text('50'), findsOneWidget);
      expect(find.text('Memories'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('Knowledge Docs'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Sensors'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Insights'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('shows encryption, telemetry, and outbound status cards',
        (tester) async {
      when(() => mockService.getSovereigntyReport()).thenAnswer(
        (_) async => const SovereigntyReportModel(
          encryptionStatus: 'ENCRYPTED',
          telemetryStatus: 'DISABLED',
          outboundTrafficVerification: 'BLOCKED',
        ),
      );

      await tester.pumpWidget(ProviderScope(
        overrides: [
          fortressStatusProvider.overrideWith((ref) =>
              const FortressStatusModel(enabled: true, verified: true)),
          privacyServiceProvider.overrideWithValue(mockService),
        ],
        child: const MaterialApp(home: PrivacyScreen()),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sovereignty'));
      await tester.pumpAndSettle();

      expect(find.text('Encryption'), findsOneWidget);
      expect(find.text('ENCRYPTED'), findsOneWidget);
      expect(find.text('Telemetry'), findsOneWidget);
      expect(find.text('DISABLED'), findsOneWidget);
      expect(find.text('Outbound Traffic'), findsOneWidget);
      expect(find.text('BLOCKED'), findsOneWidget);
    });

    testWidgets('shows error on sovereignty report failure',
        (tester) async {
      when(() => mockService.getSovereigntyReport()).thenThrow(
        const ApiException(
            statusCode: 500, message: 'Report load failed'),
      );

      await tester.pumpWidget(ProviderScope(
        overrides: [
          fortressStatusProvider.overrideWith((ref) =>
              const FortressStatusModel(enabled: true, verified: true)),
          privacyServiceProvider.overrideWithValue(mockService),
        ],
        child: const MaterialApp(home: PrivacyScreen()),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sovereignty'));
      await tester.pumpAndSettle();

      expect(
          find.text('Failed to load sovereignty report'), findsOneWidget);
      expect(find.text('Report load failed'), findsOneWidget);
    });

    testWidgets('shows generic error for non-API sovereignty error',
        (tester) async {
      when(() => mockService.getSovereigntyReport())
          .thenThrow(Exception('Unknown'));

      await tester.pumpWidget(ProviderScope(
        overrides: [
          fortressStatusProvider.overrideWith((ref) =>
              const FortressStatusModel(enabled: true, verified: true)),
          privacyServiceProvider.overrideWithValue(mockService),
        ],
        child: const MaterialApp(home: PrivacyScreen()),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sovereignty'));
      await tester.pumpAndSettle();

      expect(
          find.text('Failed to load sovereignty report'), findsOneWidget);
      expect(find.text('An unexpected error occurred.'), findsOneWidget);
    });
  });

  group('Audit Log tab', () {
    testWidgets('shows audit logs with SUCCESS outcome', (tester) async {
      when(() => mockService.getAuditLogs(
            outcome: any(named: 'outcome'),
            page: any(named: 'page'),
            size: any(named: 'size'),
          )).thenAnswer((_) async => [
            const AuditLogModel(
              id: 'a1',
              action: 'LOGIN',
              outcome: 'SUCCESS',
              username: 'adam',
              httpMethod: 'POST',
              requestPath: '/api/auth/login',
              durationMs: 50,
            ),
          ]);

      await tester.pumpWidget(ProviderScope(
        overrides: [
          fortressStatusProvider.overrideWith((ref) =>
              const FortressStatusModel(enabled: true, verified: true)),
          privacyServiceProvider.overrideWithValue(mockService),
        ],
        child: const MaterialApp(home: PrivacyScreen()),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Audit Log'));
      await tester.pumpAndSettle();

      expect(find.text('POST /api/auth/login'), findsOneWidget);
      expect(find.text('adam | 50ms'), findsOneWidget);
      expect(find.text('SUCCESS'), findsOneWidget);
    });

    testWidgets('shows FAILURE and DENIED outcomes', (tester) async {
      when(() => mockService.getAuditLogs(
            outcome: any(named: 'outcome'),
            page: any(named: 'page'),
            size: any(named: 'size'),
          )).thenAnswer((_) async => [
            const AuditLogModel(
              id: 'a2',
              action: 'ACCESS',
              outcome: 'FAILURE',
              username: 'bob',
              durationMs: 10,
            ),
            const AuditLogModel(
              id: 'a3',
              action: 'ADMIN',
              outcome: 'DENIED',
              username: 'eve',
              durationMs: 5,
            ),
          ]);

      await tester.pumpWidget(ProviderScope(
        overrides: [
          fortressStatusProvider.overrideWith((ref) =>
              const FortressStatusModel(enabled: true, verified: true)),
          privacyServiceProvider.overrideWithValue(mockService),
        ],
        child: const MaterialApp(home: PrivacyScreen()),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Audit Log'));
      await tester.pumpAndSettle();

      expect(find.text('FAILURE'), findsOneWidget);
      expect(find.text('DENIED'), findsOneWidget);
    });

    testWidgets('shows unknown outcome icon', (tester) async {
      when(() => mockService.getAuditLogs(
            outcome: any(named: 'outcome'),
            page: any(named: 'page'),
            size: any(named: 'size'),
          )).thenAnswer((_) async => [
            const AuditLogModel(
              id: 'a4',
              action: 'UNKNOWN_ACTION',
              outcome: 'OTHER',
              username: 'test',
            ),
          ]);

      await tester.pumpWidget(ProviderScope(
        overrides: [
          fortressStatusProvider.overrideWith((ref) =>
              const FortressStatusModel(enabled: true, verified: true)),
          privacyServiceProvider.overrideWithValue(mockService),
        ],
        child: const MaterialApp(home: PrivacyScreen()),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Audit Log'));
      await tester.pumpAndSettle();

      expect(find.text('OTHER'), findsOneWidget);
      // Unknown outcome uses help icon
      expect(find.byIcon(Icons.help), findsOneWidget);
    });

    testWidgets('shows empty audit log message', (tester) async {
      when(() => mockService.getAuditLogs(
            outcome: any(named: 'outcome'),
            page: any(named: 'page'),
            size: any(named: 'size'),
          )).thenAnswer((_) async => <AuditLogModel>[]);

      await tester.pumpWidget(ProviderScope(
        overrides: [
          fortressStatusProvider.overrideWith((ref) =>
              const FortressStatusModel(enabled: true, verified: true)),
          privacyServiceProvider.overrideWithValue(mockService),
        ],
        child: const MaterialApp(home: PrivacyScreen()),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Audit Log'));
      await tester.pumpAndSettle();

      expect(find.text('No audit logs'), findsOneWidget);
    });

    testWidgets('shows error on audit log failure', (tester) async {
      when(() => mockService.getAuditLogs(
            outcome: any(named: 'outcome'),
            page: any(named: 'page'),
            size: any(named: 'size'),
          )).thenThrow(
        const ApiException(statusCode: 500, message: 'Audit error'),
      );

      await tester.pumpWidget(ProviderScope(
        overrides: [
          fortressStatusProvider.overrideWith((ref) =>
              const FortressStatusModel(enabled: true, verified: true)),
          privacyServiceProvider.overrideWithValue(mockService),
        ],
        child: const MaterialApp(home: PrivacyScreen()),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Audit Log'));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load audit logs'), findsOneWidget);
      expect(find.text('Audit error'), findsOneWidget);
    });

    testWidgets('shows generic error for non-API audit log error',
        (tester) async {
      when(() => mockService.getAuditLogs(
            outcome: any(named: 'outcome'),
            page: any(named: 'page'),
            size: any(named: 'size'),
          )).thenThrow(Exception('Random'));

      await tester.pumpWidget(ProviderScope(
        overrides: [
          fortressStatusProvider.overrideWith((ref) =>
              const FortressStatusModel(enabled: true, verified: true)),
          privacyServiceProvider.overrideWithValue(mockService),
        ],
        child: const MaterialApp(home: PrivacyScreen()),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Audit Log'));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load audit logs'), findsOneWidget);
      expect(find.text('An unexpected error occurred.'), findsOneWidget);
    });

    testWidgets('shows action as fallback when requestPath is null',
        (tester) async {
      when(() => mockService.getAuditLogs(
            outcome: any(named: 'outcome'),
            page: any(named: 'page'),
            size: any(named: 'size'),
          )).thenAnswer((_) async => [
            const AuditLogModel(
              id: 'a5',
              action: 'MANUAL_ACTION',
              outcome: 'SUCCESS',
              username: 'admin',
              durationMs: 20,
            ),
          ]);

      await tester.pumpWidget(ProviderScope(
        overrides: [
          fortressStatusProvider.overrideWith((ref) =>
              const FortressStatusModel(enabled: true, verified: true)),
          privacyServiceProvider.overrideWithValue(mockService),
        ],
        child: const MaterialApp(home: PrivacyScreen()),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Audit Log'));
      await tester.pumpAndSettle();

      // When requestPath is null, action is shown instead
      expect(find.text(' MANUAL_ACTION'), findsOneWidget);
    });
  });

  group('Retry callbacks', () {
    testWidgets('fortress error retry button triggers reload', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          fortressStatusProvider.overrideWith((ref) =>
              throw const ApiException(
                  statusCode: 500, message: 'Fortress error')),
          privacyServiceProvider.overrideWithValue(mockService),
        ],
        child: const MaterialApp(home: PrivacyScreen()),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should still show error (provider re-throws)
      expect(find.text('Failed to load fortress status'), findsOneWidget);
    });

    testWidgets('sovereignty error retry button triggers reload',
        (tester) async {
      when(() => mockService.getSovereigntyReport()).thenThrow(
        const ApiException(
            statusCode: 500, message: 'Sovereignty error'),
      );

      await tester.pumpWidget(ProviderScope(
        overrides: [
          fortressStatusProvider.overrideWith((ref) =>
              const FortressStatusModel(enabled: true, verified: true)),
          privacyServiceProvider.overrideWithValue(mockService),
        ],
        child: const MaterialApp(home: PrivacyScreen()),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sovereignty'));
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // Should still show error (service keeps throwing)
      expect(
          find.text('Failed to load sovereignty report'), findsOneWidget);
    });

    testWidgets('audit log error retry button triggers reload',
        (tester) async {
      when(() => mockService.getAuditLogs(
            outcome: any(named: 'outcome'),
            page: any(named: 'page'),
            size: any(named: 'size'),
          )).thenThrow(
        const ApiException(statusCode: 500, message: 'Audit error'),
      );

      await tester.pumpWidget(ProviderScope(
        overrides: [
          fortressStatusProvider.overrideWith((ref) =>
              const FortressStatusModel(enabled: true, verified: true)),
          privacyServiceProvider.overrideWithValue(mockService),
        ],
        child: const MaterialApp(home: PrivacyScreen()),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Audit Log'));
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // Should still show error (service keeps throwing)
      expect(find.text('Failed to load audit logs'), findsOneWidget);
    });
  });
}
