import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/core/router/app_router.dart';
import 'src/core/theme/app_theme.dart';
import 'src/providers/app_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const IqamtyApp(),
    ),
  );
}

class IqamtyApp extends StatelessWidget {
  const IqamtyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    return MaterialApp.router(
      title: 'IQAMTY',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: appProvider.themeMode,
      routerConfig: appRouter,
      builder: (context, child) {
        return Directionality(
          textDirection: appProvider.language == 'AR'
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
