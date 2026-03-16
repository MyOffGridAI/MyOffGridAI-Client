import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/providers.dart';

/// Shown when the MyOffGridAI device has not been set up yet.
///
/// Displayed when `GET /api/system/status` returns `initialized: false`.
/// Provides instructions for connecting to the setup WiFi network
/// and a retry button to re-check initialization status.
class DeviceNotSetupScreen extends ConsumerStatefulWidget {
  /// Creates a [DeviceNotSetupScreen].
  const DeviceNotSetupScreen({super.key});

  @override
  ConsumerState<DeviceNotSetupScreen> createState() =>
      _DeviceNotSetupScreenState();
}

/// State for [DeviceNotSetupScreen] managing the retry check for device initialization status.
class _DeviceNotSetupScreenState extends ConsumerState<DeviceNotSetupScreen> {
  bool _isChecking = false;

  Future<void> _retryCheck() async {
    setState(() => _isChecking = true);
    try {
      ref.invalidate(systemStatusProvider);
      final status = await ref.read(systemStatusProvider.future);
      if (status.initialized && mounted) {
        context.go(AppConstants.routeLogin);
      }
    } catch (_) {
      // Stay on this screen
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.wifi_tethering,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'MyOffGrid AI Not Set Up',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  _buildStep(context, '1',
                      'On your phone or laptop, go to WiFi settings'),
                  const SizedBox(height: 16),
                  _buildStep(context, '2',
                      'Connect to the network named MyOffGridAI-Setup'),
                  const SizedBox(height: 16),
                  _buildStep(context, '3',
                      'A setup page will open automatically'),
                  const SizedBox(height: 16),
                  _buildStep(context, '4',
                      'Follow the steps to configure your device'),
                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    onPressed: _isChecking ? null : _retryCheck,
                    icon: _isChecking
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context, String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}
