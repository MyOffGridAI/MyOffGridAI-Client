import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/models/event_model.dart';
import 'package:myoffgridai_client/core/services/event_service.dart';
import 'package:myoffgridai_client/core/services/sensor_service.dart';

/// Shows a dialog for creating or editing a scheduled event.
///
/// Returns `true` if the event was saved, `null` otherwise.
Future<bool?> showEventDialog(
  BuildContext context,
  WidgetRef ref, {
  ScheduledEventModel? existing,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => _EventDialogContent(ref: ref, existing: existing),
  );
}

class _EventDialogContent extends StatefulWidget {
  final WidgetRef ref;
  final ScheduledEventModel? existing;

  const _EventDialogContent({required this.ref, this.existing});

  @override
  State<_EventDialogContent> createState() => _EventDialogContentState();
}

class _EventDialogContentState extends State<_EventDialogContent> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _payloadController;
  late final TextEditingController _cronController;
  late final TextEditingController _intervalController;
  late final TextEditingController _thresholdController;

  late String _eventType;
  late String _actionType;
  String? _sensorId;
  String _thresholdOperator = ThresholdOperator.above;
  late bool _isEnabled;
  bool _saving = false;

  // Schedule preset state
  String _schedulePreset = 'daily';
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  String _selectedDay = 'MON';
  int _everyNHours = 2;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController = TextEditingController(text: e?.name ?? '');
    _descController = TextEditingController(text: e?.description ?? '');
    _payloadController = TextEditingController(text: e?.actionPayload ?? '');
    _cronController = TextEditingController(text: e?.cronExpression ?? '');
    _intervalController = TextEditingController(
        text: e?.recurringIntervalMinutes?.toString() ?? '60');
    _thresholdController = TextEditingController(
        text: e?.thresholdValue?.toString() ?? '');
    _eventType = e?.eventType ?? EventType.scheduled;
    _actionType = e?.actionType ?? ActionType.pushNotification;
    _sensorId = e?.sensorId;
    _thresholdOperator = e?.thresholdOperator ?? ThresholdOperator.above;
    _isEnabled = e?.isEnabled ?? true;

    if (e?.cronExpression != null && e!.cronExpression!.isNotEmpty) {
      _schedulePreset = 'custom';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _payloadController.dispose();
    _cronController.dispose();
    _intervalController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Event' : 'Create Event'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 12),

                // Description
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),

                // Event Type
                DropdownButtonFormField<String>(
                  initialValue: _eventType,
                  decoration: const InputDecoration(
                    labelText: 'Event Type',
                    border: OutlineInputBorder(),
                  ),
                  items: EventType.all
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(EventType.label(t)),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _eventType = v);
                  },
                ),
                const SizedBox(height: 12),

                // Dynamic section based on event type
                _buildDynamicSection(),
                const SizedBox(height: 12),

                // Action Type
                DropdownButtonFormField<String>(
                  initialValue: _actionType,
                  decoration: const InputDecoration(
                    labelText: 'Action Type',
                    border: OutlineInputBorder(),
                  ),
                  items: ActionType.all
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(ActionType.label(t)),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _actionType = v);
                  },
                ),
                const SizedBox(height: 12),

                // Action Payload
                TextFormField(
                  controller: _payloadController,
                  decoration: InputDecoration(
                    labelText: 'Action Payload',
                    border: const OutlineInputBorder(),
                    hintText: _payloadHint(),
                  ),
                  maxLines: 4,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Payload is required'
                      : null,
                ),
                const SizedBox(height: 12),

                // Enabled
                SwitchListTile(
                  title: const Text('Enabled'),
                  value: _isEnabled,
                  onChanged: (v) => setState(() => _isEnabled = v),
                  contentPadding: EdgeInsets.zero,
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
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing ? 'Save' : 'Create'),
        ),
      ],
    );
  }

  Widget _buildDynamicSection() {
    switch (_eventType) {
      case EventType.scheduled:
        return _buildScheduledSection();
      case EventType.sensorThreshold:
        return _buildSensorThresholdSection();
      case EventType.recurring:
        return _buildRecurringSection();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildScheduledSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Schedule',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'daily', label: Text('Daily')),
            ButtonSegment(value: 'weekly', label: Text('Weekly')),
            ButtonSegment(value: 'hours', label: Text('Every N Hours')),
            ButtonSegment(value: 'custom', label: Text('Custom')),
          ],
          selected: {_schedulePreset},
          onSelectionChanged: (s) => setState(() => _schedulePreset = s.first),
        ),
        const SizedBox(height: 8),
        if (_schedulePreset == 'daily')
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Daily at ${_selectedTime.format(context)}'),
            trailing: const Icon(Icons.access_time),
            onTap: _pickTime,
          ),
        if (_schedulePreset == 'weekly') ...[
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedDay,
                  decoration: const InputDecoration(
                    labelText: 'Day',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'MON', child: Text('Monday')),
                    DropdownMenuItem(value: 'TUE', child: Text('Tuesday')),
                    DropdownMenuItem(value: 'WED', child: Text('Wednesday')),
                    DropdownMenuItem(value: 'THU', child: Text('Thursday')),
                    DropdownMenuItem(value: 'FRI', child: Text('Friday')),
                    DropdownMenuItem(value: 'SAT', child: Text('Saturday')),
                    DropdownMenuItem(value: 'SUN', child: Text('Sunday')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedDay = v);
                  },
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                icon: const Icon(Icons.access_time),
                label: Text(_selectedTime.format(context)),
                onPressed: _pickTime,
              ),
            ],
          ),
        ],
        if (_schedulePreset == 'hours')
          TextFormField(
            initialValue: '$_everyNHours',
            decoration: const InputDecoration(
              labelText: 'Every N hours',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (v) {
              final n = int.tryParse(v);
              if (n != null && n > 0) _everyNHours = n;
            },
          ),
        if (_schedulePreset == 'custom')
          TextFormField(
            controller: _cronController,
            decoration: const InputDecoration(
              labelText: 'Cron Expression (6-field)',
              border: OutlineInputBorder(),
              hintText: '0 0 8 * * *',
            ),
          ),
      ],
    );
  }

  Widget _buildSensorThresholdSection() {
    final sensorsAsync = widget.ref.watch(sensorsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sensorsAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const Text('Failed to load sensors'),
          data: (sensors) {
            return DropdownButtonFormField<String>(
              initialValue: _sensorId,
              decoration: const InputDecoration(
                labelText: 'Sensor',
                border: OutlineInputBorder(),
              ),
              items: sensors
                  .map((s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(s.name),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _sensorId = v),
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _thresholdOperator,
                decoration: const InputDecoration(
                  labelText: 'Operator',
                  border: OutlineInputBorder(),
                ),
                items: ThresholdOperator.all
                    .map((o) => DropdownMenuItem(
                          value: o,
                          child: Text(ThresholdOperator.label(o)),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _thresholdOperator = v);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _thresholdController,
                decoration: const InputDecoration(
                  labelText: 'Threshold',
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecurringSection() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _intervalController,
            decoration: const InputDecoration(
              labelText: 'Interval',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(width: 8),
        const Text('minutes'),
      ],
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  String _payloadHint() {
    switch (_actionType) {
      case ActionType.pushNotification:
        return 'Message to send...';
      case ActionType.aiPrompt:
        return 'Prompt to run...';
      case ActionType.aiSummary:
        return 'What to summarize...';
      default:
        return '';
    }
  }

  String _buildCronExpression() {
    switch (_schedulePreset) {
      case 'daily':
        return '0 ${_selectedTime.minute} ${_selectedTime.hour} * * *';
      case 'weekly':
        return '0 ${_selectedTime.minute} ${_selectedTime.hour} * * $_selectedDay';
      case 'hours':
        return '0 0 */$_everyNHours * * *';
      case 'custom':
        return _cronController.text.trim();
      default:
        return '';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final service = widget.ref.read(eventServiceProvider);

      final body = <String, dynamic>{
        'name': _nameController.text.trim(),
        'description': _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        'eventType': _eventType,
        'actionType': _actionType,
        'actionPayload': _payloadController.text.trim(),
        'isEnabled': _isEnabled,
      };

      if (_eventType == EventType.scheduled) {
        body['cronExpression'] = _buildCronExpression();
      } else if (_eventType == EventType.sensorThreshold) {
        body['sensorId'] = _sensorId;
        body['thresholdOperator'] = _thresholdOperator;
        final tv = double.tryParse(_thresholdController.text.trim());
        if (tv != null) body['thresholdValue'] = tv;
      } else if (_eventType == EventType.recurring) {
        body['recurringIntervalMinutes'] =
            int.tryParse(_intervalController.text.trim());
      }

      if (widget.existing != null) {
        await service.updateEvent(widget.existing!.id, body);
      } else {
        await service.createEvent(body);
      }

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
}
