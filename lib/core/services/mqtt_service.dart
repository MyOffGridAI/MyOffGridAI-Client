import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/auth/secure_storage_service.dart';
import 'package:myoffgridai_client/core/models/notification_model.dart';
import 'package:myoffgridai_client/core/services/local_notification_service.dart';
import 'package:myoffgridai_client/core/services/log_service.dart';
import 'package:myoffgridai_client/core/services/notification_service.dart';

/// MQTT connection status.
///
/// Named `MqttConnectionStatus` to avoid collision with the mqtt_client
/// package's own `MqttConnectionStatus`.
enum MqttConnectionStatus { disconnected, connecting, connected, error }

/// Immutable snapshot of the MQTT service state.
class MqttState {
  /// The current connection state.
  final MqttConnectionStatus connectionState;

  /// Error message when [connectionState] is [MqttConnectionStatus.error].
  final String? errorMessage;

  /// Timestamp when the connection was established.
  final DateTime? connectedAt;

  /// Number of MQTT messages received since connection.
  final int messagesReceived;

  /// Creates an [MqttState].
  const MqttState({
    this.connectionState = MqttConnectionStatus.disconnected,
    this.errorMessage,
    this.connectedAt,
    this.messagesReceived = 0,
  });

  /// Creates a copy with the given fields replaced.
  MqttState copyWith({
    MqttConnectionStatus? connectionState,
    String? errorMessage,
    DateTime? connectedAt,
    int? messagesReceived,
  }) {
    return MqttState(
      connectionState: connectionState ?? this.connectionState,
      errorMessage: errorMessage,
      connectedAt: connectedAt ?? this.connectedAt,
      messagesReceived: messagesReceived ?? this.messagesReceived,
    );
  }
}

/// Manages the MQTT connection to the MyOffGridAI server's Mosquitto broker.
///
/// On Android, the connection is maintained by a foreground service, allowing
/// notifications to be received when the app is backgrounded. On iOS, the
/// connection is active only while the app is in the foreground — this is an
/// Apple platform limitation with no sanctioned workaround.
///
/// Subscribes to:
/// - `/myoffgridai/{userId}/notifications` — user-specific topic
/// - `/myoffgridai/broadcast` — server-wide broadcasts
///
/// Incoming messages are deserialized as [NotificationModel] and passed to
/// [LocalNotificationService] for display, and to [NotificationService] to
/// trigger a refresh of the notifications list.
class MqttServiceNotifier extends StateNotifier<MqttState> {
  final Ref _ref;
  MqttServerClient? _client;
  Timer? _reconnectTimer;
  String? _userId;
  StreamSubscription? _messageSubscription;

  /// Creates an [MqttServiceNotifier].
  MqttServiceNotifier(this._ref) : super(const MqttState());

  /// Initiates an MQTT connection and subscribes to the user's notification topics.
  ///
  /// Derives the broker host from the stored server URL. Generates a unique
  /// client ID from the stored device ID.
  Future<void> connect(String userId) async {
    if (state.connectionState == MqttConnectionStatus.connecting ||
        state.connectionState == MqttConnectionStatus.connected) {
      return;
    }

    _userId = userId;
    state = state.copyWith(connectionState: MqttConnectionStatus.connecting);

    try {
      final storage = _ref.read(secureStorageProvider);
      final serverUrl = await storage.getServerUrl();
      final host = Uri.parse(serverUrl).host;
      final deviceId = await _getOrCreateDeviceId(storage);
      final clientId = '${AppConstants.mqttClientIdPrefix}$deviceId';

      _client = MqttServerClient(host, clientId)
        ..port = AppConstants.mqttPort
        ..keepAlivePeriod = AppConstants.mqttKeepAliveSeconds
        ..autoReconnect = true
        ..onDisconnected = _onDisconnected
        ..onConnected = _onConnected
        ..onAutoReconnect = _onAutoReconnect
        ..logging(on: kDebugMode);

      final connMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .startClean();
      _client!.connectionMessage = connMessage;

      await _client!.connect();

      if (_client!.connectionStatus?.state ==
          MqttConnectionState.connected) {
        _subscribe(userId);
        _listenForMessages();
        state = MqttState(
          connectionState: MqttConnectionStatus.connected,
          connectedAt: DateTime.now(),
        );
      } else {
        state = state.copyWith(
          connectionState: MqttConnectionStatus.error,
          errorMessage: 'Connection failed',
        );
        _scheduleReconnect();
      }
    } catch (e) {
      LogService.instance.error('MQTT', 'Connect error', e);
      state = state.copyWith(
        connectionState: MqttConnectionStatus.error,
        errorMessage: e.toString(),
      );
      _scheduleReconnect();
    }
  }

  /// Cleanly disconnects from the broker and cancels reconnect timers.
  void disconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _messageSubscription?.cancel();
    _messageSubscription = null;
    _userId = null;

    if (_client != null) {
      _client!.autoReconnect = false;
      _client!.disconnect();
      _client = null;
    }

    state = const MqttState();
  }

  void _subscribe(String userId) {
    final userTopic = '${AppConstants.mqttTopicPrefix}$userId/notifications';
    _client!.subscribe(userTopic, MqttQos.atLeastOnce);
    _client!.subscribe(AppConstants.mqttBroadcastTopic, MqttQos.atLeastOnce);
    LogService.instance.info('MQTT', 'Subscribed: $userTopic, ${AppConstants.mqttBroadcastTopic}');
  }

  void _listenForMessages() {
    _messageSubscription?.cancel();
    _messageSubscription =
        _client!.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      for (final msg in c) {
        final payload = msg.payload as MqttPublishMessage;
        final text = MqttPublishPayload.bytesToStringAsString(
            payload.payload.message);
        _handleMessage(text);
      }
    });
  }

  void _handleMessage(String jsonText) {
    try {
      final json = jsonDecode(jsonText) as Map<String, dynamic>;
      final notification = NotificationModel(
        id: json['notificationId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        type: json['type'] as String? ?? 'GENERAL',
        severity: json['severity'] as String? ?? 'INFO',
        isRead: false,
        createdAt: json['timestamp'] as String?,
      );

      state = state.copyWith(messagesReceived: state.messagesReceived + 1);

      // Show local notification
      try {
        final localService = _ref.read(localNotificationServiceProvider);
        localService.showAlertNotification(notification);
      } catch (e) {
        LogService.instance.error('MQTT', 'Failed to show notification', e);
      }

      // Refresh notification list
      try {
        _ref.invalidate(notificationsProvider);
      } catch (e) {
        LogService.instance.error('MQTT', 'Failed to invalidate notifications', e);
      }
    } catch (e) {
      LogService.instance.error('MQTT', 'Message parse error', e);
    }
  }

  void _onConnected() {
    LogService.instance.info('MQTT', 'Connected');
    state = MqttState(
      connectionState: MqttConnectionStatus.connected,
      connectedAt: DateTime.now(),
      messagesReceived: state.messagesReceived,
    );
  }

  void _onDisconnected() {
    LogService.instance.info('MQTT', 'Disconnected');
    if (_userId != null) {
      state = state.copyWith(
        connectionState: MqttConnectionStatus.disconnected,
      );
      _scheduleReconnect();
    }
  }

  void _onAutoReconnect() {
    LogService.instance.info('MQTT', 'Auto-reconnecting');
    state = state.copyWith(connectionState: MqttConnectionStatus.connecting);
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    if (_userId == null) return;
    _reconnectTimer = Timer(AppConstants.mqttReconnectDelay, () {
      if (_userId != null) {
        connect(_userId!);
      }
    });
  }

  Future<String> _getOrCreateDeviceId(SecureStorageService storage) async {
    final existing = await storage.getDeviceId();
    if (existing != null) return existing;

    // Generate a short unique ID from timestamp
    final id = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    await storage.saveDeviceId(id);
    return id;
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}

/// Riverpod provider for the MQTT service state.
final mqttServiceProvider =
    StateNotifierProvider<MqttServiceNotifier, MqttState>((ref) {
  return MqttServiceNotifier(ref);
});
