import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/config/theme.dart';
import 'package:myoffgridai_client/core/api/providers.dart';
import 'package:myoffgridai_client/core/auth/auth_state.dart';
import 'package:myoffgridai_client/core/services/system_service.dart';

/// Full settings screen with Account, Appearance, Server, and About sections.
///
/// Accessible from the Settings gear in the [NavigationPanel].
class SettingsScreen extends ConsumerWidget {
  /// Creates a [SettingsScreen].
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);
    final themeMode = ref.watch(themeProvider);
    final serverUrlAsync = ref.watch(serverUrlProvider);
    final systemStatusAsync = ref.watch(systemStatusDetailProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Account ──
          _buildSectionHeader(context, 'Account'),
          Card(
            child: authAsync.when(
              data: (user) {
                if (user == null) {
                  return const ListTile(
                    title: Text('Not logged in'),
                  );
                }
                return Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: const Text('Username'),
                      subtitle: Text(user.username),
                    ),
                    ListTile(
                      leading: const Icon(Icons.badge),
                      title: const Text('Display Name'),
                      subtitle: Text(user.displayName),
                    ),
                    ListTile(
                      leading: const Icon(Icons.security),
                      title: const Text('Role'),
                      subtitle: Text(
                        user.role.replaceFirst('ROLE_', ''),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const ListTile(
                title: Text('Loading...'),
              ),
              error: (_, __) => const ListTile(
                title: Text('Failed to load account info'),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Appearance ──
          _buildSectionHeader(context, 'Appearance'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.brightness_auto),
                  title: const Text('System'),
                  subtitle: const Text('Follow device theme'),
                  trailing: themeMode == ThemeMode.system
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => ref
                      .read(themeProvider.notifier)
                      .setThemeMode(ThemeMode.system),
                ),
                ListTile(
                  leading: const Icon(Icons.light_mode),
                  title: const Text('Light'),
                  trailing: themeMode == ThemeMode.light
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => ref
                      .read(themeProvider.notifier)
                      .setThemeMode(ThemeMode.light),
                ),
                ListTile(
                  leading: const Icon(Icons.dark_mode),
                  title: const Text('Dark'),
                  trailing: themeMode == ThemeMode.dark
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => ref
                      .read(themeProvider.notifier)
                      .setThemeMode(ThemeMode.dark),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Server ──
          _buildSectionHeader(context, 'Server'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.dns),
                  title: const Text('Server URL'),
                  subtitle: serverUrlAsync.when(
                    data: (url) => Text(url),
                    loading: () => const Text('Loading...'),
                    error: (_, __) => const Text('Unknown'),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Server Version'),
                  subtitle: systemStatusAsync.when(
                    data: (status) =>
                        Text(status.serverVersion ?? 'Unknown'),
                    loading: () => const Text('Loading...'),
                    error: (_, __) => const Text('Unavailable'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── About ──
          _buildSectionHeader(context, 'About'),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.eco),
                  title: Text('MyOffGrid AI'),
                  subtitle: Text('Private, local AI for off-grid living'),
                ),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('Instance'),
                  subtitle: systemStatusAsync.when(
                    data: (status) =>
                        Text(status.instanceName ?? 'MyOffGrid AI'),
                    loading: () => const Text('Loading...'),
                    error: (_, __) => const Text('Unknown'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
