import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'bottom_nav_bar.dart';
import 'side_drawer.dart';

/// Shell widget that wraps all main screens with bottom nav + side drawer
class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final location = GoRouterState.of(context).uri.path;

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(child: child),
              BottomNavBar(currentPath: location),
            ],
          ),
          // Side drawer overlay
          if (appProvider.isDrawerOpen)
            GestureDetector(
              onTap: () => appProvider.setDrawerOpen(false),
              child: Container(
                color: Colors.black.withValues(alpha: 0.55),
              ),
            ),
          // Side drawer panel
          AnimatedPositioned(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            left: appProvider.isDrawerOpen ? 0 : -300,
            top: 0,
            bottom: 0,
            child: const SideDrawer(),
          ),
        ],
      ),
    );
  }
}
