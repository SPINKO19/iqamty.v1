import 'package:go_router/go_router.dart';
import '../../views/splash_screen.dart';
import '../../views/login_screen.dart';
import '../../views/home_screen.dart';
import '../../views/profile_screen.dart';
import '../../views/complaints_view.dart';
import '../../views/dining_view.dart';
import '../../views/requests_view.dart';
import '../../views/notifications_view.dart';
import '../../widgets/app_shell.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/restauration',
          builder: (context, state) => const DiningView(),
        ),
        GoRoute(
          path: '/demandes',
          builder: (context, state) => const RequestsView(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/reclamations',
          builder: (context, state) => const ComplaintsView(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsView(),
        ),
      ],
    ),
  ],
);
