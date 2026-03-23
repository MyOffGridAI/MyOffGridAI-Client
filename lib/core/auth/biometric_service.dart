import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:myoffgridai_client/core/services/log_service.dart';

/// Wraps the [LocalAuthentication] plugin for biometric authentication.
///
/// Provides availability checks and authentication prompts. Returns false
/// gracefully on platforms that do not support biometrics (e.g. web, desktop).
class BiometricService {
  final LocalAuthentication _auth;

  /// Creates a [BiometricService] with the given [LocalAuthentication] instance.
  BiometricService({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  /// Returns true if the device has biometric hardware and at least one
  /// biometric is enrolled. Returns false on unsupported platforms.
  Future<bool> isAvailable() async {
    try {
      if (kIsWeb) return false;
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (e) {
      LogService.instance.error('BIOMETRIC', 'Availability check failed', e);
      return false;
    }
  }

  /// Triggers the system biometric prompt. Returns true if authentication
  /// succeeds, false otherwise.
  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Authenticate to log in to MyOffGrid AI',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      LogService.instance.error('BIOMETRIC', 'Authentication failed', e);
      return false;
    }
  }
}

/// Riverpod provider for [BiometricService].
final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});
