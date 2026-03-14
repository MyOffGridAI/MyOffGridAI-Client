import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/myoffgridai_api_client.dart';
import 'package:myoffgridai_client/core/auth/secure_storage_service.dart';

/// DTO mirroring server OllamaHealthDto.
class OllamaHealthDto {
  final bool available;
  final String? activeModel;
  final String? embedModelName;
  final int? responseTimeMs;

  const OllamaHealthDto({
    required this.available,
    this.activeModel,
    this.embedModelName,
    this.responseTimeMs,
  });

  factory OllamaHealthDto.fromJson(Map<String, dynamic> json) {
    return OllamaHealthDto(
      available: json['available'] as bool? ?? false,
      activeModel: json['activeModel'] as String?,
      embedModelName: json['embedModelName'] as String?,
      responseTimeMs: json['responseTimeMs'] as int?,
    );
  }
}

/// DTO mirroring server SystemStatusDto.
class SystemStatusDto {
  final bool initialized;

  const SystemStatusDto({required this.initialized});

  factory SystemStatusDto.fromJson(Map<String, dynamic> json) {
    return SystemStatusDto(
      initialized: json['initialized'] as bool? ?? false,
    );
  }
}

/// Provider that polls system status to check if the device is initialized.
final systemStatusProvider = FutureProvider.autoDispose<SystemStatusDto>((ref) async {
  final client = ref.watch(apiClientProvider);
  try {
    final response = await client.get<Map<String, dynamic>>(
      '${AppConstants.systemBasePath}/status',
    );
    final data = response['data'] as Map<String, dynamic>?;
    if (data != null) {
      return SystemStatusDto.fromJson(data);
    }
    return const SystemStatusDto(initialized: true);
  } catch (_) {
    // If we can't reach the system status, assume initialized
    // so the user gets to the login screen (connection banner handles unreachable)
    return const SystemStatusDto(initialized: true);
  }
});

/// Provider that polls Ollama model health every 60 seconds.
final modelHealthProvider = FutureProvider.autoDispose<OllamaHealthDto>((ref) async {
  final client = ref.watch(apiClientProvider);
  try {
    final response = await client.get<Map<String, dynamic>>(
      '${AppConstants.modelsBasePath}/health',
    );
    final data = response['data'] as Map<String, dynamic>?;
    if (data != null) {
      return OllamaHealthDto.fromJson(data);
    }
    return const OllamaHealthDto(available: false);
  } catch (_) {
    return const OllamaHealthDto(available: false);
  }
});

/// Provider that fetches the unread notification count.
final unreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final client = ref.watch(apiClientProvider);
  try {
    final response = await client.get<Map<String, dynamic>>(
      '${AppConstants.notificationsBasePath}/unread-count',
    );
    final data = response['data'];
    if (data is int) return data;
    return 0;
  } catch (_) {
    return 0;
  }
});

/// Stream provider that pings the server periodically to check connectivity.
final connectionStatusProvider = StreamProvider.autoDispose<bool>((ref) {
  final client = ref.watch(apiClientProvider);
  final controller = StreamController<bool>();

  Future<void> check() async {
    try {
      await client.get<Map<String, dynamic>>(
        '${AppConstants.systemBasePath}/status',
      );
      controller.add(true);
    } catch (_) {
      controller.add(false);
    }
  }

  check();
  final timer = Timer.periodic(AppConstants.connectionPollInterval, (_) => check());

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});

/// Provider that resolves the server URL from storage and creates the API client.
final serverUrlProvider = FutureProvider<String>((ref) async {
  final storage = ref.watch(secureStorageProvider);
  return storage.getServerUrl();
});
