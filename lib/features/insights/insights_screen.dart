import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/models/insight_model.dart';
import 'package:myoffgridai_client/core/models/notification_model.dart';
import 'package:myoffgridai_client/core/services/insight_service.dart';
import 'package:myoffgridai_client/core/services/notification_service.dart';
import 'package:myoffgridai_client/shared/widgets/empty_state_view.dart';
import 'package:myoffgridai_client/shared/widgets/error_view.dart';
import 'package:myoffgridai_client/shared/widgets/loading_indicator.dart';

/// Displays proactive insights and notifications.
///
/// Uses a [TabBar] to switch between AI-generated insights and system
/// notifications. Insights can be marked as read or dismissed.
class InsightsScreen extends ConsumerStatefulWidget {
  /// Creates an [InsightsScreen].
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        title: const Text('Insights'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Insights'),
            Tab(text: 'Notifications'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Generate Insights',
            onPressed: _generateInsights,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _InsightsTab(),
          _NotificationsTab(),
        ],
      ),
    );
  }

  Future<void> _generateInsights() async {
    try {
      final service = ref.read(insightServiceProvider);
      await service.generateInsights();
      ref.invalidate(insightsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Insights generated')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }
}

class _InsightsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(insightsProvider);

    return insightsAsync.when(
      loading: () => const LoadingIndicator(),
      error: (error, _) => ErrorView(
        title: 'Failed to load insights',
        message: error is ApiException
            ? error.message
            : 'An unexpected error occurred.',
        onRetry: () => ref.invalidate(insightsProvider),
      ),
      data: (insights) {
        if (insights.isEmpty) {
          return const EmptyStateView(
            icon: Icons.lightbulb_outline,
            title: 'No insights yet',
            subtitle: 'Tap the sparkle icon to generate insights',
          );
        }
        return ListView.builder(
          itemCount: insights.length,
          itemBuilder: (context, index) {
            final insight = insights[index];
            return _InsightTile(
              insight: insight,
              onMarkRead: () async {
                final service = ref.read(insightServiceProvider);
                await service.markAsRead(insight.id);
                ref.invalidate(insightsProvider);
              },
              onDismiss: () async {
                final service = ref.read(insightServiceProvider);
                await service.dismiss(insight.id);
                ref.invalidate(insightsProvider);
              },
            );
          },
        );
      },
    );
  }
}

class _InsightTile extends StatelessWidget {
  final InsightModel insight;
  final VoidCallback onMarkRead;
  final VoidCallback onDismiss;

  const _InsightTile({
    required this.insight,
    required this.onMarkRead,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(insight.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.orange,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.visibility_off, color: Colors.white),
      ),
      onDismissed: (_) => onDismiss(),
      child: ListTile(
        leading: Icon(
          _categoryIcon(insight.category),
          color: insight.isRead ? Colors.grey : null,
        ),
        title: Text(
          insight.content,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: insight.isRead ? FontWeight.normal : FontWeight.w600,
          ),
        ),
        subtitle: Text(insight.category),
        trailing: insight.isRead
            ? null
            : IconButton(
                icon: const Icon(Icons.check),
                onPressed: onMarkRead,
                tooltip: 'Mark as read',
              ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'SECURITY':
        return Icons.security;
      case 'EFFICIENCY':
        return Icons.speed;
      case 'HEALTH':
        return Icons.favorite;
      case 'MAINTENANCE':
        return Icons.build;
      case 'SUSTAINABILITY':
        return Icons.eco;
      case 'PLANNING':
        return Icons.calendar_today;
      default:
        return Icons.lightbulb;
    }
  }
}

class _NotificationsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(notificationsProvider);

    return notifAsync.when(
      loading: () => const LoadingIndicator(),
      error: (error, _) => ErrorView(
        title: 'Failed to load notifications',
        message: error is ApiException
            ? error.message
            : 'An unexpected error occurred.',
        onRetry: () => ref.invalidate(notificationsProvider),
      ),
      data: (notifications) {
        if (notifications.isEmpty) {
          return const EmptyStateView(
            icon: Icons.notifications_none,
            title: 'No notifications',
          );
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextButton(
                onPressed: () async {
                  final service = ref.read(notificationServiceProvider);
                  await service.markAllAsRead();
                  ref.invalidate(notificationsProvider);
                },
                child: const Text('Mark All as Read'),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notif = notifications[index];
                  return _NotificationTile(
                    notification: notif,
                    onMarkRead: () async {
                      final service = ref.read(notificationServiceProvider);
                      await service.markAsRead(notif.id);
                      ref.invalidate(notificationsProvider);
                    },
                    onDelete: () async {
                      final service = ref.read(notificationServiceProvider);
                      await service.deleteNotification(notif.id);
                      ref.invalidate(notificationsProvider);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onMarkRead;
  final VoidCallback onDelete;

  const _NotificationTile({
    required this.notification,
    required this.onMarkRead,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        leading: Icon(
          _typeIcon(notification.type),
          color: _typeColor(notification.type),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight:
                notification.isRead ? FontWeight.normal : FontWeight.w600,
          ),
        ),
        subtitle: Text(
          notification.body,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: notification.isRead
            ? null
            : IconButton(
                icon: const Icon(Icons.check),
                onPressed: onMarkRead,
              ),
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'ALERT':
        return Icons.warning;
      case 'WARNING':
        return Icons.warning_amber;
      case 'ERROR':
        return Icons.error;
      case 'SUCCESS':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'ALERT':
        return Colors.orange;
      case 'WARNING':
        return Colors.amber;
      case 'ERROR':
        return Colors.red;
      case 'SUCCESS':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }
}
