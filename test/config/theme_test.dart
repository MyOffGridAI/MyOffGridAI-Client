import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/config/theme.dart';
import 'package:myoffgridai_client/core/auth/secure_storage_service.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  // ── AppColors ──────────────────────────────────────────────────────────
  group('AppColors', () {
    test('primary colors are defined', () {
      expect(AppColors.primary, isA<Color>());
      expect(AppColors.primaryContainer, isA<Color>());
      expect(AppColors.secondary, isA<Color>());
    });

    test('background colors are defined', () {
      expect(AppColors.backgroundDark, isA<Color>());
      expect(AppColors.backgroundLight, isA<Color>());
    });

    test('surface colors are defined', () {
      expect(AppColors.surfaceDark, isA<Color>());
      expect(AppColors.surfaceLight, isA<Color>());
    });

    test('error and onPrimary are defined', () {
      expect(AppColors.error, isA<Color>());
      expect(AppColors.onPrimary, isA<Color>());
    });
  });

  // ── lightTheme ─────────────────────────────────────────────────────────
  group('lightTheme', () {
    test('uses Material 3', () {
      expect(lightTheme.useMaterial3, isTrue);
    });

    test('has light brightness', () {
      expect(lightTheme.brightness, Brightness.light);
    });

    test('uses correct scaffold background', () {
      expect(lightTheme.scaffoldBackgroundColor, AppColors.backgroundLight);
    });

    test('card theme has rounded corners', () {
      expect(lightTheme.cardTheme.shape, isA<RoundedRectangleBorder>());
    });

    test('app bar has zero elevation', () {
      expect(lightTheme.appBarTheme.elevation, 0);
      expect(lightTheme.appBarTheme.scrolledUnderElevation, 0);
    });

    test('input decoration is filled', () {
      expect(lightTheme.inputDecorationTheme.filled, isTrue);
      expect(lightTheme.inputDecorationTheme.fillColor, AppColors.surfaceLight);
    });

    test('elevated button has minimum size', () {
      final style = lightTheme.elevatedButtonTheme.style;
      expect(style, isNotNull);
    });

    test('list tile theme is configured', () {
      expect(lightTheme.listTileTheme.leadingAndTrailingTextStyle, isNotNull);
    });
  });

  // ── darkTheme ──────────────────────────────────────────────────────────
  group('darkTheme', () {
    test('uses Material 3', () {
      expect(darkTheme.useMaterial3, isTrue);
    });

    test('has dark brightness', () {
      expect(darkTheme.brightness, Brightness.dark);
    });

    test('uses correct scaffold background', () {
      expect(darkTheme.scaffoldBackgroundColor, AppColors.backgroundDark);
    });

    test('card theme has rounded corners', () {
      expect(darkTheme.cardTheme.shape, isA<RoundedRectangleBorder>());
    });

    test('app bar has zero elevation', () {
      expect(darkTheme.appBarTheme.elevation, 0);
      expect(darkTheme.appBarTheme.scrolledUnderElevation, 0);
    });

    test('input decoration is filled with dark surface', () {
      expect(darkTheme.inputDecorationTheme.filled, isTrue);
      expect(darkTheme.inputDecorationTheme.fillColor, AppColors.surfaceDark);
    });

    test('elevated button has minimum size', () {
      final style = darkTheme.elevatedButtonTheme.style;
      expect(style, isNotNull);
    });

    test('list tile theme is configured', () {
      expect(darkTheme.listTileTheme.leadingAndTrailingTextStyle, isNotNull);
    });
  });

  // ── ThemeNotifier ──────────────────────────────────────────────────────
  group('ThemeNotifier', () {
    late MockSecureStorageService mockStorage;

    setUp(() {
      mockStorage = MockSecureStorageService();
    });

    test('initial state defaults to ThemeMode.system', () {
      when(() => mockStorage.getThemePreference())
          .thenAnswer((_) async => 'system');

      final notifier = ThemeNotifier(mockStorage);

      expect(notifier.state, ThemeMode.system);
    });

    test('loads light theme preference from storage', () async {
      when(() => mockStorage.getThemePreference())
          .thenAnswer((_) async => 'light');

      final notifier = ThemeNotifier(mockStorage);

      // Wait for _loadPreference to complete
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state, ThemeMode.light);
    });

    test('loads dark theme preference from storage', () async {
      when(() => mockStorage.getThemePreference())
          .thenAnswer((_) async => 'dark');

      final notifier = ThemeNotifier(mockStorage);

      await Future<void>.delayed(Duration.zero);

      expect(notifier.state, ThemeMode.dark);
    });

    test('loads unknown preference as system', () async {
      when(() => mockStorage.getThemePreference())
          .thenAnswer((_) async => 'auto');

      final notifier = ThemeNotifier(mockStorage);

      await Future<void>.delayed(Duration.zero);

      expect(notifier.state, ThemeMode.system);
    });

    test('setThemeMode updates state and saves to storage', () async {
      when(() => mockStorage.getThemePreference())
          .thenAnswer((_) async => 'system');
      when(() => mockStorage.saveThemePreference(any()))
          .thenAnswer((_) async {});

      final notifier = ThemeNotifier(mockStorage);
      await Future<void>.delayed(Duration.zero);

      await notifier.setThemeMode(ThemeMode.dark);

      expect(notifier.state, ThemeMode.dark);
      verify(() => mockStorage.saveThemePreference('dark')).called(1);
    });

    test('setThemeMode saves light string for light mode', () async {
      when(() => mockStorage.getThemePreference())
          .thenAnswer((_) async => 'system');
      when(() => mockStorage.saveThemePreference(any()))
          .thenAnswer((_) async {});

      final notifier = ThemeNotifier(mockStorage);
      await Future<void>.delayed(Duration.zero);

      await notifier.setThemeMode(ThemeMode.light);

      expect(notifier.state, ThemeMode.light);
      verify(() => mockStorage.saveThemePreference('light')).called(1);
    });

    test('setThemeMode saves system string for system mode', () async {
      when(() => mockStorage.getThemePreference())
          .thenAnswer((_) async => 'dark');
      when(() => mockStorage.saveThemePreference(any()))
          .thenAnswer((_) async {});

      final notifier = ThemeNotifier(mockStorage);
      await Future<void>.delayed(Duration.zero);

      await notifier.setThemeMode(ThemeMode.system);

      expect(notifier.state, ThemeMode.system);
      verify(() => mockStorage.saveThemePreference('system')).called(1);
    });
  });
}
