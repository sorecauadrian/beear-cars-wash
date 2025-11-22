import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // TODO: Initialize Firebase when config files are added
  // await Firebase.initializeApp();
  
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
    );
  }
}
