import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'config/theme/app_colors.dart';
import 'core/config/api_config.dart';
import 'core/services/api_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/storage_service.dart';
import 'firebase_options.dart';
import 'providers/providers.dart';
import 'routes/app_routes.dart';

/// Global navigator key for navigation from notifications
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Flag to prevent multiple logout calls
bool _isLoggingOut = false;

/// Background FCM handler. Must be a top-level function and annotated with
/// `@pragma('vm:entry-point')` so it survives tree-shaking in release.
///
/// Firebase auto-displays messages with a `notification` payload while the
/// app is in the background, so we only need to make sure the Firebase app
/// is initialized for the isolate.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

/// Dev-only HTTP overrides.
///
/// `dev.maicafeuk.com` is served behind a shared-hosting certificate
/// (CN=*.web-hosting.com) that does not match the host, so the default TLS
/// validation rejects it. We trust it ONLY for the dev host. This must never
/// reach production — guarded by [ApiConfig.isDev].
class _DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) =>
              host == ApiConfig.host;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Trust the dev backend's mismatched TLS certificate (dev only).
  if (ApiConfig.isDev) {
    HttpOverrides.global = _DevHttpOverrides();
  }

  // Initialize storage service
  await StorageService.init();

  // Initialize Firebase before any plugin that depends on it.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Register the background handler before the app starts so messages
  // delivered while the process is suspended can still be processed.
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize local notifications + FCM handlers.
  await NotificationService.instance.init();
  await NotificationService.instance.initFcm();

  // Set up API service unauthorized callback for auto-logout on token expiry
  ApiService.onUnauthorized = _handleUnauthorized;

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const McCafeApp());
}

/// Handle unauthorized (401) response - logout user and navigate to login
void _handleUnauthorized() async {
  // Prevent multiple logout calls
  if (_isLoggingOut) return;
  _isLoggingOut = true;

  // Clear auth data
  await StorageService.instance.clearAuthData();

  // Navigate to login screen
  navigatorKey.currentState?.pushNamedAndRemoveUntil(
    AppRoutes.login,
    (route) => false,
  );

  // Reset flag after a short delay
  Future.delayed(const Duration(seconds: 2), () {
    _isLoggingOut = false;
  });
}

class McCafeApp extends StatelessWidget {
  const McCafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()..init()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'MAICAFE',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            secondary: AppColors.accent,
            surface: AppColors.surface,
            error: AppColors.error,
          ),
          scaffoldBackgroundColor: AppColors.background,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: AppColors.black),
            titleTextStyle: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          useMaterial3: true,
        ),
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}
