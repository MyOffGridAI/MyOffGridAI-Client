import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/core/auth/secure_storage_service.dart';

/// MyOffGridAI brand color palette.
///
/// Earth-toned colors reflecting the off-grid, nature-connected identity.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF2D5016);
  static const Color primaryContainer = Color(0xFF4A7C2F);
  static const Color secondary = Color(0xFF8B5E1A);
  static const Color backgroundDark = Color(0xFF1A1A14);
  static const Color backgroundLight = Color(0xFFF5F0E8);
  static const Color surfaceDark = Color(0xFF242418);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFCF6679);
  static const Color onPrimary = Color(0xFFFFFFFF);
}

/// Light theme for MyOffGridAI.
final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
    surface: AppColors.surfaceLight,
    error: AppColors.error,
  ),
  scaffoldBackgroundColor: AppColors.backgroundLight,
  cardTheme: const CardThemeData(
    elevation: 1,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  ),
  appBarTheme: const AppBarTheme(
    elevation: 0,
    scrolledUnderElevation: 0,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surfaceLight,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      minimumSize: const Size(double.infinity, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
  listTileTheme: const ListTileThemeData(
    leadingAndTrailingTextStyle: TextStyle(fontSize: 16),
  ),
);

/// Dark theme for MyOffGridAI.
final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.dark,
    surface: AppColors.surfaceDark,
    error: AppColors.error,
  ),
  scaffoldBackgroundColor: AppColors.backgroundDark,
  cardTheme: const CardThemeData(
    elevation: 1,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  ),
  appBarTheme: const AppBarTheme(
    elevation: 0,
    scrolledUnderElevation: 0,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surfaceDark,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      minimumSize: const Size(double.infinity, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
  listTileTheme: const ListTileThemeData(
    leadingAndTrailingTextStyle: TextStyle(fontSize: 16),
  ),
);

/// Manages the current [ThemeMode] and persists preference to secure storage.
class ThemeNotifier extends StateNotifier<ThemeMode> {
  final SecureStorageService _storage;

  /// Creates a [ThemeNotifier] with the given [SecureStorageService].
  ThemeNotifier(this._storage) : super(ThemeMode.system) {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final pref = await _storage.getThemePreference();
    state = _fromString(pref);
  }

  /// Sets the theme mode and persists the preference.
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _storage.saveThemePreference(_toString(mode));
  }

  ThemeMode _fromString(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _toString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}

/// Riverpod provider for the [ThemeNotifier].
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ThemeNotifier(storage);
});
