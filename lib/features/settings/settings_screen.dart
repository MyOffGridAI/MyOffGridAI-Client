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
import 'package:myoffgridai_client/core/services/system_service.dart';
import 'package:myoffgridai_client/core/services/user_service.dart';
import 'package:myoffgridai_client/shared/widgets/confirmation_dialog.dart';
import 'package:myoffgridai_client/shared/widgets/error_view.dart';
import 'package:myoffgridai_client/shared/widgets/loading_indicator.dart';

/// Full settings screen with tabbed layout: General and AI & Memory.
///
/// Accessible from the Settings gear in the NavigationPanel.
class SettingsScreen extends ConsumerStatefulWidget {
  /// Creates a [SettingsScreen].
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
          tabs: const [
            Tab(text: 'General'),
            Tab(text: 'Users'),
            Tab(text: 'AI & Memory'),
            Tab(text: 'File Storage'),
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
