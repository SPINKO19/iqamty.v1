import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart'; // Placeholder
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/placeholder_screen.dart';
import '../widgets/bottom_nav_bar.dart';
import '../providers/auth_provider.dart';
import 'package:flutter/material.dart';

class AppRouter {
  static GoRouter router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final authProvider = context.read<AuthProvider>();
      final isAuthenticated = authProvider.isAuthenticated;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isAuthenticated && !isLoginRoute) {
        return '/login';
      }

      if (isAuthenticated && isLoginRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return BottomNavBarScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: '/planning',
            pageBuilder: (context, state) => const NoTransitionPage(child: PlaceholderScreen(title: 'Planning')),
          ),
          GoRoute(
            path: '/posts',
            pageBuilder: (context, state) => const NoTransitionPage(child: PlaceholderScreen(title: 'Posts')),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(child: ProfileScreen()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(child: SettingsScreen()),
          ),
        ],
      ),
    ],
  );
}
