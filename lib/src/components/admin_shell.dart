import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../services/firestore_service.dart';
import '../core/theme/colors.dart';
import '../models/types.dart';

class AdminShell extends StatelessWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 1100;

        return Scaffold(
          backgroundColor: context.appBackground, // Uses theme-aware background
          drawer: isDesktop ? null : Drawer(
            width: 200,
            child: _AdminSidebarContent(),
          ),
          body: Row(
            children: [
              if (isDesktop)
                SizedBox(
                  width: 200,
                  child: _AdminSidebarContent(),
                ),
              Expanded(
                child: Column(
                  children: [
                    _AdminHeader(isDesktop: isDesktop),
                    Expanded(
                      child: child,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AdminSidebarContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LanguageProvider>();
    final auth = context.watch<AuthProvider>();
    final currentRoute = GoRouterState.of(context).uri.toString();
    final firestore = context.read<FirestoreService>();
    final resId = auth.currentResidenceId ?? auth.currentUserData?['residenceId'];

    return Container(
      color: const Color(0xFF0E2318), // Deep Night Green
      child: Column(
        children: [
          // Brand Section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D5C35),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.school_rounded, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'IQAMTY',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Admin Info
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1D5C35),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          'AD',
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lp.getText('administrator'),
                            style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Super admin',
                            style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.4), fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const Divider(color: Colors.white10, height: 1),
          
          // Navigation
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              children: [
                _buildNavItem(context, Icons.grid_view_rounded, lp.getText('dashboard'), '/admin', currentRoute),
                
                _buildNavItemWithBadge(
                  context, 
                  Icons.report_problem_rounded, 
                  lp.getText('complaints'), 
                  '/admin/complaints', 
                  currentRoute,
                  stream: firestore.getAllComplaints(residenceId: resId).map((list) => list.where((c) => c.status != Status.resolved).length),
                ),
                
                _buildNavItemWithBadge(
                  context, 
                  Icons.assignment_rounded, 
                  lp.getText('requests'), 
                  '/admin/requests', 
                  currentRoute,
                  stream: firestore.getAllRequests(residenceId: resId).map((list) => list.where((r) => r.status == 'pending').length),
                ),
                
                _buildNavItem(context, Icons.people_rounded, lp.getText('users'), '/admin/users', currentRoute),
                _buildNavItem(context, Icons.meeting_room_rounded, lp.getText('rooms'), '/admin/rooms', currentRoute),
                _buildNavItemWithBadge(
                  context, 
                  Icons.chat_bubble_rounded, 
                  lp.getText('messaging'), 
                  '/admin/chat', 
                  currentRoute,
                  stream: firestore.getAllChats(residenceId: resId).map((list) => list.where((c) => c['hasUnreadAdmin'] == true).length),
                ),
                _buildNavItem(context, Icons.engineering_rounded, 'Travailleurs', '/admin/workers', currentRoute),
                _buildNavItem(context, Icons.file_copy_rounded, lp.getText('documents'), '/admin/documents', currentRoute),
                _buildNavItem(context, Icons.restaurant_rounded, lp.getText('restoration'), '/admin/dining-config', currentRoute),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: Colors.white10, height: 1),
                ),
                
                _buildNavItem(context, Icons.campaign_rounded, lp.getText('announcements'), '/admin/announcements', currentRoute),
                _buildNavItem(context, Icons.handyman_rounded, lp.getText('maintenance'), '/admin/maintenance', currentRoute),
                _buildNavItem(context, Icons.settings_rounded, lp.getText('settings'), '/admin/settings', currentRoute),
              ],
            ),
          ),

          // Footer
          Padding(
            padding: const EdgeInsets.all(12),
            child: _buildNavItem(context, Icons.logout_rounded, 'Déconnexion', '/logout', currentRoute, isLogout: true),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String title, String route, String currentRoute, {bool isLogout = false, String? subtitle}) {
    final isSelected = currentRoute == route || (route != '/admin' && currentRoute.startsWith(route));
    final color = isLogout ? const Color(0xFFF87171) : (isSelected ? Colors.white : Colors.white.withValues(alpha: 0.4));
    final bgColor = isSelected ? const Color(0xFF1D5C35) : Colors.transparent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (isLogout) {
            _showLogoutConfirmation(context);
          } else {
            context.go(route);
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        color: color,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (subtitle != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    subtitle,
                    style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.5), fontSize: 9),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItemWithBadge(BuildContext context, IconData icon, String title, String route, String currentRoute, {required Stream<int> stream}) {
    return StreamBuilder<int>(
      stream: stream,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return _buildNavItem(
          context, 
          icon, 
          title, 
          route, 
          currentRoute, 
          subtitle: count > 0 ? count.toString() : null,
        );
      },
    );
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
            child: Text(lp.getText('cancel'), style: GoogleFonts.inter(color: context.appTextSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
            child: Text(lp.getText('confirm'), style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _AdminHeader extends StatelessWidget {
  final bool isDesktop;
  const _AdminHeader({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LanguageProvider>();
    final now = DateTime.now();
    final localeCode = context.watch<LanguageProvider>().currentLocale.languageCode;
    final dateStr = DateFormat.yMMMMEEEEd(localeCode == 'ar' ? 'ar' : 'fr').format(now);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: context.appCard,
        border: Border(bottom: BorderSide(color: context.appBorder)),
      ),
      child: Row(
        children: [
          if (!isDesktop)
            IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu_rounded),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getPageTitle(context, lp),
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: context.appTextPrimary),
              ),
              Text(
                dateStr,
                style: GoogleFonts.inter(fontSize: 11, color: context.appTextSecondary),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => context.push('/admin/notifications'),
            child: Stack(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    border: Border.all(color: context.appBorder),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.notifications_none_rounded, size: 18, color: context.appTextSecondary),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPageTitle(BuildContext context, LanguageProvider lp) {
    final route = GoRouterState.of(context).uri.toString();
    if (route == '/admin') return 'Bonjour, Administrateur';
    if (route.startsWith('/admin/complaints')) return lp.getText('complaints');
    if (route.startsWith('/admin/requests')) return lp.getText('requests');
    if (route.startsWith('/admin/users')) return lp.getText('users');
    if (route.startsWith('/admin/chat')) return lp.getText('messaging');
    if (route.startsWith('/admin/workers')) return 'Travailleurs';
    if (route.startsWith('/admin/rooms/')) return 'Détails Bloc';
    if (route.startsWith('/admin/rooms')) return lp.getText('rooms');
    if (route.startsWith('/admin/resources')) return 'Ressources';
    if (route.startsWith('/admin/announcements')) return lp.getText('announcements');
    if (route.startsWith('/admin/maintenance')) return lp.getText('maintenance');
    if (route.startsWith('/admin/dining')) return lp.getText('restoration');
    if (route.startsWith('/admin/documents')) return lp.getText('documents');
    if (route.startsWith('/admin/settings')) return lp.getText('settings');
    return 'Admin';
  }
}
