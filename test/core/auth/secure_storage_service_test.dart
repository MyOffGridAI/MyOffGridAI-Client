import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/core/auth/secure_storage_service.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late SecureStorageService service;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    service = SecureStorageService(storage: mockStorage);
  });

  // ── saveTokens ─────────────────────────────────────────────────────────
  group('saveTokens', () {
    test('writes both tokens to storage and caches them', () async {
      when(() => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async {});

      await service.saveTokens(
        accessToken: 'access-123',
        refreshToken: 'refresh-456',
      );

      verify(() => mockStorage.write(
            key: AppConstants.accessTokenKey,
            value: 'access-123',
          )).called(1);
      verify(() => mockStorage.write(
            key: AppConstants.refreshTokenKey,
            value: 'refresh-456',
          )).called(1);

      // Verify cached — subsequent reads should return without storage call
      final access = await service.getAccessToken();
      final refresh = await service.getRefreshToken();
      expect(access, 'access-123');
      expect(refresh, 'refresh-456');
    });

    test('caches tokens even when storage write throws', () async {
      when(() => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenThrow(Exception('Write failed'));

      await service.saveTokens(
        accessToken: 'access-cached',
        refreshToken: 'refresh-cached',
      );

      final access = await service.getAccessToken();
      expect(access, 'access-cached');
    });
  });

  // ── getAccessToken ─────────────────────────────────────────────────────
  group('getAccessToken', () {
    test('returns cached value without reading storage', () async {
      when(() => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async {});

      await service.saveTokens(
        accessToken: 'cached-access',
        refreshToken: 'cached-refresh',
      );

      final result = await service.getAccessToken();

      expect(result, 'cached-access');
      verifyNever(() => mockStorage.read(key: AppConstants.accessTokenKey));
    });

    test('reads from storage when no cache and caches result', () async {
      when(() => mockStorage.read(key: AppConstants.accessTokenKey))
          .thenAnswer((_) async => 'stored-access');

      final result = await service.getAccessToken();

      expect(result, 'stored-access');
      verify(() => mockStorage.read(key: AppConstants.accessTokenKey))
          .called(1);

      // Second call should use cache
      final result2 = await service.getAccessToken();
      expect(result2, 'stored-access');
      // Still only 1 read call
      verifyNever(() => mockStorage.read(key: AppConstants.accessTokenKey));
    });

    test('returns null when storage read returns null', () async {
      when(() => mockStorage.read(key: AppConstants.accessTokenKey))
          .thenAnswer((_) async => null);

      final result = await service.getAccessToken();

      expect(result, isNull);
    });

    test('returns null when storage read throws', () async {
      when(() => mockStorage.read(key: AppConstants.accessTokenKey))
          .thenThrow(Exception('Read failed'));

      final result = await service.getAccessToken();

      expect(result, isNull);
    });
  });

  // ── getRefreshToken ────────────────────────────────────────────────────
  group('getRefreshToken', () {
    test('returns cached value without reading storage', () async {
      when(() => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async {});

      await service.saveTokens(
        accessToken: 'access',
        refreshToken: 'cached-refresh',
      );

      final result = await service.getRefreshToken();

      expect(result, 'cached-refresh');
    });

    test('reads from storage when no cache', () async {
      when(() => mockStorage.read(key: AppConstants.refreshTokenKey))
          .thenAnswer((_) async => 'stored-refresh');

      final result = await service.getRefreshToken();

      expect(result, 'stored-refresh');
    });

    test('returns null when storage read returns null', () async {
      when(() => mockStorage.read(key: AppConstants.refreshTokenKey))
          .thenAnswer((_) async => null);

      final result = await service.getRefreshToken();

      expect(result, isNull);
    });

    test('returns null when storage read throws', () async {
      when(() => mockStorage.read(key: AppConstants.refreshTokenKey))
          .thenThrow(Exception('Read failed'));

      final result = await service.getRefreshToken();

      expect(result, isNull);
    });
  });

  // ── clearTokens ────────────────────────────────────────────────────────
  group('clearTokens', () {
    test('removes both tokens from cache and storage', () async {
      when(() => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async {});
      when(() => mockStorage.delete(key: any(named: 'key')))
          .thenAnswer((_) async {});
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);

      // First save tokens so they're cached
      await service.saveTokens(
        accessToken: 'to-delete-access',
        refreshToken: 'to-delete-refresh',
      );

      await service.clearTokens();

      verify(() => mockStorage.delete(key: AppConstants.accessTokenKey))
          .called(1);
      verify(() => mockStorage.delete(key: AppConstants.refreshTokenKey))
          .called(1);

      // Cache should be cleared — reading should go to storage
      final access = await service.getAccessToken();
      expect(access, isNull);
    });

    test('clears cache even when storage delete throws', () async {
      when(() => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async {});
      when(() => mockStorage.delete(key: any(named: 'key')))
          .thenThrow(Exception('Delete failed'));
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);

      await service.saveTokens(
        accessToken: 'cached',
        refreshToken: 'cached',
      );

      await service.clearTokens();

      // Cache should be cleared even though storage throw
      final access = await service.getAccessToken();
      expect(access, isNull);
    });
  });

  // ── saveServerUrl / getServerUrl ───────────────────────────────────────
  group('saveServerUrl / getServerUrl', () {
    test('saves and retrieves from cache', () async {
      when(() => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async {});

      await service.saveServerUrl('http://192.168.1.100:8080');

      final result = await service.getServerUrl();
      expect(result, 'http://192.168.1.100:8080');
    });

    test('reads from storage when no cache', () async {
      when(() => mockStorage.read(key: AppConstants.serverUrlKey))
          .thenAnswer((_) async => 'http://stored.url:8080');

      final result = await service.getServerUrl();
      expect(result, 'http://stored.url:8080');
    });

    test('returns default URL when storage read returns null', () async {
      when(() => mockStorage.read(key: AppConstants.serverUrlKey))
          .thenAnswer((_) async => null);

      final result = await service.getServerUrl();
      expect(result, AppConstants.defaultServerUrl);
    });

    test('returns default URL when storage read throws', () async {
      when(() => mockStorage.read(key: AppConstants.serverUrlKey))
          .thenThrow(Exception('Read failed'));

      final result = await service.getServerUrl();
      expect(result, AppConstants.defaultServerUrl);
    });

    test('caches value even when storage write throws', () async {
      when(() => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenThrow(Exception('Write failed'));

      await service.saveServerUrl('http://cached-only:8080');

      final result = await service.getServerUrl();
      expect(result, 'http://cached-only:8080');
    });
  });

  // ── saveThemePreference / getThemePreference ───────────────────────────
  group('saveThemePreference / getThemePreference', () {
    test('saves and retrieves from cache', () async {
      when(() => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async {});

      await service.saveThemePreference('dark');

      final result = await service.getThemePreference();
      expect(result, 'dark');
    });

    test('reads from storage when no cache', () async {
      when(() => mockStorage.read(key: AppConstants.themeKey))
          .thenAnswer((_) async => 'light');

      final result = await service.getThemePreference();
      expect(result, 'light');
    });

    test('returns system when storage read returns null', () async {
      when(() => mockStorage.read(key: AppConstants.themeKey))
          .thenAnswer((_) async => null);

      final result = await service.getThemePreference();
      expect(result, 'system');
    });

    test('returns system when storage read throws', () async {
      when(() => mockStorage.read(key: AppConstants.themeKey))
          .thenThrow(Exception('Read failed'));

      final result = await service.getThemePreference();
      expect(result, 'system');
    });

    test('caches value even when storage write throws', () async {
      when(() => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenThrow(Exception('Write failed'));

      await service.saveThemePreference('light');

      final result = await service.getThemePreference();
      expect(result, 'light');
    });
  });

  // ── saveDeviceId / getDeviceId ─────────────────────────────────────────
  group('saveDeviceId / getDeviceId', () {
    test('saves and retrieves from cache', () async {
      when(() => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async {});

      await service.saveDeviceId('device-abc');

      final result = await service.getDeviceId();
      expect(result, 'device-abc');
    });

    test('reads from storage when no cache', () async {
      when(() => mockStorage.read(key: AppConstants.deviceIdKey))
          .thenAnswer((_) async => 'stored-device-id');

      final result = await service.getDeviceId();
      expect(result, 'stored-device-id');
    });

    test('returns null when storage read returns null', () async {
      when(() => mockStorage.read(key: AppConstants.deviceIdKey))
          .thenAnswer((_) async => null);

      final result = await service.getDeviceId();
      expect(result, isNull);
    });

    test('returns null when storage read throws', () async {
      when(() => mockStorage.read(key: AppConstants.deviceIdKey))
          .thenThrow(Exception('Read failed'));

      final result = await service.getDeviceId();
      expect(result, isNull);
    });

    test('caches value even when storage write throws', () async {
      when(() => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenThrow(Exception('Write failed'));

      await service.saveDeviceId('cached-device');

      final result = await service.getDeviceId();
      expect(result, 'cached-device');
    });
  });

  // ── writeValue / readValue / deleteValue ─────────────────────────────
  group('writeValue / readValue', () {
    test('writes value and retrieves from cache', () async {
      when(() => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async {});

      await service.writeValue('custom_key', 'custom_value');

      final result = await service.readValue('custom_key');
      expect(result, 'custom_value');
    });

    test('reads from storage when no cache and caches result', () async {
      when(() => mockStorage.read(key: 'no_cache_key'))
          .thenAnswer((_) async => 'stored_value');

      final result = await service.readValue('no_cache_key');
      expect(result, 'stored_value');

      verify(() => mockStorage.read(key: 'no_cache_key')).called(1);

      // Second call should use cache
      final result2 = await service.readValue('no_cache_key');
      expect(result2, 'stored_value');
    });

    test('returns null when storage read returns null', () async {
      when(() => mockStorage.read(key: 'missing_key'))
          .thenAnswer((_) async => null);

      final result = await service.readValue('missing_key');
      expect(result, isNull);
    });

    test('returns null when storage read throws', () async {
      when(() => mockStorage.read(key: 'error_key'))
          .thenThrow(Exception('Read failed'));

      final result = await service.readValue('error_key');
      expect(result, isNull);
    });

    test('caches value even when storage write throws', () async {
      when(() => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenThrow(Exception('Write failed'));

      await service.writeValue('fail_write_key', 'cached_value');

      final result = await service.readValue('fail_write_key');
      expect(result, 'cached_value');
    });
  });

  group('deleteValue', () {
    test('removes value from cache and storage', () async {
      when(() => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async {});
      when(() => mockStorage.delete(key: any(named: 'key')))
          .thenAnswer((_) async {});
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);

      await service.writeValue('del_key', 'del_value');
      await service.deleteValue('del_key');

      verify(() => mockStorage.delete(key: 'del_key')).called(1);

      final result = await service.readValue('del_key');
      expect(result, isNull);
    });

    test('clears cache even when storage delete throws', () async {
      when(() => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async {});
      when(() => mockStorage.delete(key: any(named: 'key')))
          .thenThrow(Exception('Delete failed'));
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);

      await service.writeValue('del_fail_key', 'value');
      await service.deleteValue('del_fail_key');

      final result = await service.readValue('del_fail_key');
      expect(result, isNull);
    });
  });

  // ── Provider body tests ───────────────────────────────────────────────
  group('secureStorageProvider', () {
    test('creates SecureStorageService with default constructor', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final storage = container.read(secureStorageProvider);
      expect(storage, isA<SecureStorageService>());
    });
  });
}
