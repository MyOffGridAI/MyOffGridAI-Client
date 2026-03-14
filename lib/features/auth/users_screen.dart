import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/models/user_model.dart';
import 'package:myoffgridai_client/core/services/user_service.dart';
import 'package:myoffgridai_client/shared/widgets/confirmation_dialog.dart';
import 'package:myoffgridai_client/shared/widgets/error_view.dart';
import 'package:myoffgridai_client/shared/widgets/loading_indicator.dart';

/// User management screen for OWNER and ADMIN roles.
///
/// Displays a list of all users with their role badges and active status.
/// Provides a FAB to navigate to user registration, and tap actions
/// for role editing, deactivation, and user detail.
class UsersScreen extends ConsumerWidget {
  /// Creates a [UsersScreen].
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go(AppConstants.routeRegister),
        child: const Icon(Icons.person_add),
      ),
      body: usersAsync.when(
        loading: () => const LoadingIndicator(),
        error: (error, _) => ErrorView(
          title: 'Failed to load users',
          message: error is ApiException
              ? error.message
              : 'An unexpected error occurred.',
          onRetry: () => ref.invalidate(usersListProvider),
        ),
        data: (users) {
          if (users.isEmpty) {
            return const Center(child: Text('No users found'));
          }
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(user.displayName.isNotEmpty
                      ? user.displayName[0].toUpperCase()
                      : '?'),
                ),
                title: Text(user.displayName),
                subtitle: Text(user.username),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _roleBadge(context, user.role),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.circle,
                      size: 12,
                      color: user.isActive ? Colors.green : Colors.grey,
                    ),
                  ],
                ),
                onTap: () => _showUserActions(context, ref, user),
              );
            },
          );
        },
      ),
    );
  }

  Widget _roleBadge(BuildContext context, String role) {
    final label = role.replaceFirst('ROLE_', '');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }

  void _showUserActions(BuildContext context, WidgetRef ref, UserModel user) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(ctx);
                _showUserDetail(context, ref, user.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Change Role'),
              onTap: () {
                Navigator.pop(ctx);
                _showChangeRoleDialog(context, ref, user);
              },
            ),
            ListTile(
              leading: Icon(
                user.isActive ? Icons.person_off : Icons.person,
                color: user.isActive ? Colors.red : Colors.green,
              ),
              title: Text(user.isActive ? 'Deactivate' : 'Activate'),
              onTap: () {
                Navigator.pop(ctx);
                _deactivateUser(context, ref, user);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Delete User'),
              onTap: () {
                Navigator.pop(ctx);
                _deleteUser(context, ref, user);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showUserDetail(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    try {
      final service = ref.read(userServiceProvider);
      final detail = await service.getUser(userId);

      if (!context.mounted) return;
      showModalBottomSheet(
        context: context,
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(detail.displayName,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('Username: ${detail.username}'),
                if (detail.email != null) Text('Email: ${detail.email}'),
                Text('Role: ${detail.role.replaceFirst('ROLE_', '')}'),
                Text('Active: ${detail.isActive ? 'Yes' : 'No'}'),
                if (detail.createdAt != null)
                  Text('Created: ${detail.createdAt}'),
                if (detail.lastLoginAt != null)
                  Text('Last Login: ${detail.lastLoginAt}'),
              ],
            ),
          ),
        ),
      );
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  Future<void> _showChangeRoleDialog(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
  ) async {
    const roles = [
      'ROLE_OWNER',
      'ROLE_ADMIN',
      'ROLE_MEMBER',
      'ROLE_VIEWER',
      'ROLE_CHILD',
    ];
    final selectedRole = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Change role for ${user.displayName}'),
        children: roles
            .map((role) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, role),
                  child: Row(
                    children: [
                      if (role == user.role)
                        const Icon(Icons.check, size: 16)
                      else
                        const SizedBox(width: 16),
                      const SizedBox(width: 8),
                      Text(role.replaceFirst('ROLE_', '')),
                    ],
                  ),
                ))
            .toList(),
      ),
    );

    if (selectedRole == null || selectedRole == user.role) return;

    try {
      final service = ref.read(userServiceProvider);
      await service.updateUser(user.id, role: selectedRole);
      ref.invalidate(usersListProvider);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  Future<void> _deactivateUser(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
  ) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Deactivate ${user.displayName}?',
      message: 'This user will no longer be able to log in.',
      isDestructive: true,
    );
    if (confirmed != true) return;

    try {
      final service = ref.read(userServiceProvider);
      await service.deactivateUser(user.id);
      ref.invalidate(usersListProvider);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  Future<void> _deleteUser(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
  ) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete ${user.displayName}?',
      message:
          'This will permanently delete the user and all their data.',
      isDestructive: true,
    );
    if (confirmed != true) return;

    try {
      final service = ref.read(userServiceProvider);
      await service.deleteUser(user.id);
      ref.invalidate(usersListProvider);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }
}
