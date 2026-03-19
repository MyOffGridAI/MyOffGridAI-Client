import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// MyOffGridAI brand color palette.
///
/// Earth-toned colors reflecting the off-grid, nature-connected identity.
class AppColors {
  AppColors._();

  /// Primary forest green used for main actions and branding.
  static const Color primary = Color(0xFF2D5016);
  /// Lighter green for primary container surfaces and filled backgrounds.
  static const Color primaryContainer = Color(0xFF4A7C2F);
  /// Warm amber-brown secondary accent for complementary UI elements.
  static const Color secondary = Color(0xFF8B5E1A);
  /// Deep olive-black scaffold background for dark mode.
  static const Color backgroundDark = Color(0xFF1A1A14);
  /// Warm parchment scaffold background for light mode.
  static const Color backgroundLight = Color(0xFFF5F0E8);
  /// Dark olive surface color for cards and elevated containers in dark mode.
  static const Color surfaceDark = Color(0xFF242418);
  /// White surface color for cards and elevated containers in light mode.
  static const Color surfaceLight = Color(0xFFFFFFFF);
  /// Muted rose used for error states and destructive actions.
  static const Color error = Color(0xFFCF6679);
  /// White text and icon color used on primary-colored surfaces.
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

/// Manages the current [ThemeMode] as a simple state holder.
///
/// Theme is persisted server-side in user_settings. The server is the
/// source of truth; this notifier just holds the in-memory state.
class ThemeNotifier extends StateNotifier<ThemeMode> {
  /// Creates a [ThemeNotifier] with the default system theme.
  ThemeNotifier() : super(ThemeMode.system);

  /// Sets the current theme mode.
  void setThemeMode(ThemeMode mode) {
    state = mode;
  }
}

/// Converts a theme preference string to a [ThemeMode].
ThemeMode themeModeFromString(String value) {
  switch (value) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
}

/// Converts a [ThemeMode] to a theme preference string.
String themeModeToString(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:
      return 'light';
    case ThemeMode.dark:
      return 'dark';
    case ThemeMode.system:
      return 'system';
  }
}

/// Riverpod provider for the [ThemeNotifier].
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});
