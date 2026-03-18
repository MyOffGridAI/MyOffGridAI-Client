import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/core/auth/auth_service.dart';
import 'package:myoffgridai_client/core/auth/secure_storage_service.dart';
import 'package:myoffgridai_client/core/models/user_model.dart';
import 'package:myoffgridai_client/core/services/device_registration_service.dart';
import 'package:myoffgridai_client/core/services/foreground_service_manager.dart';
import 'package:myoffgridai_client/core/services/log_service.dart';
import 'package:myoffgridai_client/core/services/mqtt_service.dart';

/// Manages the authentication state for the application.
///
/// Checks for stored tokens on startup, validates them, and provides
/// login, logout, and register methods that update the auth state.
class AuthNotifier extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    final storage = ref.read(secureStorageProvider);
    final token = await storage.getAccessToken();
    if (token == null) return null;

    // Decode JWT to get user info without a network call
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = _decodeJwtPayload(parts[1]);
      if (payload == null) return null;

      // Check expiry
      final exp = payload['exp'] as int?;
      if (exp != null) {
        final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        if (expiry.isBefore(DateTime.now())) {
          // Token expired — try refresh
          try {
            final authService = ref.read(authServiceProvider);
            final authResponse = await authService.refresh();
            return authResponse.user;
          } catch (_) {
            await storage.clearTokens();
            return null;
          }
        }
      }

      final userId = payload['userId'] as String? ?? payload['sub'] as String?;
      final username = payload['sub'] as String? ?? '';
      final displayName = payload['displayName'] as String? ?? username;
      final role = payload['role'] as String? ?? 'ROLE_MEMBER';

      if (userId == null) return null;

      return UserModel(
        id: userId,
        username: username,
        displayName: displayName,
        role: role,
        isActive: true,
      );
    } catch (_) {
      await storage.clearTokens();
      return null;
    }
  }

  /// Logs in with [username] and [password], updating state on success.
  ///
  /// On failure, sets state to [AsyncError]. Callers should check
  /// [state.hasError] after awaiting to detect and display errors.
  Future<void> login(String username, String password) async {
    state = const AsyncLoading();
    try {
      final authService = ref.read(authServiceProvider);
      final response = await authService.login(username, password);
      state = AsyncData(response.user);
      _startNotificationServices(response.user.id);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Registers a new user account and updates state on success.
  ///
  /// On failure, sets state to [AsyncError]. Callers should check
  /// [state.hasError] after awaiting to detect and display errors.
  Future<void> register({
    required String username,
    required String displayName,
    required String password,
    String? email,
  }) async {
    state = const AsyncLoading();
    try {
      final authService = ref.read(authServiceProvider);
      final response = await authService.register(
        username: username,
        displayName: displayName,
        password: password,
        email: email,
      );
      state = AsyncData(response.user);
      _startNotificationServices(response.user.id);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Logs out the current user and clears the auth state.
  Future<void> logout() async {
    _stopNotificationServices();
    final authService = ref.read(authServiceProvider);
    await authService.logout();
    state = const AsyncData(null);
  }

  /// Starts device registration, foreground service, and MQTT after login.
  void _startNotificationServices(String userId) {
    // Non-blocking — failures must not prevent login
    Future<void>.microtask(() async {
      try {
        final regService = ref.read(deviceRegistrationServiceProvider);
        await regService.registerDevice();
      } catch (e) {
        LogService.instance.error('AUTH', 'Device registration failed', e);
      }

      try {
        final foregroundManager = ref.read(foregroundServiceManagerProvider);
        await foregroundManager.startService();
      } catch (e) {
        LogService.instance.error('AUTH', 'Foreground service start failed', e);
      }

      try {
        final mqttNotifier = ref.read(mqttServiceProvider.notifier);
        await mqttNotifier.connect(userId);
      } catch (e) {
        LogService.instance.error('AUTH', 'MQTT connect failed', e);
      }
    });
  }

  /// Stops MQTT and foreground service on logout.
  void _stopNotificationServices() {
    try {
      final mqttNotifier = ref.read(mqttServiceProvider.notifier);
      mqttNotifier.disconnect();
    } catch (e) {
      LogService.instance.error('AUTH', 'MQTT disconnect failed', e);
    }

    try {
      final foregroundManager = ref.read(foregroundServiceManagerProvider);
      foregroundManager.stopService();
    } catch (e) {
      LogService.instance.error('AUTH', 'Foreground service stop failed', e);
    }
  }

  Map<String, dynamic>? _decodeJwtPayload(String payload) {
    try {
      String normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}

/// Riverpod provider for the authentication state.
final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, UserModel?>(() => AuthNotifier());
