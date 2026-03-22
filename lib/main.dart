import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/config/router.dart';
import 'package:myoffgridai_client/config/theme.dart';
import 'package:myoffgridai_client/core/api/myoffgridai_api_client.dart';
import 'package:myoffgridai_client/core/auth/secure_storage_service.dart';
import 'package:myoffgridai_client/core/services/local_notification_service.dart';
import 'package:myoffgridai_client/core/services/log_service.dart';
import 'package:myoffgridai_client/core/services/window_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Entry point for the MyOffGridAI client application.
///
/// Initializes secure storage, resolves the server URL, creates the
/// API client, initializes local notifications, and launches the app
/// within a [ProviderScope].
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final logService = LogService();
  await logService.initialize();

  final storage = SecureStorageService();
  final serverUrl = await storage.getServerUrl();

  // Restore window geometry before the window is shown (macOS only)
  WindowService? windowService;
  if (WindowService.isSupported) {
    final prefs = await SharedPreferences.getInstance();
    windowService = WindowService(prefs: prefs, log: logService);
    await windowService.initialize();
  }

  // Initialize local notifications before runApp
  final localNotifications = LocalNotificationService();
  await localNotifications.initialize();

  runApp(
    ProviderScope(
      overrides: [
        logServiceProvider.overrideWithValue(logService),
        secureStorageProvider.overrideWithValue(storage),
        if (windowService != null)
          windowServiceProvider.overrideWithValue(windowService),
        localNotificationServiceProvider
            .overrideWithValue(localNotifications),
        apiClientProvider.overrideWith((ref) {
          return MyOffGridAIApiClient(
            baseUrl: serverUrl,
            storage: storage,
            ref: ref,
          );
        }),
      ],
      child: const MyOffGridAIApp(),
    ),
  );
}

/// Root widget for the MyOffGridAI application.
///
/// Configures [MaterialApp.router] with the brand theme, dark mode support,
/// and GoRouter navigation.
class MyOffGridAIApp extends ConsumerWidget {
  /// Creates a [MyOffGridAIApp].
  const MyOffGridAIApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'MyOffGrid AI',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
    );
  }
}
