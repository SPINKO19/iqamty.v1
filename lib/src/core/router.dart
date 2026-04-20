import 'package:go_router/go_router.dart';

import '../components/app_sidebar.dart';
import '../components/admin_shell.dart';
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
import '../views/sports_program_view.dart';
import '../views/notifications_view.dart';
import '../views/chat_view.dart';
import '../views/worker_dashboard.dart';
import '../views/admin_dashboard.dart';
import '../views/admin_complaints_view.dart';
import '../views/admin_requests_view.dart';
import '../views/admin_users_view.dart';
import '../views/admin_announcements_view.dart';
import '../views/admin_documents_view.dart';
import '../views/admin_workers_view.dart';
import '../views/announcement_detail_screen.dart';
import '../views/request_list_screen.dart';
import '../views/create_request_screen.dart';
import '../views/register_screen.dart';
import '../views/banned_screen.dart';
import '../views/placeholder_screen.dart';
import '../views/admin_placeholder_view.dart';
import '../views/admin_dining_config_view.dart';
import '../views/gym_view.dart';
import '../views/weightlifting_view.dart';
import '../views/hamam_view.dart';
<<<<<<< HEAD
import '../views/admin_chat_list_view.dart';
=======
import '../views/banned_screen.dart';
>>>>>>> 58ecaf86e10f96527016faf5e573cb6072c3269b
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
        final isRegisterRoute = state.matchedLocation == '/register';
        final isBannedRoute = state.matchedLocation == '/banned';

        if (!isAuthenticated && !isLoginRoute && !isRegisterRoute) {
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
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/banned',
          builder: (context, state) => const BannedScreen(),
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
          GoRoute(path: '/sports', pageBuilder: (context, state) => const NoTransitionPage(child: SportsProgramView())),
          GoRoute(path: '/notifications', pageBuilder: (context, state) => const NoTransitionPage(child: NotificationsView())),
          GoRoute(path: '/documents', pageBuilder: (context, state) => const NoTransitionPage(child: DocumentsView())),
            GoRoute(path: '/community', pageBuilder: (context, state) => const NoTransitionPage(child: ForumView())),
            GoRoute(
              path: '/chat', 
              pageBuilder: (context, state) => const NoTransitionPage(child: ChatView()),
            ),
            GoRoute(
              path: '/chat/:chatId', 
              builder: (context, state) {
                final chatId = state.pathParameters['chatId'];
                final extra = state.extra as Map<String, dynamic>?;
                return ChatView(
                  chatId: chatId, 
                  name: extra?['name'],
                  isAdmin: extra?['isAdmin'] ?? false,
                );
              }
            ),
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
            GoRoute(path: '/planning', pageBuilder: (context, state) => const NoTransitionPage(child: SportsProgramView())),
            GoRoute(path: '/gym', pageBuilder: (context, state) => const NoTransitionPage(child: GymView())),
            GoRoute(path: '/weightlifting', pageBuilder: (context, state) => const NoTransitionPage(child: WeightliftingView())),
            GoRoute(path: '/hamam', pageBuilder: (context, state) => const NoTransitionPage(child: HamamView())),
            
            GoRoute(path: '/worker-dashboard', pageBuilder: (context, state) => const NoTransitionPage(child: WorkerDashboard())),
          ],
        ),
        ShellRoute(
          builder: (context, state, child) {
            return AdminShell(child: child);
          },
          routes: [
            GoRoute(path: '/admin', pageBuilder: (context, state) => const NoTransitionPage(child: AdminDashboard())),
            GoRoute(path: '/admin/complaints', pageBuilder: (context, state) => const NoTransitionPage(child: AdminComplaintsView())),
            GoRoute(
              path: '/admin/requests',
              builder: (context, state) => const AdminRequestsView(),
            ),
            GoRoute(path: '/admin/users', pageBuilder: (context, state) => const NoTransitionPage(child: AdminUsersView())),
            GoRoute(path: '/admin/announcements', pageBuilder: (context, state) => const NoTransitionPage(child: AdminAnnouncementsView())),
            GoRoute(path: '/admin/documents', pageBuilder: (context, state) => const NoTransitionPage(child: AdminDocumentsView())),
            GoRoute(path: '/admin/resources', pageBuilder: (context, state) => const NoTransitionPage(child: AdminPlaceholderView(title: 'Resources'))),
            GoRoute(path: '/admin/dining', pageBuilder: (context, state) => const NoTransitionPage(child: AdminPlaceholderView(title: 'Dining Config'))),
            GoRoute(path: '/admin/dining-config', pageBuilder: (context, state) => const NoTransitionPage(child: AdminDiningConfigView())),
            GoRoute(path: '/admin/workers', pageBuilder: (context, state) => const NoTransitionPage(child: AdminWorkersView())),
            GoRoute(path: '/admin/chat', pageBuilder: (context, state) => const NoTransitionPage(child: AdminChatListView())),
            GoRoute(
              path: '/admin/chat/:chatId',
              builder: (context, state) {
                final chatId = state.pathParameters['chatId'];
                final extra = state.extra as Map<String, dynamic>?;
                return ChatView(
                  chatId: chatId, 
                  name: extra?['name'],
                  isAdmin: true,
                );
              }
            ),
            GoRoute(path: '/admin/maintenance', pageBuilder: (context, state) => const NoTransitionPage(child: AdminPlaceholderView(title: 'Maintenance'))),
            GoRoute(path: '/admin/settings', pageBuilder: (context, state) => const NoTransitionPage(child: SettingsScreen())),
          ],
        ),
      ],
    );
  }
}
