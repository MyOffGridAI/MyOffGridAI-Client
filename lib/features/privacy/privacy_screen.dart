import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/models/privacy_models.dart';
import 'package:myoffgridai_client/core/services/privacy_service.dart';
import 'package:myoffgridai_client/shared/widgets/confirmation_dialog.dart';
import 'package:myoffgridai_client/shared/widgets/error_view.dart';
import 'package:myoffgridai_client/shared/widgets/loading_indicator.dart';

/// Provider for the sovereignty report.
final _sovereigntyProvider =
    FutureProvider.autoDispose<SovereigntyReportModel>((ref) async {
  final service = ref.watch(privacyServiceProvider);
  return service.getSovereigntyReport();
});

/// Provider for audit logs.
final _auditLogsProvider =
    FutureProvider.autoDispose<List<AuditLogModel>>((ref) async {
  final service = ref.watch(privacyServiceProvider);
  return service.getAuditLogs();
});

/// Privacy Fortress screen with sovereignty report and audit log.
///
/// Uses a [TabBar] with three tabs: Fortress status and toggle,
/// Sovereignty report showing data inventory, and Audit logs.
class PrivacyScreen extends ConsumerStatefulWidget {
  /// Creates a [PrivacyScreen].
  const PrivacyScreen({super.key});

  @override
  ConsumerState<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends ConsumerState<PrivacyScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Fortress'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Fortress'),
            Tab(text: 'Sovereignty'),
            Tab(text: 'Audit Log'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _FortressTab(),
          _SovereigntyTab(),
          _AuditLogTab(),
        ],
      ),
    );
  }
}

class _FortressTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fortressAsync = ref.watch(fortressStatusProvider);

    return fortressAsync.when(
      loading: () => const LoadingIndicator(),
      error: (error, _) => ErrorView(
        title: 'Failed to load fortress status',
        message: error is ApiException
            ? error.message
            : 'An unexpected error occurred.',
        onRetry: () => ref.invalidate(fortressStatusProvider),
      ),
      data: (status) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      status.enabled ? Icons.shield : Icons.shield_outlined,
                      size: 64,
                      color: status.enabled ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      status.enabled
                          ? 'Fortress ENABLED'
                          : 'Fortress DISABLED',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color:
                                status.enabled ? Colors.green : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (status.verified)
                      const Chip(
                        avatar: Icon(Icons.verified, size: 16),
                        label: Text('Verified'),
                      ),
                    if (status.enabledByUsername != null) ...[
                      const SizedBox(height: 8),
                      Text('Enabled by: ${status.enabledByUsername}'),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () =>
                          _toggleFortress(context, ref, status.enabled),
                      icon: Icon(status.enabled
                          ? Icons.lock_open
                          : Icons.lock),
                      label:
                          Text(status.enabled ? 'Disable' : 'Enable'),
                      style: status.enabled
                          ? ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Wipe My Data'),
                subtitle: const Text(
                    'Permanently delete all your data from this device'),
                onTap: () => _wipeSelfData(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleFortress(
    BuildContext context,
    WidgetRef ref,
    bool currentlyEnabled,
  ) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title:
          currentlyEnabled ? 'Disable Fortress?' : 'Enable Fortress?',
      message: currentlyEnabled
          ? 'Disabling the fortress will allow outbound network traffic.'
          : 'Enabling the fortress will block all outbound network traffic.',
      isDestructive: currentlyEnabled,
    );
    if (confirmed != true) return;

    try {
      final service = ref.read(privacyServiceProvider);
      if (currentlyEnabled) {
        await service.disableFortress();
      } else {
        await service.enableFortress();
      }
      ref.invalidate(fortressStatusProvider);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  Future<void> _wipeSelfData(BuildContext context, WidgetRef ref) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Wipe All Data?',
      message:
          'This will permanently delete ALL of your data. This action cannot be undone.',
      isDestructive: true,
    );
    if (confirmed != true) return;

    try {
      final service = ref.read(privacyServiceProvider);
      await service.wipeSelfData();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data wiped successfully')),
        );
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }
}

class _SovereigntyTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(_sovereigntyProvider);

    return reportAsync.when(
      loading: () => const LoadingIndicator(),
      error: (error, _) => ErrorView(
        title: 'Failed to load sovereignty report',
        message: error is ApiException
            ? error.message
            : 'An unexpected error occurred.',
        onRetry: () => ref.invalidate(_sovereigntyProvider),
      ),
      data: (report) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (report.dataInventory != null) ...[
              Text('Data Inventory',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _dataRow('Conversations',
                          '${report.dataInventory!.conversationCount}'),
                      _dataRow('Messages',
                          '${report.dataInventory!.messageCount}'),
                      _dataRow('Memories',
                          '${report.dataInventory!.memoryCount}'),
                      _dataRow('Knowledge Docs',
                          '${report.dataInventory!.knowledgeDocumentCount}'),
                      _dataRow('Sensors',
                          '${report.dataInventory!.sensorCount}'),
                      _dataRow('Insights',
                          '${report.dataInventory!.insightCount}'),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (report.encryptionStatus != null)
              _statusCard(context, 'Encryption',
                  report.encryptionStatus!, Icons.lock),
            if (report.telemetryStatus != null)
              _statusCard(context, 'Telemetry',
                  report.telemetryStatus!, Icons.analytics),
            if (report.outboundTrafficVerification != null)
              _statusCard(context, 'Outbound Traffic',
                  report.outboundTrafficVerification!, Icons.cloud_off),
          ],
        ),
      ),
    );
  }

  Widget _dataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _statusCard(
    BuildContext context,
    String label,
    String status,
    IconData icon,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: Text(status,
            style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _AuditLogTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(_auditLogsProvider);

    return logsAsync.when(
      loading: () => const LoadingIndicator(),
      error: (error, _) => ErrorView(
        title: 'Failed to load audit logs',
        message: error is ApiException
            ? error.message
            : 'An unexpected error occurred.',
        onRetry: () => ref.invalidate(_auditLogsProvider),
      ),
      data: (logs) {
        if (logs.isEmpty) {
          return const Center(child: Text('No audit logs'));
        }
        return ListView.builder(
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            return ListTile(
              dense: true,
              leading: Icon(
                _outcomeIcon(log.outcome),
                color: _outcomeColor(log.outcome),
                size: 18,
              ),
              title: Text(
                '${log.httpMethod ?? ''} ${log.requestPath ?? log.action}',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
              subtitle: Text(
                '${log.username ?? 'unknown'} | ${log.durationMs ?? 0}ms',
              ),
              trailing: Text(
                log.outcome,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _outcomeColor(log.outcome),
                ),
              ),
            );
          },
        );
      },
    );
  }

  IconData _outcomeIcon(String outcome) {
    switch (outcome) {
      case 'SUCCESS':
        return Icons.check_circle;
      case 'FAILURE':
        return Icons.error;
      case 'DENIED':
        return Icons.block;
      default:
        return Icons.help;
    }
  }

  Color _outcomeColor(String outcome) {
    switch (outcome) {
      case 'SUCCESS':
        return Colors.green;
      case 'FAILURE':
        return Colors.red;
      case 'DENIED':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
