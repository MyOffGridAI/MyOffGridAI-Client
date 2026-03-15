import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/models/event_model.dart';
import 'package:myoffgridai_client/core/services/event_service.dart';
import 'package:myoffgridai_client/features/events/event_dialog.dart';
import 'package:myoffgridai_client/shared/widgets/confirmation_dialog.dart';
import 'package:myoffgridai_client/shared/widgets/empty_state_view.dart';
import 'package:myoffgridai_client/shared/widgets/error_view.dart';
import 'package:myoffgridai_client/shared/widgets/loading_indicator.dart';

/// Dashboard displaying all scheduled events.
///
/// Shows events as cards with type badges, action labels, toggle switches,
/// and edit/delete options. Provides a FAB to create new events.
class EventsScreen extends ConsumerWidget {
  /// Creates an [EventsScreen].
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: eventsAsync.when(
        loading: () => const LoadingIndicator(),
        error: (error, _) => ErrorView(
          title: 'Failed to load events',
          message: error is ApiException
              ? error.message
              : 'An unexpected error occurred.',
          onRetry: () => ref.invalidate(eventsListProvider),
        ),
        data: (events) {
          if (events.isEmpty) {
            return const EmptyStateView(
              icon: Icons.event,
              title: 'No events configured',
              subtitle: 'Tap + to create an event',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: events.length,
            itemBuilder: (context, index) => _EventCard(
              event: events[index],
              onToggle: () => _toggleEvent(context, ref, events[index]),
              onEdit: () => _showEditDialog(context, ref, events[index]),
              onDelete: () => _deleteEvent(context, ref, events[index]),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final created = await showEventDialog(context, ref);
    if (created == true) {
      ref.invalidate(eventsListProvider);
    }
  }

  Future<void> _showEditDialog(
      BuildContext context, WidgetRef ref, ScheduledEventModel event) async {
    final updated = await showEventDialog(context, ref, existing: event);
    if (updated == true) {
      ref.invalidate(eventsListProvider);
    }
  }

  Future<void> _toggleEvent(
      BuildContext context, WidgetRef ref, ScheduledEventModel event) async {
    try {
      final service = ref.read(eventServiceProvider);
      await service.toggleEvent(event.id);
      ref.invalidate(eventsListProvider);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  Future<void> _deleteEvent(
      BuildContext context, WidgetRef ref, ScheduledEventModel event) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Event',
      message: 'This will permanently delete "${event.name}".',
      isDestructive: true,
    );
    if (confirmed != true) return;

    try {
      final service = ref.read(eventServiceProvider);
      await service.deleteEvent(event.id);
      ref.invalidate(eventsListProvider);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }
}

class _EventCard extends StatelessWidget {
  final ScheduledEventModel event;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EventCard({
    required this.event,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Switch(
                  value: event.isEnabled,
                  onChanged: (_) => onToggle(),
                ),
                PopupMenuButton<String>(
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit();
                      case 'delete':
                        onDelete();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(
                    EventType.label(event.eventType),
                    style: const TextStyle(fontSize: 11),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  backgroundColor: colorScheme.primaryContainer,
                  labelStyle: TextStyle(color: colorScheme.onPrimaryContainer),
                ),
                const SizedBox(width: 8),
                Text(
                  ActionType.label(event.actionType),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            if (event.nextFireAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Next: ${event.nextFireAt}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
