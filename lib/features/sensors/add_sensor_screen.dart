import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/models/sensor_model.dart';
import 'package:myoffgridai_client/core/services/sensor_service.dart';

/// Screen for registering a new sensor.
///
/// Collects sensor configuration including name, type, port path,
/// baud rate, and poll interval. Supports testing the connection
/// before registration.
class AddSensorScreen extends ConsumerStatefulWidget {
  /// Creates an [AddSensorScreen].
  const AddSensorScreen({super.key});

  @override
  ConsumerState<AddSensorScreen> createState() => _AddSensorScreenState();
}

/// State for [AddSensorScreen] managing the sensor registration form,
/// connection testing, and sensor creation.
class _AddSensorScreenState extends ConsumerState<AddSensorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _portController = TextEditingController();
  final _unitController = TextEditingController();
  String _selectedType = SensorType.temperature;
  int _baudRate = 9600;
  int _pollInterval = 60;
  bool _isTesting = false;
  bool _isSaving = false;
  SensorTestResultModel? _testResult;

  @override
  void dispose() {
    _nameController.dispose();
    _portController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Sensor')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Sensor Name'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: const InputDecoration(labelText: 'Sensor Type'),
                items: SensorType.all
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _selectedType = v ?? _selectedType),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _portController,
                decoration: const InputDecoration(
                  labelText: 'Port Path',
                  hintText: '/dev/ttyUSB0',
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Port is required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _baudRate,
                decoration: const InputDecoration(labelText: 'Baud Rate'),
                items: [9600, 19200, 38400, 57600, 115200]
                    .map(
                        (b) => DropdownMenuItem(value: b, child: Text('$b')))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _baudRate = v ?? _baudRate),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _unitController,
                decoration: const InputDecoration(
                  labelText: 'Unit (optional)',
                  hintText: 'e.g., °C, %, hPa',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _pollInterval,
                decoration:
                    const InputDecoration(labelText: 'Poll Interval'),
                items: [5, 10, 30, 60, 300, 600, 3600]
                    .map((s) => DropdownMenuItem(
                        value: s, child: Text('${s}s')))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _pollInterval = v ?? _pollInterval),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _isTesting ? null : _testConnection,
                icon: _isTesting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cable),
                label: Text(_isTesting ? 'Testing...' : 'Test Connection'),
              ),
              if (_testResult != null) ...[
                const SizedBox(height: 8),
                Card(
                  color: _testResult!.success
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      _testResult!.message,
                      style: TextStyle(
                        color:
                            _testResult!.success ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveSensor,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Register Sensor'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _testConnection() async {
    if (_portController.text.isEmpty) return;

    setState(() => _isTesting = true);
    try {
      final service = ref.read(sensorServiceProvider);
      final result =
          await service.testConnection(_portController.text, _baudRate);
      setState(() {
        _testResult = result;
        _isTesting = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _testResult = SensorTestResultModel(
          success: false,
          portPath: _portController.text,
          baudRate: _baudRate,
          message: e.message,
        );
        _isTesting = false;
      });
    }
  }

  Future<void> _saveSensor() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final service = ref.read(sensorServiceProvider);
      await service.createSensor(
        name: _nameController.text,
        type: _selectedType,
        portPath: _portController.text,
        baudRate: _baudRate,
        unit: _unitController.text.isNotEmpty ? _unitController.text : null,
        pollIntervalSeconds: _pollInterval,
      );
      ref.invalidate(sensorsProvider);
      if (mounted) {
        context.go(AppConstants.routeSensors);
      }
    } on ApiException catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }
}
