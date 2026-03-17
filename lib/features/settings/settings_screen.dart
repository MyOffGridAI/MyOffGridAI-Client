import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/config/theme.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/api/myoffgridai_api_client.dart';
import 'package:myoffgridai_client/core/api/providers.dart';
import 'package:myoffgridai_client/core/auth/auth_state.dart';
import 'package:myoffgridai_client/core/models/system_models.dart';
import 'package:myoffgridai_client/core/models/user_model.dart';
import 'package:myoffgridai_client/core/models/enrichment_models.dart';
import 'package:myoffgridai_client/core/models/model_catalog_models.dart';
import 'package:myoffgridai_client/core/models/judge_models.dart';
import 'package:myoffgridai_client/core/services/enrichment_service.dart';
import 'package:myoffgridai_client/core/services/judge_service.dart';
import 'package:myoffgridai_client/core/services/model_catalog_service.dart';
import 'package:myoffgridai_client/core/services/system_service.dart';
import 'package:myoffgridai_client/core/services/user_service.dart';
import 'package:myoffgridai_client/features/settings/widgets/discover_model_list.dart';
import 'package:myoffgridai_client/features/settings/widgets/model_detail_panel.dart';
import 'package:myoffgridai_client/shared/utils/size_formatter.dart';
import 'package:myoffgridai_client/shared/widgets/confirmation_dialog.dart';
import 'package:myoffgridai_client/shared/widgets/error_view.dart';
import 'package:myoffgridai_client/shared/widgets/loading_indicator.dart';

/// Full settings screen with tabbed layout.
///
/// Tabs: General, Users, AI & Memory, File Storage, Models, External APIs.
/// Accessible from the Settings gear in the NavigationPanel.
class SettingsScreen extends ConsumerStatefulWidget {
  /// Creates a [SettingsScreen].
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

/// State for [SettingsScreen] managing the six-tab layout controller.
class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
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
        title: const Text('Settings'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'General'),
            Tab(text: 'Users'),
            Tab(text: 'AI & Memory'),
            Tab(text: 'File Storage'),
            Tab(text: 'Models'),
            Tab(text: 'External APIs'),
            Tab(text: 'AI Judge'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _GeneralTab(),
          const _UsersTab(),
          const _AiMemoryTab(),
          const _FileStorageTab(),
          const _ModelsTab(),
          const _ExternalApisTab(),
          const _AiJudgeTab(),
        ],
      ),
    );
  }
}

/// The Users tab for managing users (OWNER and ADMIN only).
class _UsersTab extends ConsumerWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);

    return authAsync.when(
      loading: () => const LoadingIndicator(),
      error: (_, __) => const Center(child: Text('Failed to load auth state')),
      data: (user) {
        if (user == null ||
            (user.role != 'ROLE_OWNER' && user.role != 'ROLE_ADMIN')) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Only Owners and Admins can manage users'),
            ),
          );
        }

        final usersAsync = ref.watch(usersListProvider);
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.person_add),
                  label: const Text('Register New User'),
                  onPressed: () => _showRegisterDialog(context, ref),
                ),
              ),
            ),
            Expanded(
              child: usersAsync.when(
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
                      final u = users[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(u.displayName.isNotEmpty
                              ? u.displayName[0].toUpperCase()
                              : '?'),
                        ),
                        title: Text(u.displayName),
                        subtitle: Text(u.username),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _roleBadge(context, u.role),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.circle,
                              size: 12,
                              color: u.isActive ? Colors.green : Colors.grey,
                            ),
                          ],
                        ),
                        onTap: () => _showUserActions(context, ref, u),
                      );
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

  Future<void> _showRegisterDialog(BuildContext context, WidgetRef ref) async {
    final usernameController = TextEditingController();
    final displayNameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => _RegisterUserDialog(
        formKey: formKey,
        usernameController: usernameController,
        displayNameController: displayNameController,
        emailController: emailController,
        passwordController: passwordController,
        confirmPasswordController: confirmPasswordController,
        ref: ref,
      ),
    );

    usernameController.dispose();
    displayNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    if (created == true) {
      ref.invalidate(usersListProvider);
    }
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
      message: 'This will permanently delete the user and all their data.',
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

/// The General tab with Account, Appearance, Server, and About sections.
class _GeneralTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);
    final themeMode = ref.watch(themeProvider);
    final serverUrlAsync = ref.watch(serverUrlProvider);
    final systemStatusAsync = ref.watch(systemStatusDetailProvider);

    return ListView(
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

/// The AI & Memory tab with configurable sliders for AI settings.
class _AiMemoryTab extends ConsumerStatefulWidget {
  const _AiMemoryTab();

  @override
  ConsumerState<_AiMemoryTab> createState() => _AiMemoryTabState();
}

/// State for [_AiMemoryTab] managing AI settings sliders and save operations.
class _AiMemoryTabState extends ConsumerState<_AiMemoryTab> {
  String _modelName = '';
  double _temperature = 0.7;
  double _similarityThreshold = 0.45;
  int _memoryTopK = 5;
  int _ragMaxContextTokens = 2048;
  int _contextSize = 4096;
  int _contextMessageLimit = 20;
  bool _loaded = false;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final aiSettingsAsync = ref.watch(aiSettingsProvider);

    return aiSettingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Failed to load AI settings',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => ref.invalidate(aiSettingsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (settings) {
        if (!_loaded) {
          _modelName = settings.modelName;
          _temperature = settings.temperature;
          _similarityThreshold = settings.similarityThreshold;
          _memoryTopK = settings.memoryTopK;
          _ragMaxContextTokens = settings.ragMaxContextTokens;
          _contextSize = settings.contextSize;
          _contextMessageLimit = settings.contextMessageLimit;
          _loaded = true;
        }

        final modelsAsync = ref.watch(ollamaModelsProvider);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Model selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Model',
                      style:
                          Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                    const SizedBox(height: 8),
                    modelsAsync.when(
                      data: (models) {
                        final items = models
                            .map((m) => DropdownMenuItem<String>(
                                  value: m.name,
                                  child: Text(
                                    m.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList();
                        // Ensure current value is in the list
                        final hasValue =
                            models.any((m) => m.name == _modelName);
                        return DropdownButtonFormField<String>(
                          initialValue: hasValue ? _modelName : null,
                          hint: const Text('Select a model'),
                          isExpanded: true,
                          items: items,
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _modelName = v);
                            }
                          },
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                        );
                      },
                      loading: () => const Center(
                          child: CircularProgressIndicator()),
                      error: (_, __) =>
                          const Text('Failed to load models'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Temperature
            _buildSliderCard(
              context,
              title: 'Temperature',
              value: _temperature,
              min: 0.0,
              max: 2.0,
              divisions: 20,
              labelLeft: 'Precise',
              labelRight: 'Creative',
              displayValue: _temperature.toStringAsFixed(1),
              onChanged: (v) => setState(() => _temperature = v),
            ),
            const SizedBox(height: 12),

            // Similarity Threshold
            _buildSliderCard(
              context,
              title: 'Similarity Threshold',
              value: _similarityThreshold,
              min: 0.0,
              max: 1.0,
              divisions: 20,
              labelLeft: 'Broad',
              labelRight: 'Strict',
              displayValue: _similarityThreshold.toStringAsFixed(2),
              onChanged: (v) => setState(() => _similarityThreshold = v),
            ),
            const SizedBox(height: 12),

            // Memory Top-K
            _buildSliderCard(
              context,
              title: 'Memory Top-K',
              value: _memoryTopK.toDouble(),
              min: 1,
              max: 20,
              divisions: 19,
              labelLeft: '1',
              labelRight: '20',
              displayValue: '$_memoryTopK memories to include',
              onChanged: (v) => setState(() => _memoryTopK = v.round()),
            ),
            const SizedBox(height: 12),

            // RAG Max Context Tokens
            _buildSliderCard(
              context,
              title: 'RAG Max Context Tokens',
              value: _ragMaxContextTokens.toDouble(),
              min: 512,
              max: 8192,
              divisions: 30,
              labelLeft: '512',
              labelRight: '8192',
              displayValue: '$_ragMaxContextTokens max context tokens',
              onChanged: (v) =>
                  setState(() => _ragMaxContextTokens = (v / 256).round() * 256),
            ),
            const SizedBox(height: 12),

            // Context Size (Ollama num_ctx)
            _buildSliderCard(
              context,
              title: 'Context Size',
              value: _contextSize.toDouble(),
              min: 1024,
              max: 32768,
              divisions: 31,
              labelLeft: 'Compact',
              labelRight: 'Maximum',
              displayValue: '$_contextSize tokens',
              onChanged: (v) =>
                  setState(() => _contextSize = (v / 1024).round() * 1024),
            ),
            const SizedBox(height: 12),

            // Context Message Limit
            _buildSliderCard(
              context,
              title: 'Context Message Limit',
              value: _contextMessageLimit.toDouble(),
              min: 5,
              max: 100,
              divisions: 19,
              labelLeft: '5',
              labelRight: '100',
              displayValue: '$_contextMessageLimit messages per conversation',
              onChanged: (v) =>
                  setState(() => _contextMessageLimit = (v / 5).round() * 5),
            ),
            const SizedBox(height: 24),

            // Save button
            Center(
              child: FilledButton.icon(
                onPressed: _saving ? null : _saveSettings,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_saving ? 'Saving...' : 'Save'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSliderCard(
    BuildContext context, {
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String labelLeft,
    required String labelRight,
    required String displayValue,
    required ValueChanged<double> onChanged,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  displayValue,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
            Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  labelLeft,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                ),
                Text(
                  labelRight,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSettings() async {
    setState(() => _saving = true);
    try {
      final service = ref.read(systemServiceProvider);
      await service.updateAiSettings(AiSettingsModel(
        modelName: _modelName,
        temperature: _temperature,
        similarityThreshold: _similarityThreshold,
        memoryTopK: _memoryTopK,
        ragMaxContextTokens: _ragMaxContextTokens,
        contextSize: _contextSize,
        contextMessageLimit: _contextMessageLimit,
      ));
      ref.invalidate(aiSettingsProvider);
      ref.invalidate(modelHealthProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI settings saved successfully')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save AI settings')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

/// The File Storage tab for configuring the server-side knowledge storage path.
class _FileStorageTab extends ConsumerStatefulWidget {
  const _FileStorageTab();

  @override
  ConsumerState<_FileStorageTab> createState() => _FileStorageTabState();
}

/// State for [_FileStorageTab] managing storage path editing and upload size configuration.
class _FileStorageTabState extends ConsumerState<_FileStorageTab> {
  final _pathController = TextEditingController();
  int _maxUploadSizeMb = 25;
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storageAsync = ref.watch(storageSettingsProvider);

    return storageAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Failed to load storage settings',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => ref.invalidate(storageSettingsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (settings) {
        if (!_loaded) {
          _pathController.text = settings.knowledgeStoragePath;
          _maxUploadSizeMb = settings.maxUploadSizeMb;
          _loaded = true;
        }

        final totalMb = settings.totalSpaceMb;
        final usedMb = settings.usedSpaceMb;
        final freeMb = settings.freeSpaceMb;
        final usagePercent = totalMb > 0 ? usedMb / totalMb : 0.0;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Storage Directory ──
            _buildSectionHeader(context, 'Storage Directory'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _pathController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.folder),
                    labelText: 'Knowledge storage path',
                    border: OutlineInputBorder(),
                    helperText: 'Absolute path on the server filesystem',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Disk Usage ──
            _buildSectionHeader(context, 'Disk Usage'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(
                      value: usagePercent,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total: ${_formatMb(totalMb)}'),
                        Text('Used: ${_formatMb(usedMb)}'),
                        Text('Free: ${_formatMb(freeMb)}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Max Upload Size ──
            _buildSectionHeader(context, 'Max Upload Size'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Per-file limit',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        Text(
                          '$_maxUploadSizeMb MB per file',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _maxUploadSizeMb.toDouble(),
                      min: 1,
                      max: 100,
                      divisions: 99,
                      onChanged: (v) =>
                          setState(() => _maxUploadSizeMb = v.round()),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '1 MB',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                        ),
                        Text(
                          '100 MB',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Save button ──
            Center(
              child: FilledButton.icon(
                onPressed: _saving ? null : _saveSettings,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_saving ? 'Saving...' : 'Save'),
              ),
            ),
          ],
        );
      },
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

  String _formatMb(int mb) {
    if (mb >= 1024) {
      return '${(mb / 1024).toStringAsFixed(1)} GB';
    }
    return '$mb MB';
  }

  Future<void> _saveSettings() async {
    setState(() => _saving = true);
    try {
      final service = ref.read(systemServiceProvider);
      await service.updateStorageSettings(StorageSettingsModel(
        knowledgeStoragePath: _pathController.text.trim(),
        maxUploadSizeMb: _maxUploadSizeMb,
      ));
      ref.invalidate(storageSettingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Storage settings saved successfully')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save storage settings')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

/// The Models tab for browsing, downloading, and managing LM Studio models.
///
/// Contains two sub-tabs: Local Models and Discover.
class _ModelsTab extends ConsumerStatefulWidget {
  const _ModelsTab();

  @override
  ConsumerState<_ModelsTab> createState() => _ModelsTabState();
}

/// State for [_ModelsTab] managing the two sub-tab layout.
class _ModelsTabState extends ConsumerState<_ModelsTab>
    with SingleTickerProviderStateMixin {
  late TabController _subTabController;

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _subTabController,
          tabs: const [
            Tab(text: 'Local Models'),
            Tab(text: 'Discover'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: [
              _LocalModelsSubTab(onNavigateToDiscover: () {
                _subTabController.animateTo(1);
              }),
              const _DiscoverSubTab(),
            ],
          ),
        ),
      ],
    );
  }
}

/// Sub-tab showing model files already downloaded in LM Studio.
class _LocalModelsSubTab extends ConsumerWidget {
  final VoidCallback onNavigateToDiscover;

  const _LocalModelsSubTab({required this.onNavigateToDiscover});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modelsAsync = ref.watch(localModelsProvider);

    return modelsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Failed to load local models',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => ref.invalidate(localModelsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (models) {
        if (models.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.download_outlined,
                  size: 64,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No models downloaded yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Go to the Discover tab to find and download models',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onNavigateToDiscover,
                  icon: const Icon(Icons.search),
                  label: const Text('Discover Models'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(localModelsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: models.length,
            itemBuilder: (context, index) {
              final model = models[index];
              return _LocalModelCard(model: model);
            },
          ),
        );
      },
    );
  }
}

/// Card displaying a local model file with size, format, and delete action.
class _LocalModelCard extends ConsumerWidget {
  final LocalModelFileModel model;

  const _LocalModelCard({required this.model});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          model.format == 'gguf' ? Icons.memory : Icons.hub,
          color: model.isCurrentlyLoaded
              ? Theme.of(context).colorScheme.primary
              : null,
        ),
        title: Text(
          model.filename,
          style: TextStyle(
            fontWeight: model.isCurrentlyLoaded
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          [
            SizeFormatter.formatBytes(model.sizeBytes),
            model.format.toUpperCase(),
            if (model.repoId != null) model.repoId!,
            if (model.isCurrentlyLoaded) 'Currently loaded',
          ].join(' · '),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Delete model',
          onPressed: () => _confirmDelete(context, ref),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Delete Model',
        message:
            'Delete "${model.filename}"? This cannot be undone.',
        confirmText: 'Delete',
        isDestructive: true,
      ),
    );
    if (confirmed != true) return;

    try {
      final service = ref.read(modelCatalogServiceProvider);
      await service.deleteLocalModel(model.filename);
      ref.invalidate(localModelsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted ${model.filename}')),
        );
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete model')),
        );
      }
    }
  }
}

/// Sub-tab for searching and browsing the HuggingFace model catalog.
/// Discover sub-tab with two-panel LM Studio-style layout.
///
/// On wide screens (>=600px), shows a model list on the left and a detail
/// panel on the right. On narrow screens, shows the model list with a
/// bottom sheet detail panel when a file is selected.
class _DiscoverSubTab extends ConsumerStatefulWidget {
  const _DiscoverSubTab();

  @override
  ConsumerState<_DiscoverSubTab> createState() => _DiscoverSubTabState();
}

class _DiscoverSubTabState extends ConsumerState<_DiscoverSubTab> {
  final _searchController = TextEditingController();
  List<HfModelModel> _results = [];
  bool _searching = false;
  String? _error;

  /// Currently selected model + file for the detail panel.
  HfModelModel? _selectedModel;
  HfModelFileModel? _selectedFile;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _searching = true;
      _error = null;
    });

    try {
      final service = ref.read(modelCatalogServiceProvider);
      final results = await service.searchCatalog(query: query);
      if (mounted) setState(() => _results = results);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Search failed. Check your connection.');
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _onFileSelected(HfModelModel model, HfModelFileModel file) {
    setState(() {
      _selectedModel = model;
      _selectedFile = file;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 600;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search HuggingFace models (e.g. "llama 3 gguf")',
              border: const OutlineInputBorder(),
              suffixIcon: _searching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _search,
                    ),
            ),
            onSubmitted: (_) => _search(),
            textInputAction: TextInputAction.search,
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        Expanded(
          child: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: DiscoverModelList(
                        results: _results,
                        onFileSelected: _onFileSelected,
                      ),
                    ),
                    if (_selectedModel != null && _selectedFile != null)
                      Expanded(
                        flex: 2,
                        child: ModelDetailPanel(
                          model: _selectedModel!,
                          initialFile: _selectedFile!,
                          onClose: () => setState(() {
                            _selectedModel = null;
                            _selectedFile = null;
                          }),
                        ),
                      ),
                  ],
                )
              : DiscoverModelList(
                  results: _results,
                  onFileSelected: (model, file) {
                    _onFileSelected(model, file);
                    _showDetailBottomSheet(context, model, file);
                  },
                ),
        ),
      ],
    );
  }

  void _showDetailBottomSheet(
      BuildContext context, HfModelModel model, HfModelFileModel file) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) => ModelDetailPanel(
          model: model,
          initialFile: file,
          onClose: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }
}

/// Card displaying a HuggingFace catalog model with expandable file list
/// and inline download progress.
class _CatalogModelCard extends StatefulWidget {
  /// The HuggingFace model to display.
  final HfModelModel model;

  /// Active downloads keyed by "repoId/filename".
  final Map<String, DownloadProgressModel> activeDownloads;

  /// Callback to start a download for a given repoId and filename.
  final Future<void> Function(String repoId, String filename) onStartDownload;

  /// Callback to cancel a download for a given repoId and filename.
  final Future<void> Function(String repoId, String filename) onCancelDownload;

  const _CatalogModelCard({
    required this.model,
    required this.activeDownloads,
    required this.onStartDownload,
    required this.onCancelDownload,
  });

  @override
  State<_CatalogModelCard> createState() => _CatalogModelCardState();
}

/// State for [_CatalogModelCard] managing the expanded/collapsed file list.
class _CatalogModelCardState extends State<_CatalogModelCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final model = widget.model;
    final ggufFiles = model.ggufFiles;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(
              model.id,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              [
                '${_formatCount(model.downloads)} downloads',
                '${model.likes} likes',
                '${ggufFiles.length} GGUF files',
                if (model.isGated) 'Gated',
              ].join(' · '),
              style: theme.textTheme.bodySmall,
            ),
            trailing: IconButton(
              icon: Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
              ),
              onPressed: () => setState(() => _expanded = !_expanded),
            ),
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          if (_expanded && ggufFiles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: ggufFiles.map((file) {
                  final key = '${model.id}/${file.filename}';
                  final progress = widget.activeDownloads[key];
                  if (progress != null) {
                    return _buildInlineProgress(theme, file, progress);
                  }
                  return _buildFileRow(theme, model, file);
                }).toList(),
              ),
            ),
          if (_expanded && ggufFiles.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                'No GGUF files available in this repository.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Builds the default file row with a download button.
  Widget _buildFileRow(
    ThemeData theme,
    HfModelModel model,
    HfModelFileModel file,
  ) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(
        file.filename,
        style: theme.textTheme.bodyMedium,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        [
          file.formattedSize,
          if (file.quantLabel.isNotEmpty) file.quantLabel,
        ].join(' · '),
        style: theme.textTheme.bodySmall,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.download),
        tooltip: 'Download',
        onPressed: () => widget.onStartDownload(model.id, file.filename),
      ),
    );
  }

  /// Builds the inline download progress UI replacing the file row.
  Widget _buildInlineProgress(
    ThemeData theme,
    HfModelFileModel file,
    DownloadProgressModel progress,
  ) {
    final statusColor = progress.isComplete
        ? Colors.green
        : progress.isFailed
            ? theme.colorScheme.error
            : progress.isCancelled
                ? Colors.orange
                : theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  file.filename,
                  style: theme.textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  progress.status,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: progress.totalBytes > 0
                ? progress.bytesDownloaded / progress.totalBytes
                : null,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '${progress.percentComplete.toStringAsFixed(1)}%'
                  ' · ${SizeFormatter.formatBytes(progress.bytesDownloaded)}'
                  '${progress.totalBytes > 0 ? ' / ${SizeFormatter.formatBytes(progress.totalBytes)}' : ''}',
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (progress.isActive)
                Text(
                  '${SizeFormatter.formatBytes(progress.speedBytesPerSecond.round())}/s',
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
          if (progress.isActive)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => widget.onCancelDownload(
                  progress.repoId,
                  progress.filename,
                ),
                icon: const Icon(Icons.cancel_outlined, size: 18),
                label: const Text('Cancel'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
              ),
            ),
          if (progress.isComplete)
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    'Complete',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.green),
                  ),
                ],
              ),
            ),
          if (progress.isFailed) ...[
            if (progress.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  progress.errorMessage!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.error),
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => widget.onStartDownload(
                  progress.repoId,
                  progress.filename,
                ),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

/// The External APIs tab for managing Anthropic and Brave Search keys (OWNER only).
class _ExternalApisTab extends ConsumerStatefulWidget {
  const _ExternalApisTab();

  @override
  ConsumerState<_ExternalApisTab> createState() => _ExternalApisTabState();
}

/// State for [_ExternalApisTab] managing Anthropic, Brave, and HuggingFace API key inputs and save operations.
class _ExternalApisTabState extends ConsumerState<_ExternalApisTab> {
  final _anthropicKeyController = TextEditingController();
  final _braveKeyController = TextEditingController();
  final _hfTokenController = TextEditingController();
  final _grokKeyController = TextEditingController();
  final _openAiKeyController = TextEditingController();
  String _anthropicModel = 'claude-sonnet-4-20250514';
  bool _anthropicEnabled = false;
  bool _braveEnabled = false;
  bool _hfEnabled = false;
  bool _grokEnabled = false;
  bool _openAiEnabled = false;
  String _preferredFrontierProvider = 'CLAUDE';
  int _maxWebFetchSizeKb = 512;
  int _searchResultLimit = 5;
  bool _loaded = false;
  bool _saving = false;
  bool _obscureAnthropicKey = true;
  bool _obscureBraveKey = true;
  bool _obscureHfToken = true;
  bool _obscureGrokKey = true;
  bool _obscureOpenAiKey = true;

  @override
  void dispose() {
    _anthropicKeyController.dispose();
    _braveKeyController.dispose();
    _hfTokenController.dispose();
    _grokKeyController.dispose();
    _openAiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authStateProvider);

    return authAsync.when(
      loading: () => const LoadingIndicator(),
      error: (_, __) =>
          const Center(child: Text('Failed to load auth state')),
      data: (user) {
        if (user == null || user.role != 'ROLE_OWNER') {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child:
                  Text('Only the Owner can manage external API settings'),
            ),
          );
        }

        final settingsAsync = ref.watch(externalApiSettingsProvider);

        return settingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Failed to load external API settings',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(externalApiSettingsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (settings) {
            if (!_loaded) {
              _anthropicModel = settings.anthropicModel;
              _anthropicEnabled = settings.anthropicEnabled;
              _braveEnabled = settings.braveEnabled;
              _hfEnabled = settings.huggingFaceEnabled;
              _grokEnabled = settings.grokEnabled;
              _openAiEnabled = settings.openAiEnabled;
              _preferredFrontierProvider =
                  settings.preferredFrontierProvider ?? 'CLAUDE';
              _maxWebFetchSizeKb = settings.maxWebFetchSizeKb;
              _searchResultLimit = settings.searchResultLimit;
              _loaded = true;
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Anthropic (Claude) ──
                _buildSectionHeader(context, 'Anthropic (Claude)'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SwitchListTile(
                          title: const Text('Enable Anthropic API'),
                          subtitle: Text(settings.anthropicKeyConfigured
                              ? 'API key configured'
                              : 'No API key configured'),
                          value: _anthropicEnabled,
                          onChanged: (v) =>
                              setState(() => _anthropicEnabled = v),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _anthropicKeyController,
                          obscureText: _obscureAnthropicKey,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.key),
                            labelText: settings.anthropicKeyConfigured
                                ? 'Anthropic API Key (leave blank to keep)'
                                : 'Anthropic API Key',
                            border: const OutlineInputBorder(),
                            helperText:
                                'Enter a new key, or leave blank to keep existing',
                            suffixIcon: IconButton(
                              icon: Icon(_obscureAnthropicKey
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () => setState(() =>
                                  _obscureAnthropicKey =
                                      !_obscureAnthropicKey),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _anthropicModel,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.smart_toy),
                            labelText: 'Model',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'claude-sonnet-4-20250514',
                              child: Text('Claude Sonnet 4'),
                            ),
                            DropdownMenuItem(
                              value: 'claude-haiku-4-5-20251001',
                              child: Text('Claude Haiku 4.5'),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _anthropicModel = v);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Brave Search ──
                _buildSectionHeader(context, 'Brave Search'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SwitchListTile(
                          title: const Text('Enable Brave Search'),
                          subtitle: Text(settings.braveKeyConfigured
                              ? 'API key configured'
                              : 'No API key configured'),
                          value: _braveEnabled,
                          onChanged: (v) =>
                              setState(() => _braveEnabled = v),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _braveKeyController,
                          obscureText: _obscureBraveKey,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.key),
                            labelText: settings.braveKeyConfigured
                                ? 'Brave API Key (leave blank to keep)'
                                : 'Brave API Key',
                            border: const OutlineInputBorder(),
                            helperText:
                                'Enter a new key, or leave blank to keep existing',
                            suffixIcon: IconButton(
                              icon: Icon(_obscureBraveKey
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () => setState(() =>
                                  _obscureBraveKey = !_obscureBraveKey),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── HuggingFace ──
                _buildSectionHeader(context, 'HuggingFace'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SwitchListTile(
                          title: const Text('Enable HuggingFace'),
                          subtitle: Text(
                              settings.huggingFaceKeyConfigured
                                  ? 'Access token configured'
                                  : 'No access token configured'),
                          value: _hfEnabled,
                          onChanged: (v) =>
                              setState(() => _hfEnabled = v),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _hfTokenController,
                          obscureText: _obscureHfToken,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.key),
                            labelText:
                                settings.huggingFaceKeyConfigured
                                    ? 'HuggingFace Token (leave blank to keep)'
                                    : 'HuggingFace Access Token',
                            border: const OutlineInputBorder(),
                            helperText:
                                'Required for gated models. Get one at huggingface.co/settings/tokens',
                            suffixIcon: IconButton(
                              icon: Icon(_obscureHfToken
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () => setState(() =>
                                  _obscureHfToken = !_obscureHfToken),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Grok (xAI) ──
                _buildSectionHeader(context, 'Grok (xAI)'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SwitchListTile(
                          title: const Text('Enable Grok'),
                          subtitle: Text(settings.grokKeyConfigured
                              ? 'API key configured'
                              : 'No API key configured'),
                          value: _grokEnabled,
                          onChanged: (v) =>
                              setState(() => _grokEnabled = v),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _grokKeyController,
                          obscureText: _obscureGrokKey,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.key),
                            labelText: settings.grokKeyConfigured
                                ? 'Grok API Key (leave blank to keep)'
                                : 'Grok API Key',
                            border: const OutlineInputBorder(),
                            helperText:
                                'Enter a new key, or leave blank to keep existing',
                            suffixIcon: IconButton(
                              icon: Icon(_obscureGrokKey
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () => setState(
                                  () => _obscureGrokKey = !_obscureGrokKey),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── OpenAI ──
                _buildSectionHeader(context, 'OpenAI'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SwitchListTile(
                          title: const Text('Enable OpenAI'),
                          subtitle: Text(settings.openAiKeyConfigured
                              ? 'API key configured'
                              : 'No API key configured'),
                          value: _openAiEnabled,
                          onChanged: (v) =>
                              setState(() => _openAiEnabled = v),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _openAiKeyController,
                          obscureText: _obscureOpenAiKey,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.key),
                            labelText: settings.openAiKeyConfigured
                                ? 'OpenAI API Key (leave blank to keep)'
                                : 'OpenAI API Key',
                            border: const OutlineInputBorder(),
                            helperText:
                                'Enter a new key, or leave blank to keep existing',
                            suffixIcon: IconButton(
                              icon: Icon(_obscureOpenAiKey
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () => setState(() =>
                                  _obscureOpenAiKey = !_obscureOpenAiKey),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Preferred Frontier Provider ──
                _buildSectionHeader(context, 'Preferred Frontier Provider'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: DropdownButtonFormField<String>(
                      initialValue: _preferredFrontierProvider,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.cloud),
                        labelText: 'Preferred Provider',
                        border: OutlineInputBorder(),
                        helperText:
                            'Cloud provider tried first for response enhancement',
                      ),
                      items: AppConstants.frontierProviders
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(p),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _preferredFrontierProvider = v);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Limits ──
                _buildSectionHeader(context, 'Limits'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Max Web Fetch Size',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                      fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '$_maxWebFetchSizeKb KB',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                        Slider(
                          value: _maxWebFetchSizeKb.toDouble(),
                          min: 64,
                          max: 10240,
                          divisions: 40,
                          onChanged: (v) => setState(
                              () => _maxWebFetchSizeKb = v.round()),
                        ),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '64 KB',
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
                            Text(
                              '10 MB',
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
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Search Result Limit',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                      fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '$_searchResultLimit results',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                        Slider(
                          value: _searchResultLimit.toDouble(),
                          min: 1,
                          max: 20,
                          divisions: 19,
                          onChanged: (v) => setState(
                              () => _searchResultLimit = v.round()),
                        ),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '1',
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
                            Text(
                              '20',
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
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Save button ──
                Center(
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _saveSettings,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(_saving ? 'Saving...' : 'Save'),
                  ),
                ),
              ],
            );
          },
        );
      },
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

  Future<void> _saveSettings() async {
    setState(() => _saving = true);
    try {
      final service = ref.read(enrichmentServiceProvider);
      final anthropicKey = _anthropicKeyController.text;
      final braveKey = _braveKeyController.text;
      final hfToken = _hfTokenController.text;
      final grokKey = _grokKeyController.text;
      final openAiKey = _openAiKeyController.text;
      await service.updateExternalApiSettings(
        UpdateExternalApiSettingsRequest(
          anthropicApiKey:
              anthropicKey.isNotEmpty ? anthropicKey : null,
          anthropicModel: _anthropicModel,
          anthropicEnabled: _anthropicEnabled,
          braveApiKey: braveKey.isNotEmpty ? braveKey : null,
          braveEnabled: _braveEnabled,
          huggingFaceToken: hfToken.isNotEmpty ? hfToken : null,
          huggingFaceEnabled: _hfEnabled,
          grokApiKey: grokKey.isNotEmpty ? grokKey : null,
          grokEnabled: _grokEnabled,
          openAiApiKey: openAiKey.isNotEmpty ? openAiKey : null,
          openAiEnabled: _openAiEnabled,
          preferredFrontierProvider: _preferredFrontierProvider,
          maxWebFetchSizeKb: _maxWebFetchSizeKb,
          searchResultLimit: _searchResultLimit,
        ),
      );
      ref.invalidate(externalApiSettingsProvider);
      ref.invalidate(enrichmentStatusProvider);
      _anthropicKeyController.clear();
      _braveKeyController.clear();
      _hfTokenController.clear();
      _grokKeyController.clear();
      _openAiKeyController.clear();
      _loaded = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('External API settings saved successfully')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to save external API settings')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

/// Dialog for registering a new user without switching the current session.
class _RegisterUserDialog extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final TextEditingController displayNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final WidgetRef ref;

  const _RegisterUserDialog({
    required this.formKey,
    required this.usernameController,
    required this.displayNameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.ref,
  });

  @override
  State<_RegisterUserDialog> createState() => _RegisterUserDialogState();
}

/// State for [_RegisterUserDialog] managing form fields and user creation submission.
class _RegisterUserDialogState extends State<_RegisterUserDialog> {
  bool _saving = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  Future<void> _register() async {
    if (!widget.formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final client = widget.ref.read(apiClientProvider);
      final body = <String, dynamic>{
        'username': widget.usernameController.text.trim(),
        'displayName': widget.displayNameController.text.trim(),
        'password': widget.passwordController.text,
        'role': 'ROLE_MEMBER',
      };
      final email = widget.emailController.text.trim();
      if (email.isNotEmpty) {
        body['email'] = email;
      }

      await client.post<Map<String, dynamic>>(
        '${AppConstants.authBasePath}/register',
        data: body,
      );

      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Register New User'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: widget.formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: widget.usernameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Username is required';
                    }
                    if (v.trim().length < AppConstants.usernameMinLength) {
                      return 'Username must be at least ${AppConstants.usernameMinLength} characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: widget.displayNameController,
                  decoration: const InputDecoration(
                    labelText: 'Display Name',
                    prefixIcon: Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Display name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: widget.emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email (optional)',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: widget.passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Password is required';
                    }
                    if (v.length < AppConstants.passwordMinLength) {
                      return 'Password must be at least ${AppConstants.passwordMinLength} characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: widget.confirmPasswordController,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _saving ? null : _register(),
                  validator: (v) {
                    if (v != widget.passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _register,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Register'),
        ),
      ],
    );
  }
}

/// AI Judge settings tab for managing the judge model process and testing.
///
/// Shows judge status, start/stop controls, and a test form for evaluating
/// query/response pairs. Restricted to ADMIN and OWNER roles.
class _AiJudgeTab extends ConsumerStatefulWidget {
  const _AiJudgeTab();

  @override
  ConsumerState<_AiJudgeTab> createState() => _AiJudgeTabState();
}

class _AiJudgeTabState extends ConsumerState<_AiJudgeTab> {
  final _queryController = TextEditingController();
  final _responseController = TextEditingController();
  bool _testing = false;
  JudgeTestResultModel? _testResult;

  @override
  void dispose() {
    _queryController.dispose();
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _startJudge() async {
    try {
      final service = ref.read(judgeServiceProvider);
      await service.start();
      ref.invalidate(judgeStatusProvider);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  Future<void> _stopJudge() async {
    try {
      final service = ref.read(judgeServiceProvider);
      await service.stop();
      ref.invalidate(judgeStatusProvider);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  Future<void> _runTest() async {
    final query = _queryController.text.trim();
    final response = _responseController.text.trim();
    if (query.isEmpty || response.isEmpty) return;

    setState(() {
      _testing = true;
      _testResult = null;
    });

    try {
      final service = ref.read(judgeServiceProvider);
      final result = await service.test(query: query, response: response);
      if (mounted) setState(() => _testResult = result);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(judgeStatusProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Status section
        Text('Judge Status', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        statusAsync.when(
          loading: () => const LoadingIndicator(),
          error: (error, _) => Text(
            'Failed to load judge status',
            style: TextStyle(color: colorScheme.error),
          ),
          data: (status) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        status.processRunning
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: status.processRunning
                            ? Colors.green
                            : colorScheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        status.processRunning
                            ? 'Process running on port ${status.port}'
                            : 'Process not running',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        status.enabled ? Icons.toggle_on : Icons.toggle_off,
                        color: status.enabled
                            ? Colors.green
                            : colorScheme.onSurface.withValues(alpha: 0.4),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(status.enabled ? 'Judge enabled' : 'Judge disabled'),
                    ],
                  ),
                  if (status.judgeModelFilename != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Model: ${status.judgeModelFilename}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                  Text(
                    'Score threshold: ${status.scoreThreshold.toStringAsFixed(1)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: status.processRunning ? null : _startJudge,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: status.processRunning ? _stopJudge : null,
                        icon: const Icon(Icons.stop),
                        label: const Text('Stop'),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Refresh status',
                        onPressed: () => ref.invalidate(judgeStatusProvider),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Test section
        Text('Test Evaluation',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _queryController,
                  decoration: const InputDecoration(
                    labelText: 'Query',
                    hintText: 'Enter a test query...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _responseController,
                  decoration: const InputDecoration(
                    labelText: 'Response',
                    hintText: 'Enter the response to evaluate...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _testing ? null : _runTest,
                    icon: _testing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.gavel),
                    label: const Text('Run Test'),
                  ),
                ),
                if (_testResult != null) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  if (!_testResult!.judgeAvailable)
                    Text(
                      _testResult!.error ?? 'Judge is not available',
                      style: TextStyle(color: colorScheme.error),
                    )
                  else ...[
                    Row(
                      children: [
                        Text(
                          'Score: ${_testResult!.score.toStringAsFixed(1)}/10',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_testResult!.needsCloud)
                          Chip(
                            label: const Text('Needs cloud'),
                            avatar: const Icon(Icons.cloud, size: 16),
                            backgroundColor: colorScheme.tertiaryContainer,
                          ),
                      ],
                    ),
                    if (_testResult!.reason != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _testResult!.reason!,
                          style: TextStyle(
                            color:
                                colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    if (_testResult!.error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _testResult!.error!,
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
