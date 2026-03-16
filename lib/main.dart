import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/config/router.dart';
import 'package:myoffgridai_client/config/theme.dart';
import 'package:myoffgridai_client/core/api/myoffgridai_api_client.dart';
import 'package:myoffgridai_client/core/auth/secure_storage_service.dart';
import 'package:myoffgridai_client/core/services/local_notification_service.dart';

/// Entry point for the MyOffGridAI client application.
///
/// Initializes secure storage, resolves the server URL, creates the
/// API client, initializes local notifications, and launches the app
/// within a [ProviderScope].
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = SecureStorageService();
  final serverUrl = await storage.getServerUrl();

  // Initialize local notifications before runApp
  final localNotifications = LocalNotificationService();
  await localNotifications.initialize();

  runApp(
    ProviderScope(
      overrides: [
        secureStorageProvider.overrideWithValue(storage),
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
