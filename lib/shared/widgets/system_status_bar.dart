import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/providers.dart';
import 'package:myoffgridai_client/core/models/system_models.dart';
import 'package:myoffgridai_client/core/services/system_service.dart';
import 'package:myoffgridai_client/shared/widgets/notification_badge.dart';

/// Compact bar displayed below the app bar showing Ollama status and notifications.
///
/// Shows a green/red status dot for Ollama availability, a dropdown of
/// available models (visual only), and the unread notification count.
/// Tapping the notification count navigates to the Insights screen.
class SystemStatusBar extends ConsumerWidget {
  /// Creates a [SystemStatusBar].
  const SystemStatusBar({super.key});

  String _formatSize(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(modelHealthProvider);
    final unreadAsync = ref.watch(unreadCountProvider);
    final modelsAsync = ref.watch(ollamaModelsProvider);
    final aiSettingsAsync = ref.watch(aiSettingsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          healthAsync.when(
            data: (health) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  size: 10,
                  color: health.available ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 6),
                PopupMenuButton<String>(
                  tooltip: 'Available models',
                  offset: const Offset(0, 30),
                  onSelected: (model) async {
                    try {
                      final currentSettings =
                          aiSettingsAsync.valueOrNull;
                      final service = ref.read(systemServiceProvider);
                      await service.updateAiSettings(
                        AiSettingsModel(
                          modelName: model,
                          temperature:
                              currentSettings?.temperature ?? 0.7,
                          similarityThreshold:
                              currentSettings?.similarityThreshold ??
                                  0.45,
                          memoryTopK:
                              currentSettings?.memoryTopK ?? 5,
                          ragMaxContextTokens:
                              currentSettings?.ragMaxContextTokens ??
                                  2048,
                        ),
                      );
                      ref.invalidate(aiSettingsProvider);
                      ref.invalidate(modelHealthProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Switched to $model'),
                            duration: AppConstants.snackBarDuration,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Failed to switch model'),
                            duration: AppConstants.snackBarDuration,
                          ),
                        );
                      }
                    }
                  },
                  itemBuilder: (context) {
                    final models = modelsAsync.valueOrNull ?? [];
                    if (models.isEmpty) {
                      return [
                        const PopupMenuItem<String>(
                          enabled: false,
                          child: Text('No models available'),
                        ),
                      ];
                    }
                    final activeModel =
                        aiSettingsAsync.valueOrNull?.modelName ??
                            health.activeModel;
                    return models.map((model) {
                      final isActive = model.name == activeModel;
                      return PopupMenuItem<String>(
                        value: model.name,
                        child: Row(
                          children: [
                            if (isActive)
                              const Icon(Icons.check, size: 16)
                            else
                              const SizedBox(width: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                model.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatSize(model.size),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                            ),
                          ],
                        ),
                      );
                    }).toList();
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        health.activeModel ?? 'No model',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.arrow_drop_down,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            loading: () => const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 1),
            ),
            error: (_, __) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.circle, size: 10, color: Colors.red),
                const SizedBox(width: 6),
                Text(
                  'Offline',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => context.go(AppConstants.routeInsights),
            child: unreadAsync.when(
              data: (count) => NotificationBadge(
                count: count,
                child: const Icon(Icons.notifications_outlined, size: 20),
              ),
              loading: () => const Icon(Icons.notifications_outlined, size: 20),
              error: (_, __) =>
                  const Icon(Icons.notifications_outlined, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
