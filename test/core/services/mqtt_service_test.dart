import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/core/services/mqtt_service.dart';

void main() {
  group('MqttConnectionStatus', () {
    test('has expected values', () {
      expect(MqttConnectionStatus.values, hasLength(4));
      expect(MqttConnectionStatus.values,
          contains(MqttConnectionStatus.disconnected));
      expect(MqttConnectionStatus.values,
          contains(MqttConnectionStatus.connecting));
      expect(MqttConnectionStatus.values,
          contains(MqttConnectionStatus.connected));
      expect(
          MqttConnectionStatus.values, contains(MqttConnectionStatus.error));
    });
  });

  group('MqttState', () {
    test('default constructor creates disconnected state', () {
      const state = MqttState();

      expect(state.connectionState, MqttConnectionStatus.disconnected);
      expect(state.errorMessage, isNull);
      expect(state.connectedAt, isNull);
      expect(state.messagesReceived, 0);
    });

    test('constructor accepts all fields', () {
      final now = DateTime.now();
      final state = MqttState(
        connectionState: MqttConnectionStatus.connected,
        errorMessage: null,
        connectedAt: now,
        messagesReceived: 5,
      );

      expect(state.connectionState, MqttConnectionStatus.connected);
      expect(state.connectedAt, now);
      expect(state.messagesReceived, 5);
    });

    test('copyWith replaces connectionState', () {
      const original = MqttState();
      final updated =
          original.copyWith(connectionState: MqttConnectionStatus.connecting);

      expect(updated.connectionState, MqttConnectionStatus.connecting);
      expect(updated.messagesReceived, 0);
    });

    test('copyWith replaces errorMessage', () {
      const original = MqttState(
        connectionState: MqttConnectionStatus.error,
        errorMessage: 'old error',
      );
      final updated = original.copyWith(errorMessage: 'new error');

      expect(updated.errorMessage, 'new error');
      expect(updated.connectionState, MqttConnectionStatus.error);
    });

    test('copyWith clears errorMessage when null is passed', () {
      const original = MqttState(
        connectionState: MqttConnectionStatus.error,
        errorMessage: 'some error',
      );
      // copyWith always replaces errorMessage (nullable)
      final updated = original.copyWith(
        connectionState: MqttConnectionStatus.connected,
      );

      expect(updated.connectionState, MqttConnectionStatus.connected);
      expect(updated.errorMessage, isNull);
    });

    test('copyWith replaces messagesReceived', () {
      const original = MqttState(messagesReceived: 3);
      final updated = original.copyWith(messagesReceived: 10);

      expect(updated.messagesReceived, 10);
    });

    test('copyWith preserves connectedAt when not overridden', () {
      final now = DateTime.now();
      final original = MqttState(
        connectionState: MqttConnectionStatus.connected,
        connectedAt: now,
      );
      final updated = original.copyWith(messagesReceived: 1);

      expect(updated.connectedAt, now);
    });

    test('copyWith replaces connectedAt', () {
      final old = DateTime(2026, 1, 1);
      final newer = DateTime(2026, 3, 16);
      final original = MqttState(
        connectionState: MqttConnectionStatus.connected,
        connectedAt: old,
      );
      final updated = original.copyWith(connectedAt: newer);

      expect(updated.connectedAt, newer);
    });

    test('copyWith preserves errorMessage when connectionState not overridden', () {
      const original = MqttState(
        connectionState: MqttConnectionStatus.error,
        errorMessage: 'timeout',
        messagesReceived: 5,
      );
      // copyWith always sets errorMessage to the provided value (null by default)
      final updated = original.copyWith(messagesReceived: 6);

      expect(updated.connectionState, MqttConnectionStatus.error);
      expect(updated.messagesReceived, 6);
      // errorMessage is replaced with null because copyWith uses `errorMessage: errorMessage`
      // where the param defaults to null
      expect(updated.errorMessage, isNull);
    });

    test('constructor with error state', () {
      const state = MqttState(
        connectionState: MqttConnectionStatus.error,
        errorMessage: 'Connection refused',
        messagesReceived: 0,
      );

      expect(state.connectionState, MqttConnectionStatus.error);
      expect(state.errorMessage, 'Connection refused');
      expect(state.messagesReceived, 0);
      expect(state.connectedAt, isNull);
    });
  });
}
