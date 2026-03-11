import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AppSidebar extends StatelessWidget {
  final Widget child;

  const AppSidebar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 768;

        if (isDesktop) {
          return Scaffold(
            body: Row(
              children: [
                _buildSidebar(context, isDesktop: true),
                Expanded(child: child),
              ],
            ),
          );
        } else {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Iqamty'),
              elevation: 0,
            ),
            drawer: _buildSidebar(context, isDesktop: false),
            body: child,
          );
        }
      },
    );
  }

  Widget _buildSidebar(BuildContext context, {required bool isDesktop}) {
    final role = context.watch<AuthProvider>().currentStudent?.role 
              ?? context.watch<AuthProvider>().currentUserData?['role'] 
              ?? 'student'; // Fallback to student

    List<Widget> items;
    if (role == 'administrator') {
      items = _adminItems(context);
    } else if (role == 'worker') {
      items = _workerItems(context);
    } else {
      items = _studentItems(context);
    }

    final drawer = Drawer(
      width: isDesktop ? 260 : null,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.blue),
            child: Center(
              child: Text(
                'Iqamty - $role', 
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: items,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              context.read<AuthProvider>().logout();
            },
          ),
        ],
      ),
    );

    return drawer;
  }

  List<Widget> _studentItems(BuildContext context) {
    return [
      _navItem(context, Icons.dashboard_outlined, 'Dashboard', '/'),
      _navItem(context, Icons.fastfood_outlined, 'Dining', '/dining'),
      _navItem(context, Icons.report_problem_outlined, 'Complaints', '/complaints'),
      _navItem(context, Icons.build_outlined, 'Requests', '/requests'),
      _navItem(context, Icons.forum_outlined, 'Community', '/community'),
      _navItem(context, Icons.chat_bubble_outline, 'Chat', '/chat'),
      _navItem(context, Icons.person_outline, 'Profile', '/profile'),
      _navItem(context, Icons.settings_outlined, 'Settings', '/settings'),
    ];
  }

  List<Widget> _adminItems(BuildContext context) {
    return [
      _navItem(context, Icons.dashboard_outlined, 'Admin Dashboard', '/admin'),
      _navItem(context, Icons.report_problem_outlined, 'Complaints', '/admin/complaints'),
      _navItem(context, Icons.build_outlined, 'Requests', '/admin/requests'),
      _navItem(context, Icons.people_outline, 'Users', '/admin/users'),
    ];
  }

  List<Widget> _workerItems(BuildContext context) {
    return [
      _navItem(context, Icons.build_outlined, 'Worker Dashboard', '/worker-dashboard'),
    ];
  }

  Widget _navItem(BuildContext context, IconData icon, String title, String route) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        if (Scaffold.maybeOf(context)?.hasDrawer ?? false) {
          Scaffold.of(context).closeDrawer();
        }
        context.go(route);
      },
    );
  }
}
