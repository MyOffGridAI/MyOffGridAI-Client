import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/providers.dart';
import 'package:myoffgridai_client/shared/widgets/notification_badge.dart';

/// Compact bar displayed below the app bar showing Ollama status and notifications.
///
/// Shows a green/red status dot for Ollama availability, the active model name,
/// and the unread notification count. Tapping the notification count navigates
/// to the Insights screen.
class SystemStatusBar extends ConsumerWidget {
  /// Creates a [SystemStatusBar].
  const SystemStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(modelHealthProvider);
    final unreadAsync = ref.watch(unreadCountProvider);

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
                Text(
                  health.activeModel ?? 'No model',
                  style: Theme.of(context).textTheme.bodySmall,
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
