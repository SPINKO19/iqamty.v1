import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'src/core/theme/app_theme.dart';
import 'src/core/router.dart';
import 'src/providers/auth_provider.dart';
import 'src/services/auth_service.dart';
import 'src/services/firestore_service.dart';
import 'src/providers/theme_provider.dart';
import 'src/providers/language_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
    final themeMode = context.watch<ThemeProvider>().themeMode;
    // Locale logic commented out for debugging white screen
    /*
    final currentLocale = context.watch<LanguageProvider>().currentLocale;
    */
    
    return MaterialApp.router(
      title: 'Iqamty',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: _router,
    );
  }
}
