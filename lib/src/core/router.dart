import 'package:go_router/go_router.dart';

import '../components/app_sidebar.dart';
import '../providers/auth_provider.dart';
import '../views/login_screen.dart';
import '../views/home_screen.dart'; // Dashboard
import '../views/profile_screen.dart';
import '../views/settings_screen.dart';
import '../views/dining_view.dart';
import '../views/complaints_view.dart';
import '../views/requests_view.dart';
import '../views/documents_view.dart';
import '../views/forum_view.dart';
import '../views/chat_view.dart';
import '../views/worker_dashboard.dart';
import '../views/admin_dashboard.dart';
import '../views/admin_complaints_view.dart';
import '../views/admin_users_view.dart';
import '../views/admin_announcements_view.dart';
import '../views/announcement_detail_screen.dart';
import '../views/request_list_screen.dart';
import '../views/create_request_screen.dart';
import '../views/placeholder_screen.dart';
import '../models/types.dart';

class AppRouter {
  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/login',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isBanned = authProvider.currentStudent?.isBanned == true || 
                         authProvider.currentUserData?['isBanned'] == true;
        final role = authProvider.currentStudent?.role ?? 
                     authProvider.currentUserData?['role'] ?? 'student';

        final isLoginRoute = state.matchedLocation == '/login';
        final isBannedRoute = state.matchedLocation == '/banned';

        if (!isAuthenticated && !isLoginRoute) {
          return '/login';
        }

        if (isAuthenticated && isBanned && !isBannedRoute) {
          return '/banned';
        }

        if (isAuthenticated && !isBanned && isBannedRoute) {
          return '/';
        }

        if (isAuthenticated && isLoginRoute) {
          if (role == 'administrator') return '/admin';
          if (role == 'worker') return '/worker-dashboard';
          return '/';
        }

        // Role-based protection
        if (isAuthenticated && !isBanned && state.matchedLocation.startsWith('/admin') && role != 'administrator') {
          return '/';
        }
        
        if (isAuthenticated && !isBanned && state.matchedLocation.startsWith('/worker') && role != 'worker') {
          return '/';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/banned',
          builder: (context, state) => const PlaceholderScreen(title: 'Account Suspended'),
        ),
        ShellRoute(
          builder: (context, state, child) {
            return AppSidebar(child: child);
          },
          routes: [
            // Student Routes
            GoRoute(
              path: '/',
              pageBuilder: (context, state) => const NoTransitionPage(child: HomeScreen()), 
            ),
            GoRoute(path: '/dining', pageBuilder: (context, state) => const NoTransitionPage(child: DiningView())),
            GoRoute(path: '/complaints', pageBuilder: (context, state) => const NoTransitionPage(child: ComplaintsView())),
          GoRoute(path: '/requests', pageBuilder: (context, state) => const NoTransitionPage(child: RequestsView())),
          GoRoute(path: '/transport', pageBuilder: (context, state) => const NoTransitionPage(child: PlaceholderScreen(title: 'Transport'))),
          GoRoute(path: '/documents', pageBuilder: (context, state) => const NoTransitionPage(child: DocumentsView())),
            GoRoute(path: '/community', pageBuilder: (context, state) => const NoTransitionPage(child: ForumView())),
            GoRoute(path: '/chat', pageBuilder: (context, state) => const NoTransitionPage(child: ChatView())),
            GoRoute(
              path: '/announcement',
              builder: (context, state) {
                final announcement = state.extra as Announcement;
                return AnnouncementDetailScreen(announcement: announcement);
              },
            ),
            GoRoute(
              path: '/request-list/:category',
              builder: (context, state) {
                final category = state.pathParameters['category']!;
                return RequestListScreen(category: category);
              },
            ),
            GoRoute(
              path: '/create-request',
              builder: (context, state) {
                final category = state.extra as String?;
                return CreateRequestScreen(initialCategory: category);
              },
            ),
            GoRoute(
              path: '/profile',
              pageBuilder: (context, state) => const NoTransitionPage(child: ProfileScreen()),
            ),
            GoRoute(
              path: '/settings',
              pageBuilder: (context, state) => const NoTransitionPage(child: SettingsScreen()),
            ),
            
            // Admin Routes
            GoRoute(path: '/admin', pageBuilder: (context, state) => const NoTransitionPage(child: AdminDashboard())),
            GoRoute(path: '/admin/complaints', pageBuilder: (context, state) => const NoTransitionPage(child: AdminComplaintsView())),
            GoRoute(path: '/admin/requests', pageBuilder: (context, state) => const NoTransitionPage(child: PlaceholderScreen(title: 'Admin Requests'))),
            GoRoute(path: '/admin/users', pageBuilder: (context, state) => const NoTransitionPage(child: AdminUsersView())),
            GoRoute(path: '/admin/announcements', pageBuilder: (context, state) => const NoTransitionPage(child: AdminAnnouncementsView())),
            GoRoute(path: '/admin/resources', pageBuilder: (context, state) => const NoTransitionPage(child: PlaceholderScreen(title: 'Config Resources'))),
            GoRoute(path: '/admin/dining', pageBuilder: (context, state) => const NoTransitionPage(child: PlaceholderScreen(title: 'Config Dining'))),
            
            // Worker Routes
            GoRoute(path: '/worker-dashboard', pageBuilder: (context, state) => const NoTransitionPage(child: WorkerDashboard())),
          ],
        ),
      ],
    );
  }
}
