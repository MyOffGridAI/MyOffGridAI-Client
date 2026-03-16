import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/api/providers.dart';
import 'package:myoffgridai_client/core/services/system_service.dart';
import 'package:myoffgridai_client/shared/utils/size_formatter.dart';
import 'package:myoffgridai_client/shared/widgets/error_view.dart';
import 'package:myoffgridai_client/shared/widgets/loading_indicator.dart';

/// System health and status screen.
///
/// Displays system status (initialized, fortress, version), inference provider
/// health (supports both Ollama and LM Studio), and a list of available models
/// with their sizes.
class SystemScreen extends ConsumerWidget {
  /// Creates a [SystemScreen].
  const SystemScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(systemStatusDetailProvider);
    final healthAsync = ref.watch(modelHealthProvider);
    final modelsAsync = ref.watch(ollamaModelsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('System'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(systemStatusDetailProvider);
              ref.invalidate(modelHealthProvider);
              ref.invalidate(ollamaModelsProvider);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('System Status',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            statusAsync.when(
              loading: () => const LoadingIndicator(),
              error: (error, _) => ErrorView(
                title: 'Failed to load status',
                message: error is ApiException
                    ? error.message
                    : 'An unexpected error occurred.',
                onRetry: () =>
                    ref.invalidate(systemStatusDetailProvider),
              ),
              data: (status) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _statusRow(
                        'Initialized',
                        status.initialized,
                      ),
                      _statusRow(
                        'Fortress',
                        status.fortressEnabled,
                      ),
                      _statusRow(
                        'WiFi',
                        status.wifiConfigured,
                      ),
                      if (status.instanceName != null)
                        _infoRow('Instance', status.instanceName!),
                      if (status.serverVersion != null)
                        _infoRow('Version', status.serverVersion!),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Inference Provider',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            healthAsync.when(
              loading: () => const LoadingIndicator(),
              error: (_, __) => const Card(
                child: ListTile(
                  leading: Icon(Icons.error, color: Colors.red),
                  title: Text('Inference provider unavailable'),
                ),
              ),
              data: (health) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 12,
                            color: health.available
                                ? Colors.green
                                : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(health.available
                              ? 'Available'
                              : 'Unavailable'),
                          const Spacer(),
                          _ProviderChip(modelName: health.activeModel),
                        ],
                      ),
                      if (health.activeModel != null)
                        _infoRow('Active Model', health.activeModel!),
                      if (health.embedModelName != null)
                        _infoRow(
                            'Embed Model', health.embedModelName!),
                      if (health.responseTimeMs != null)
                        _infoRow('Response Time',
                            '${health.responseTimeMs}ms'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Models',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            modelsAsync.when(
              loading: () => const LoadingIndicator(),
              error: (_, __) =>
                  const Center(child: Text('Failed to load models')),
              data: (models) {
                if (models.isEmpty) {
                  return const Card(
                    child: ListTile(
                      leading: Icon(Icons.info),
                      title: Text('No models installed'),
                    ),
                  );
                }
                return Column(
                  children: models
                      .map((m) => Card(
                            child: ListTile(
                              leading: const Icon(Icons.smart_toy),
                              title: Text(m.name),
                              subtitle: Text(SizeFormatter.formatBytes(m.size)),
                            ),
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusRow(String label, bool active) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Icon(
            active ? Icons.check_circle : Icons.cancel,
            color: active ? Colors.green : Colors.red,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// A chip showing the inference provider type based on model name heuristics.
///
/// If the model name contains a GGUF identifier or slash (typical of LM Studio
/// HuggingFace model paths), shows "LM Studio". Otherwise shows "Ollama".
class _ProviderChip extends StatelessWidget {
  final String? modelName;

  const _ProviderChip({this.modelName});

  @override
  Widget build(BuildContext context) {
    final isLmStudio = modelName != null &&
        (modelName!.contains('/') || modelName!.contains('GGUF'));
    final label = isLmStudio ? 'LM Studio' : 'Ollama';
    final color = isLmStudio ? Colors.blue : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
