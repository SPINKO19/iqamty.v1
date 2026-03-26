import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../core/theme/colors.dart';

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
            backgroundColor: context.appBackground,
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
              title: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'IQAMTY', 
                    style: TextStyle(
                      fontWeight: FontWeight.w900, 
                      color: context.appTextPrimary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              backgroundColor: context.appCard,
              elevation: 0,
              iconTheme: IconThemeData(color: context.appTextPrimary),
            ),
            drawer: _buildSidebar(context, isDesktop: false),
            body: child,
          );
        }
      },
    );
  }

  Widget _buildSidebar(BuildContext context, {required bool isDesktop}) {
    final languageProvider = context.watch<LanguageProvider>();
    final role = context.watch<AuthProvider>().currentStudent?.role 
              ?? context.watch<AuthProvider>().currentUserData?['role'] 
              ?? 'student';

    List<dynamic> items;
    if (role == 'administrator') {
      items = _adminItems(context, languageProvider);
    } else if (role == 'worker') {
      items = _workerItems(context, languageProvider);
    } else {
      items = _studentItems(context, languageProvider);
    }

    final currentRoute = GoRouterState.of(context).uri.toString();

    final drawer = Drawer(
      width: isDesktop ? 280 : 300,
      backgroundColor: context.appCard,
      elevation: isDesktop ? 0 : 16,
      shape: isDesktop ? const RoundedRectangleBorder(borderRadius: BorderRadius.zero) : null,
      child: Column(
        children: [
        Container(
          height: 100,
          alignment: Alignment.bottomLeft,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                ),
              ),
                const SizedBox(width: 16),
                Text(
                  'IQAMTY', 
                  style: TextStyle(
                    color: context.appTextPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          


          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: items.map<Widget>((dynamic item) {
                if (item is _NavItemData) {
                  return _buildNavItem(context, item, currentRoute);
                } else if (item is _NavHeaderData) {
                  return _buildNavHeader(context, item);
                }
                return item as Widget;
              }).toList(),
            ),
          ),
          Divider(height: 1, color: context.appBorder),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Column(
              children: [
                _buildNavItem(
                  context, 
                  _NavItemData(Icons.settings_outlined, languageProvider.getText('settings'), '/settings'),
                  currentRoute,
                ),
                _buildNavItem(
                  context, 
                  _NavItemData(Icons.logout_rounded, languageProvider.getText('logout'), '/logout'),
                  currentRoute,
                  isLogout: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (isDesktop) {
      return Container(
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: context.appBorder, width: 1)),
        ),
        child: drawer,
      );
    }
    return drawer;
  }

  List<dynamic> _studentItems(BuildContext context, LanguageProvider lp) {
    return [
      _NavHeaderData(lp.getText('platform')),
      _NavItemData(Icons.home_outlined, lp.getText('dashboard'), '/'),
      _NavItemData(Icons.restaurant_outlined, lp.getText('restoration'), '/dining'),
      
      const SizedBox(height: 16),
      _NavHeaderData(lp.getText('services')),
      _NavItemData(Icons.report_problem_outlined, lp.getText('complaints'), '/complaints'),
      _NavItemData(Icons.handyman_outlined, lp.getText('requests'), '/requests'),
      
      const SizedBox(height: 16),
      _NavHeaderData(lp.getText('network')),
      _NavItemData(Icons.forum_outlined, lp.getText('community'), '/community'),
      _NavItemData(Icons.chat_bubble_outline_rounded, lp.getText('messages'), '/chat'),
      _NavItemData(Icons.person_outline_rounded, lp.getText('profile'), '/profile'),
    ];
  }

  List<dynamic> _adminItems(BuildContext context, LanguageProvider lp) {
    return [
      _NavHeaderData(lp.getText('platform')),
      _NavItemData(Icons.dashboard_outlined, lp.getText('admin_dashboard'), '/admin'),
      
      const SizedBox(height: 16),
      _NavHeaderData(lp.getText('management')),
      _NavItemData(Icons.report_problem_outlined, lp.getText('complaints'), '/admin/complaints'),
      _NavItemData(Icons.handyman_outlined, lp.getText('requests'), '/admin/requests'),
      _NavItemData(Icons.people_outline_rounded, lp.getText('users'), '/admin/users'),
    ];
  }

  List<dynamic> _workerItems(BuildContext context, LanguageProvider lp) {
    return [
      _NavHeaderData(lp.getText('platform')),
      _NavItemData(Icons.build_outlined, lp.getText('worker_dashboard'), '/worker-dashboard'),
    ];
  }

  

  Widget _buildNavHeader(BuildContext context, _NavHeaderData data) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 12),
      child: Text(
        data.title,
        style: const TextStyle(
          color: Color(0xFF6B7280), // Dark grey
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, _NavItemData data, String currentRoute, {bool isLogout = false}) {
    final isSelected = !isLogout && (currentRoute == data.route || (data.route != '/' && currentRoute.startsWith(data.route)));
    
    final color = isLogout ? AppColors.error : (isSelected ? AppColors.primary : const Color(0xFF6B7280));
    final bgColor = isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent;

    // Determine the icon to show. If selected, you might want to switch to filled icon, but for now we'll just tint it.
    final iconData = isSelected ? _getFilledIcon(data.icon) : data.icon;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (isLogout) {
              _showLogoutConfirmation(context);
            } else {
              if (Scaffold.maybeOf(context)?.hasDrawer ?? false) {
                Scaffold.of(context).closeDrawer();
              }
              context.go(data.route);
            }
          },
          borderRadius: BorderRadius.circular(12),
          hoverColor: context.appBorder.withOpacity(0.5),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(iconData, color: color, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    data.title,
                    style: TextStyle(
                      color: isLogout ? AppColors.error : (isSelected ? AppColors.primary : const Color(0xFF6B7280)),
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getFilledIcon(IconData hollowIcon) {
    if (hollowIcon == Icons.home_outlined) return Icons.home_rounded;
    if (hollowIcon == Icons.restaurant_outlined) return Icons.restaurant_rounded;
    if (hollowIcon == Icons.report_problem_outlined) return Icons.report_problem_rounded;
    if (hollowIcon == Icons.handyman_outlined) return Icons.handyman_rounded;
    if (hollowIcon == Icons.forum_outlined) return Icons.forum_rounded;
    if (hollowIcon == Icons.chat_bubble_outline_rounded) return Icons.chat_bubble_rounded;
    if (hollowIcon == Icons.person_outline_rounded) return Icons.person_rounded;
    if (hollowIcon == Icons.dashboard_outlined) return Icons.dashboard_rounded;
    if (hollowIcon == Icons.people_outline_rounded) return Icons.people_rounded;
    if (hollowIcon == Icons.build_outlined) return Icons.build_rounded;
    return hollowIcon;
  }

  void _showLogoutConfirmation(BuildContext context) {
    final lp = context.read<LanguageProvider>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lp.getText('logout_confirm_title')),
        content: Text(lp.getText('logout_confirm_msg')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lp.getText('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(lp.getText('confirm')),
          ),
        ],
      ),
    );
  }
}

class _NavHeaderData {
  final String title;
  _NavHeaderData(this.title);
}

class _NavItemData {
  final IconData icon;
  final String title;
  final String route;
  _NavItemData(this.icon, this.title, this.route);
}
