import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/api/myoffgridai_api_client.dart';
import 'package:myoffgridai_client/core/models/user_model.dart';
import 'package:myoffgridai_client/shared/widgets/error_view.dart';
import 'package:myoffgridai_client/shared/widgets/loading_indicator.dart';

/// Provider for fetching the user list (OWNER/ADMIN only).
final _usersListProvider =
    FutureProvider.autoDispose<List<UserModel>>((ref) async {
  final client = ref.watch(apiClientProvider);
  final response = await client.get<Map<String, dynamic>>(
    AppConstants.usersBasePath,
    queryParams: {'page': 0, 'size': AppConstants.maxPageSize},
  );
  final data = response['data'] as List<dynamic>?;
  if (data == null) return [];
  return data
      .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
      .toList();
});

/// User management screen for OWNER and ADMIN roles.
///
/// Displays a list of all users with their role badges and active status.
/// Provides a FAB to navigate to user registration and tap actions
/// for role editing and deactivation.
class UsersScreen extends ConsumerWidget {
  /// Creates a [UsersScreen].
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(_usersListProvider);

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
          onRetry: () => ref.invalidate(_usersListProvider),
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
              leading: const Icon(Icons.edit),
              title: const Text('Edit Role'),
              onTap: () {
                Navigator.pop(ctx);
                // Full implementation in MC-002
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
                // Full implementation in MC-002
              },
            ),
          ],
        ),
      ),
    );
  }
}
