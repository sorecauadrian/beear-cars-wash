import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'core/config/firebase_config.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  // This will work once you add the config files (see docs/FIREBASE_SETUP.md)
  try {
    await FirebaseConfig.initialize();
    
    // Initialize notification service
    await NotificationService().initialize();
  } catch (e) {
    // If Firebase fails to initialize, the app will still run
    // but Firebase features won't work. This allows development
    // before Firebase is set up.
    debugPrint('Warning: Firebase not initialized. Add config files to enable Firebase features.');
  }
  
  runApp(
    const ProviderScope(
      child: BeearCarsWashApp(),
    ),
  );
}

class BeearCarsWashApp extends StatelessWidget {
  const BeearCarsWashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Beear Cars Wash',
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('ro', 'RO'),
      ],
      locale: const Locale('ro', 'RO'),
    );
  }
}
