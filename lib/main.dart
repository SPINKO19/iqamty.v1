


import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'src/core/theme/app_theme.dart';
import 'src/core/router.dart';
import 'src/providers/auth_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'src/services/auth_service.dart';
import 'src/services/firestore_service.dart';
import 'src/providers/theme_provider.dart';
import 'src/providers/language_provider.dart';
import 'src/providers/nav_provider.dart';
import 'src/services/storage_service.dart';

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
  final storageService = StorageService();
  final navProvider = NavProvider();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: firestoreService),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: languageProvider),
        ChangeNotifierProvider.value(value: storageService),
        ChangeNotifierProvider.value(value: navProvider),
      ],
      child: const IqamtyApp(),
    ),
  );
}

class IqamtyApp extends StatefulWidget {
  const IqamtyApp({super.key});

  @override
  State<IqamtyApp> createState() => _IqamtyAppState();
}

class _IqamtyAppState extends State<IqamtyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.createRouter(context.read<AuthProvider>());
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = context.watch<LanguageProvider>().currentLocale;
    
    return MaterialApp.router(
      title: 'Iqamty',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: context.watch<ThemeProvider>().flutterThemeMode,
      locale: currentLocale,
      localizationsDelegates: const [
        // AppLocalizations.delegate, // Add this if you use arb files
        ...GlobalMaterialLocalizations.delegates,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr'),
        Locale('en'),
        Locale('ar'),
      ],
      routerConfig: _router,
    );
  }
}
