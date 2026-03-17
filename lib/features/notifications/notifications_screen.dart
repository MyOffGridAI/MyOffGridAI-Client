import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/models/notification_model.dart';
import 'package:myoffgridai_client/core/services/mqtt_service.dart';
import 'package:myoffgridai_client/core/services/notification_service.dart';
import 'package:myoffgridai_client/shared/utils/date_formatter.dart';
import 'package:myoffgridai_client/shared/widgets/confirmation_dialog.dart';
import 'package:myoffgridai_client/shared/widgets/empty_state_view.dart';
import 'package:myoffgridai_client/shared/widgets/error_view.dart';
import 'package:myoffgridai_client/shared/widgets/loading_indicator.dart';

/// Displays the user's notification history with unread count badge,
/// mark-as-read and delete actions, and MQTT connection status indicator.
///
/// Notifications are fetched from the server REST API (persisted history)
/// and arrive in real time via the [MqttService] MQTT connection.
class NotificationsScreen extends ConsumerWidget {
  /// Creates a [NotificationsScreen].
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final mqttState = ref.watch(mqttServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          notificationsAsync.maybeWhen(
            data: (notifications) {
              final unread = notifications.where((n) => !n.isRead).length;
              if (unread == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => _markAllRead(context, ref),
                child: const Text('Mark all read'),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          _MqttStatusChip(state: mqttState),
          Expanded(
            child: notificationsAsync.when(
              loading: () => const LoadingIndicator(),
              error: (e, _) => ErrorView(
                title: 'Failed to load notifications',
                message: e is ApiException ? e.message : e.toString(),
                onRetry: () => ref.invalidate(notificationsProvider),
              ),
              data: (notifications) {
                if (notifications.isEmpty) {
                  return const EmptyStateView(
                    icon: Icons.notifications_off_outlined,
                    title: 'No notifications yet',
                    subtitle:
                        'Alerts and updates from your AI assistant will appear here.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(notificationsProvider);
                  },
                  child: ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return _NotificationTile(
                        notification: notification,
                        onTap: () => _showDetail(context, ref, notification),
                        onDismissed: () =>
                            _deleteNotification(context, ref, notification.id),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markAllRead(BuildContext context, WidgetRef ref) async {
    try {
      final service = ref.read(notificationServiceProvider);
      await service.markAllAsRead();
      ref.invalidate(notificationsProvider);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  Future<void> _deleteNotification(
    BuildContext context,
    WidgetRef ref,
    String notificationId,
  ) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Notification',
      message: 'This notification will be permanently deleted.',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (confirmed == true) {
      try {
        final service = ref.read(notificationServiceProvider);
        await service.deleteNotification(notificationId);
        ref.invalidate(notificationsProvider);
      } on ApiException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message)),
          );
        }
      }
    }
  }

  void _showDetail(
    BuildContext context,
    WidgetRef ref,
    NotificationModel notification,
  ) {
    // Mark as read if unread
    if (!notification.isRead) {
      final service = ref.read(notificationServiceProvider);
      service.markAsRead(notification.id).then((_) {
        ref.invalidate(notificationsProvider);
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _NotificationDetailSheet(
        notification: notification,
      ),
    );
  }
}

/// MQTT connection status chip displayed below the AppBar.
class _MqttStatusChip extends StatelessWidget {
  final MqttState state;

  const _MqttStatusChip({required this.state});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;

    switch (state.connectionState) {
      case MqttConnectionStatus.connected:
        color = Colors.green;
        label = 'Connected';
      case MqttConnectionStatus.connecting:
        color = Colors.orange;
        label = 'Connecting...';
      case MqttConnectionStatus.error:
        color = Colors.red;
        label = 'Error';
      case MqttConnectionStatus.disconnected:
        color = Colors.red;
        label = 'Disconnected';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'MQTT: $label',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCritical = notification.severity == NotificationSeverity.critical;
    final borderColor = _severityBorderColor(notification.severity);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: Icon(Icons.delete, color: colorScheme.onError),
      ),
      onDismissed: (_) => onDismissed(),
      child: Container(
        decoration: BoxDecoration(
          color: isCritical && !notification.isRead
              ? Colors.red.withValues(alpha: 0.06)
              : null,
          border: Border(
            left: BorderSide(color: borderColor, width: 4),
          ),
        ),
        child: ListTile(
          leading: _severityIcon(notification.severity),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight:
                  notification.isRead ? FontWeight.normal : FontWeight.bold,
              color: isCritical ? Colors.red : null,
            ),
          ),
          subtitle: Text(
            notification.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (notification.createdAt != null)
                Text(
                  DateFormatter.formatRelative(
                    DateTime.parse(notification.createdAt!),
                  ),
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              if (!notification.isRead)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  /// Returns the left border color for the given [severity].
  Color _severityBorderColor(String severity) {
    switch (severity) {
      case NotificationSeverity.critical:
        return Colors.red;
      case NotificationSeverity.warning:
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  Widget _severityIcon(String severity) {
    switch (severity) {
      case NotificationSeverity.critical:
        return const Icon(Icons.error, color: Colors.red);
      case NotificationSeverity.warning:
        return const Icon(Icons.warning, color: Colors.orange);
      default:
        return const Icon(Icons.info_outline, color: Colors.blue);
    }
  }
}

class _NotificationDetailSheet extends StatelessWidget {
  final NotificationModel notification;

  const _NotificationDetailSheet({required this.notification});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      maxChildSize: 0.8,
      minChildSize: 0.3,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                notification.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  Chip(
                    label: Text(notification.type),
                    visualDensity: VisualDensity.compact,
                  ),
                  Chip(
                    label: Text(notification.severity),
                    backgroundColor: _severityColor(notification.severity),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                notification.body,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (notification.createdAt != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Created: ${DateFormatter.formatFull(DateTime.parse(notification.createdAt!))}',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
              if (notification.readAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Read: ${DateFormatter.formatFull(DateTime.parse(notification.readAt!))}',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
              if (notification.metadata != null) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Metadata',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  notification.metadata!,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case NotificationSeverity.critical:
        return Colors.red.shade100;
      case NotificationSeverity.warning:
        return Colors.orange.shade100;
      default:
        return Colors.blue.shade100;
    }
  }
}
