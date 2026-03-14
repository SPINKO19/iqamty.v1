


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/core/theme/app_theme.dart';
import 'src/core/router.dart';
import 'src/providers/auth_provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'src/services/auth_service.dart';
import 'src/services/firestore_service.dart';
import 'src/providers/theme_provider.dart';
import 'src/providers/language_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Try to initialize Firebase, if it fails gracefully continue (for dev before google-services.json)
 
   try {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
} catch (e) {
  debugPrint("Firebase init failed: $e");
}
  

  final authService = AuthService();
  final authProvider = AuthProvider(authService);
  final firestoreService = FirestoreService();
  final themeProvider = ThemeProvider();
  final languageProvider = LanguageProvider();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: firestoreService),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: languageProvider),
      ],
      child: const IqamtyApp(),
    ),
  );
}

class IqamtyApp extends StatelessWidget {
  const IqamtyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeProvider>().themeMode;
    
    return MaterialApp.router(
      title: 'Iqamty',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: AppRouter.router,
    );
  }
}

