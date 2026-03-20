import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/models/skill_model.dart';
import 'package:myoffgridai_client/core/services/skills_service.dart';
import 'package:myoffgridai_client/shared/widgets/empty_state_view.dart';
import 'package:myoffgridai_client/shared/widgets/error_view.dart';
import 'package:myoffgridai_client/shared/widgets/loading_indicator.dart';

/// Displays available skills in a grid layout.
///
/// Shows each skill as a card with name, description, category, and
/// enabled status. Tapping a skill opens the execution screen.
class SkillsScreen extends ConsumerWidget {
  /// Creates a [SkillsScreen].
  const SkillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skillsAsync = ref.watch(skillsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Skills'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create skill',
            onPressed: () => _showCreateSkillDialog(context, ref),
          ),
        ],
      ),
      body: skillsAsync.when(
        loading: () => const LoadingIndicator(),
        error: (error, _) => ErrorView(
          title: 'Failed to load skills',
          message: error is ApiException
              ? error.message
              : 'An unexpected error occurred.',
          onRetry: () => ref.invalidate(skillsProvider),
        ),
        data: (skills) {
          if (skills.isEmpty) {
            return const EmptyStateView(
              icon: Icons.auto_fix_high,
              title: 'No skills available',
              subtitle: 'Skills are registered on the server',
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 300,
              childAspectRatio: 1.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: skills.length,
            itemBuilder: (context, index) => _SkillCard(
              skill: skills[index],
              onTap: () => _showSkillDetail(context, ref, skills[index]),
            ),
          );
        },
      ),
    );
  }

  void _showCreateSkillDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => _CreateSkillDialog(ref: ref),
    );
  }

  void _showSkillDetail(
    BuildContext context,
    WidgetRef ref,
    SkillModel skill,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollController) => _SkillDetailSheet(
          skill: skill,
          scrollController: scrollController,
          ref: ref,
        ),
      ),
    );
  }
}

/// Renders a skill as a grid card showing name, description, category, and enabled status.
class _SkillCard extends StatelessWidget {
  final SkillModel skill;
  final VoidCallback onTap;

  const _SkillCard({required this.skill, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_fix_high,
                    color: skill.isEnabled
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                  ),
                  const Spacer(),
                  if (skill.isBuiltIn)
                    const Chip(
                      label: Text('Built-in', style: TextStyle(fontSize: 10)),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                skill.displayName,
                style: Theme.of(context).textTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (skill.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  skill.description!,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const Spacer(),
              Row(
                children: [
                  if (skill.category != null)
                    Text(
                      skill.category!,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  const Spacer(),
                  Icon(
                    skill.isEnabled
                        ? Icons.check_circle
                        : Icons.cancel_outlined,
                    size: 16,
                    color: skill.isEnabled ? Colors.green : Colors.grey,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet displaying skill details and an execute button within [SkillsScreen].
class _SkillDetailSheet extends StatefulWidget {
  final SkillModel skill;
  final ScrollController scrollController;
  final WidgetRef ref;

  const _SkillDetailSheet({
    required this.skill,
    required this.scrollController,
    required this.ref,
  });

  @override
  State<_SkillDetailSheet> createState() => _SkillDetailSheetState();
}

/// State for [_SkillDetailSheet] managing skill execution and result display.
class _SkillDetailSheetState extends State<_SkillDetailSheet> {
  bool _isExecuting = false;
  SkillExecutionModel? _lastExecution;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.skill.displayName,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          if (widget.skill.description != null) ...[
            const SizedBox(height: 8),
            Text(widget.skill.description!),
          ],
          const SizedBox(height: 16),
          if (widget.skill.version != null)
            Text('Version: ${widget.skill.version}',
                style: Theme.of(context).textTheme.bodySmall),
          if (widget.skill.author != null)
            Text('Author: ${widget.skill.author}',
                style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.skill.isEnabled && !_isExecuting
                  ? _executeSkill
                  : null,
              icon: _isExecuting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(_isExecuting ? 'Executing...' : 'Execute'),
            ),
          ),
          if (_lastExecution != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status: ${_lastExecution!.status}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _lastExecution!.isSuccess
                              ? Colors.green
                              : _lastExecution!.isFailed
                                  ? Colors.red
                                  : null,
                        )),
                    if (_lastExecution!.outputResult != null) ...[
                      const SizedBox(height: 8),
                      Text('Result: ${_lastExecution!.outputResult}'),
                    ],
                    if (_lastExecution!.errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Error: ${_lastExecution!.errorMessage}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                    if (_lastExecution!.durationMs != null)
                      Text(
                        'Duration: ${_lastExecution!.durationMs}ms',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _executeSkill() async {
    setState(() => _isExecuting = true);
    try {
      final service = widget.ref.read(skillsServiceProvider);
      final execution = await service.executeSkill(widget.skill.id);
      setState(() {
        _lastExecution = execution;
        _isExecuting = false;
      });
    } on ApiException catch (e) {
      setState(() => _isExecuting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }
}

/// Skill category values matching the server enum.
const _skillCategories = [
  'HOMESTEAD',
  'RESOURCE',
  'PLANNING',
  'KNOWLEDGE',
  'WEATHER',
  'CUSTOM',
];

/// Dialog for creating a new custom skill.
class _CreateSkillDialog extends StatefulWidget {
  final WidgetRef ref;

  const _CreateSkillDialog({required this.ref});

  @override
  State<_CreateSkillDialog> createState() => _CreateSkillDialogState();
}

/// State for [_CreateSkillDialog] managing form fields and submission.
class _CreateSkillDialogState extends State<_CreateSkillDialog> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'CUSTOM';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _displayNameController.addListener(_autoGenerateName);
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Auto-generates a snake_case name from the display name.
  void _autoGenerateName() {
    final display = _displayNameController.text;
    final generated = display
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    _nameController.text = generated;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final service = widget.ref.read(skillsServiceProvider);
      await service.createSkill(
        name: _nameController.text.trim(),
        displayName: _displayNameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
      );
      widget.ref.invalidate(skillsProvider);
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Skill'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _displayNameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Display Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Identifier',
                    helperText: 'Auto-generated from display name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: _skillCategories
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedCategory = v);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}
