import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/models/conversation_model.dart';
import 'package:myoffgridai_client/core/services/chat_service.dart';
import 'package:myoffgridai_client/shared/utils/date_formatter.dart';
import 'package:myoffgridai_client/shared/widgets/confirmation_dialog.dart';

/// Unified navigation panel combining nav items, conversation list,
/// search shortcut, and settings into a single Claude-style sidebar.
///
/// Replaces the old [NavigationRail] + [ChatSidebar] two-column layout.
/// Supports expand/collapse with smooth [AnimatedContainer] transition.
class NavigationPanel extends ConsumerStatefulWidget {
  /// Callback to open the "More" end drawer from the parent [Scaffold].
  final VoidCallback onOpenMoreDrawer;

  /// Creates a [NavigationPanel].
  const NavigationPanel({super.key, required this.onOpenMoreDrawer});

  @override
  ConsumerState<NavigationPanel> createState() => _NavigationPanelState();
}

class _NavigationPanelState extends ConsumerState<NavigationPanel> {
  @override
  Widget build(BuildContext context) {
    final isCollapsed = ref.watch(sidebarCollapsedProvider);
    final conversationsAsync = ref.watch(conversationsProvider);
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: AppConstants.animationDuration,
      width: isCollapsed
          ? AppConstants.navPanelCollapsedWidth
          : AppConstants.navPanelExpandedWidth,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: Column(
        children: [
          // ── Header with collapse toggle ──
          _buildHeader(context, ref, isCollapsed),
          const Divider(height: 1),

          // ── New Chat button ──
          _buildNewChatButton(context, ref, isCollapsed),
          const Divider(height: 1),

          // ── Search shortcut ──
          _buildNavItem(
            context,
            icon: Icons.search,
            label: 'Search',
            isCollapsed: isCollapsed,
            isSelected: currentLocation == AppConstants.routeSearch,
            onTap: () => context.go(AppConstants.routeSearch),
          ),
          const Divider(height: 1),

          // ── Navigation section ──
          if (!isCollapsed)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Navigation',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          _buildNavItem(
            context,
            icon: Icons.psychology_outlined,
            selectedIcon: Icons.psychology,
            label: 'Memory',
            isCollapsed: isCollapsed,
            isSelected: currentLocation == AppConstants.routeMemory,
            onTap: () => context.go(AppConstants.routeMemory),
          ),
          _buildNavItem(
            context,
            icon: Icons.library_books_outlined,
            selectedIcon: Icons.library_books,
            label: 'Knowledge',
            isCollapsed: isCollapsed,
            isSelected: currentLocation == AppConstants.routeKnowledge ||
                currentLocation.startsWith('/knowledge/'),
            onTap: () => context.go(AppConstants.routeKnowledge),
          ),
          _buildNavItem(
            context,
            icon: Icons.sensors,
            label: 'Sensors',
            isCollapsed: isCollapsed,
            isSelected: currentLocation == AppConstants.routeSensors ||
                currentLocation.startsWith('/sensors'),
            onTap: () => context.go(AppConstants.routeSensors),
          ),
          _buildNavItem(
            context,
            icon: Icons.more_horiz,
            label: 'More',
            isCollapsed: isCollapsed,
            isSelected: false,
            onTap: widget.onOpenMoreDrawer,
          ),
          const Divider(height: 1),

          // ── Conversations section (Expanded) ──
          if (!isCollapsed)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Conversations',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          Expanded(
            child: conversationsAsync.when(
              loading: () => const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (_, __) => Center(
                child: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => ref.invalidate(conversationsProvider),
                ),
              ),
              data: (conversations) {
                // Capture the stable State context for dialogs — the
                // ListView.builder context can become invalid after a
                // PopupMenuButton route pops.
                final stableContext = this.context;
                return ListView.builder(
                  itemCount: conversations.length,
                  itemBuilder: (context, index) {
                    final conv = conversations[index];
                    final isSelected = currentLocation == '/chat/${conv.id}';
                    return _ConversationTile(
                      conversation: conv,
                      isSelected: isSelected,
                      isCollapsed: isCollapsed,
                      onTap: () => context.go('/chat/${conv.id}'),
                      onRename: () =>
                          _showRenameDialog(stableContext, ref, conv),
                      onDelete: () =>
                          _confirmDelete(stableContext, ref, conv.id),
                    );
                  },
                );
              },
            ),
          ),

          // ── Settings pinned at bottom ──
          const Divider(height: 1),
          _buildNavItem(
            context,
            icon: Icons.settings_outlined,
            selectedIcon: Icons.settings,
            label: 'Settings',
            isCollapsed: isCollapsed,
            isSelected: currentLocation == AppConstants.routeSettings,
            onTap: () => context.go(AppConstants.routeSettings),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, bool isCollapsed) {
    return SizedBox(
      height: 48,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                isCollapsed ? Icons.menu : Icons.menu_open,
              ),
              tooltip: isCollapsed ? 'Expand panel' : 'Collapse panel',
              onPressed: () => ref
                  .read(sidebarCollapsedProvider.notifier)
                  .state = !isCollapsed,
            ),
            if (!isCollapsed) ...[
              const SizedBox(width: 4),
              const Expanded(
                child: Text(
                  'MyOffGrid AI',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNewChatButton(
    BuildContext context,
    WidgetRef ref,
    bool isCollapsed,
  ) {
    if (isCollapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: IconButton(
          icon: const Icon(Icons.add),
          tooltip: 'New conversation',
          onPressed: () => _createConversation(context, ref),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(8),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          icon: const Icon(Icons.add, size: 18),
          label: const Text('New Chat'),
          onPressed: () => _createConversation(context, ref),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    IconData? selectedIcon,
    required String label,
    required bool isCollapsed,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveIcon = isSelected ? (selectedIcon ?? icon) : icon;

    if (isCollapsed) {
      return Tooltip(
        message: label,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: Icon(
              effectiveIcon,
              color: isSelected ? colorScheme.onPrimaryContainer : null,
            ),
            onPressed: onTap,
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 4),
      decoration: BoxDecoration(
        color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        leading: Icon(
          effectiveIcon,
          size: 20,
          color: isSelected ? colorScheme.onPrimaryContainer : null,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? colorScheme.onPrimaryContainer : null,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  Future<void> _createConversation(BuildContext context, WidgetRef ref) async {
    try {
      final service = ref.read(chatServiceProvider);
      final conv = await service.createConversation();
      ref.invalidate(conversationsProvider);
      if (context.mounted) {
        context.go('/chat/${conv.id}');
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  Future<void> _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    ConversationSummaryModel conversation,
  ) async {
    final controller = TextEditingController(
      text: conversation.title ?? '',
    );
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename chat'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.pop(ctx, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (result != null && result.isNotEmpty && context.mounted) {
      try {
        final service = ref.read(chatServiceProvider);
        await service.renameConversation(conversation.id, result);
        ref.invalidate(conversationsProvider);
      } on ApiException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message)),
          );
        }
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String conversationId,
  ) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Conversation',
      message:
          'This will permanently delete this conversation and all its messages.',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (confirmed == true && context.mounted) {
      try {
        final service = ref.read(chatServiceProvider);
        await service.deleteConversation(conversationId);
        ref.invalidate(conversationsProvider);

        if (context.mounted) {
          final location = GoRouterState.of(context).matchedLocation;
          if (location == '/chat/$conversationId') {
            context.go(AppConstants.routeHome);
          }
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
}

class _ConversationTile extends StatelessWidget {
  final ConversationSummaryModel conversation;
  final bool isSelected;
  final bool isCollapsed;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _ConversationTile({
    required this.conversation,
    required this.isSelected,
    required this.isCollapsed,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final title = conversation.title ?? 'New Conversation';

    if (isCollapsed) {
      return Tooltip(
        message: title,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: CircleAvatar(
              radius: 14,
              backgroundColor: isSelected
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHighest,
              child: Text(
                title.isNotEmpty ? title[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                ),
              ),
            ),
            onPressed: onTap,
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 4),
      decoration: BoxDecoration(
        color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (conversation.lastMessagePreview != null)
              Text(
                conversation.lastMessagePreview!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11),
              ),
            if (conversation.updatedAt != null)
              Text(
                DateFormatter.formatRelative(
                    DateTime.parse(conversation.updatedAt!)),
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          iconSize: 18,
          padding: EdgeInsets.zero,
          onSelected: (value) {
            switch (value) {
              case 'rename':
                onRename();
              case 'delete':
                onDelete();
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'rename',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 16),
                  SizedBox(width: 8),
                  Text('Rename'),
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
        onTap: onTap,
      ),
    );
  }
}
