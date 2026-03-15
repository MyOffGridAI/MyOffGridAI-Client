import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/config/theme.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/api/providers.dart';
import 'package:myoffgridai_client/core/auth/auth_state.dart';
import 'package:myoffgridai_client/core/models/system_models.dart';
import 'package:myoffgridai_client/core/services/system_service.dart';

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
        title: const Text('Settings'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'General'),
            Tab(text: 'AI & Memory'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _GeneralTab(),
          const _AiMemoryTab(),
        ],
      ),
    );
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
  double _temperature = 0.7;
  double _similarityThreshold = 0.45;
  int _memoryTopK = 5;
  int _ragMaxContextTokens = 2048;
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
          _temperature = settings.temperature;
          _similarityThreshold = settings.similarityThreshold;
          _memoryTopK = settings.memoryTopK;
          _ragMaxContextTokens = settings.ragMaxContextTokens;
          _loaded = true;
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
        temperature: _temperature,
        similarityThreshold: _similarityThreshold,
        memoryTopK: _memoryTopK,
        ragMaxContextTokens: _ragMaxContextTokens,
      ));
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
