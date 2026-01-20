import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'config/theme/app_colors.dart';
import 'core/services/storage_service.dart';
import 'providers/providers.dart';
import 'routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage service
  await StorageService.init();

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const McCafeApp());
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
      ],
      child: MaterialApp(
        title: 'MC Cafe',
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
