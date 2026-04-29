import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/nav_provider.dart';
import '../services/auth_service.dart';

class CustomMenuButton extends StatelessWidget {
  final Color? backgroundColor;
  final Color? iconColor;

  const CustomMenuButton({
    super.key,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final state = GoRouterState.of(context);
    final isHome = state.uri.path == '/' || state.uri.path == '/admin' || state.uri.path == '/worker-dashboard';
    final canPop = GoRouter.of(context).canPop();

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(
          (canPop || !isHome) ? Icons.arrow_back_rounded : Icons.menu_rounded, 
          color: iconColor ?? Colors.white
        ),
        onPressed: () {
          if (canPop) {
            context.pop();
          } else if (!isHome) {
            final role = context.read<AuthService>().userData?['role'] ?? 'student';
            if (role == 'administrator') {
              context.go('/admin');
            } else if (role == 'worker') {
              context.go('/worker-dashboard');
            } else {
              context.go('/');
            }
          } else {
            // Use our global NavProvider to open the root sidebar
            context.read<NavProvider>().openDrawer();
          }
        },
      ),
    );
  }
}
