import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../providers/nav_provider.dart';
import '../services/firestore_service.dart';
import '../models/types.dart';
import '../core/theme/colors.dart';

const _kDarkGreen = Color(0xFF2D6A4F);
const _kMintGreen = Color(0xFFD8F3DC);

class AppSidebar extends StatelessWidget {
  final Widget child;

  const AppSidebar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavProvider>();
    return PopScope(
      // Don't let the system pop (exit app) automatically.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final router = GoRouter.of(context);
        // If the router can go back, go back one step.
        if (router.canPop()) {
          router.pop();
        }
        // If we are at the root already, do nothing (keeps app open).
      },
      child: Scaffold(
        key: nav.scaffoldKey,
        backgroundColor: context.appBackground,
        drawer: _buildSidebar(context),
        body: child,
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final nav = context.read<NavProvider>();
    final languageProvider = context.watch<LanguageProvider>();
    final auth = context.watch<AuthProvider>();
    final firestore = context.watch<FirestoreService>();
    final role = auth.currentStudent?.role ?? auth.currentUserData?['role'] ?? 'student';

    List<dynamic> items;
    if (role == 'administrator') {
      items = _adminItems(context, languageProvider);
    } else if (role == 'worker') {
      items = _workerItems(context, languageProvider, auth, firestore);
    } else {
      items = _studentItems(context, languageProvider, auth, firestore);
    }

    final currentRoute = GoRouterState.of(context).uri.toString();

    // Redesigned Top Header
    String fullName = 'Utilisateur';
    String initials = 'U';
    String? subtitle;

    if (role == 'student' && auth.currentStudent != null) {
      final prenom = auth.currentStudent?.prenomFr ?? '';
      final nom = auth.currentStudent?.nomFr ?? '';
      fullName = '$prenom $nom'.trim().isEmpty ? 'Utilisateur' : '$prenom $nom';
      initials = (prenom.isNotEmpty ? prenom[0].toUpperCase() : '') + (nom.isNotEmpty ? nom[0].toUpperCase() : 'U');
      subtitle = 'Chambre ${auth.currentStudent?.chambre?.toString() ?? 'N/A'}';
    } else {
      fullName = auth.currentUserData?['displayName']?.toString() ?? auth.currentUserData?['name']?.toString() ?? 'Employé';
      final parts = fullName.split(' ');
      if (parts.length > 1) {
        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
        initials = parts[0][0].toUpperCase();
      }
      subtitle = auth.currentUserData?['department']?.toString() ?? (role == 'administrator' ? 'Administration' : 'Service Technique');
    }

    final header = Container(
      color: _kDarkGreen,
      padding: const EdgeInsets.only(left: 20, right: 20, top: 48, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.school_outlined, color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  const Text(
                    'IQAMTY',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'v2.1',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => nav.closeDrawer(),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final drawer = Drawer(
      width: 300,
      backgroundColor: context.appBackground,
      elevation: 16,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Column(
        children: [
          header,
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 20),
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
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                StreamBuilder<int>(
                  stream: context.read<FirestoreService>().getUnreadNotificationsCount(
                    context.read<AuthProvider>().currentStudent?.id?.toString() ?? 
                    context.read<AuthProvider>().currentUserData?['id']?.toString() ?? ''
                  ),
                  builder: (context, snapshot) {
                    final unreadCount = snapshot.data ?? 0;
                    return _buildNavItem(
                      context,
                      _NavItemData(
                        Icons.notifications_none_rounded, 
                        'Notifications', 
                        '/notifications',
                        badgeCount: unreadCount,
                        badgeColor: const Color(0xFFEF4444),
                      ),
                      currentRoute,
                    );
                  }
                ),
                _buildNavItem(
                  context,
                  _NavItemData(Icons.settings_outlined, 'Paramètres', '/settings'),
                  currentRoute,
                ),
                _buildNavItem(
                  context,
                  _NavItemData(Icons.logout_rounded, 'Déconnexion', '/logout'),
                  currentRoute,
                  isLogout: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return drawer;
  }

  List<dynamic> _studentItems(BuildContext context, LanguageProvider lp, AuthProvider auth, FirestoreService firestore) {
    final studentId = auth.currentStudent?.id?.toString() ?? '';

    return [
      _NavHeaderData('PLATEFORME'),
      _NavItemData(Icons.home_outlined, 'Dashboard', '/'),
      _NavItemData(Icons.restaurant_outlined, 'Restauration', '/dining'),

      const SizedBox(height: 8),
      _NavHeaderData('SERVICES'),
      StreamBuilder<List<Complaint>>(
        stream: firestore.getMyComplaints(studentId),
        builder: (context, snapshot) {
          final count = snapshot.data?.where((c) => c.status != Status.resolved).length ?? 0;
          return _buildNavItem(
            context,
            _NavItemData(
              Icons.warning_amber_rounded,
              'Réclamations',
              '/complaints',
              badgeCount: count,
              badgeColor: const Color(0xFFEF4444),
            ),
            GoRouterState.of(context).uri.toString(),
          );
        },
      ),
      _NavItemData(Icons.assignment_outlined, 'Demandes', '/requests'),

      const SizedBox(height: 8),
      _NavHeaderData('RÉSEAU'),
      _NavItemData(Icons.people_outline, 'Communauté', '/community'),
      _NavItemData(
        Icons.chat_bubble_outline_rounded,
        'Messages',
        '/chat',
        streamBadge: firestore.getAllChats().map((list) {
          final userId = auth.currentUserData?['uid'] ?? auth.currentStudent?.matricule ?? '';
          return list.where((c) => c['studentId'] == userId && c['hasUnreadStudent'] == true).length;
        }),
        badgeColor: const Color(0xFF3B82F6),
      ),
      _NavItemData(Icons.person_outline_rounded, 'Profil', '/profile'),
    ];
  }

  List<dynamic> _adminItems(BuildContext context, LanguageProvider lp) {
    return [
      _NavHeaderData('PLATFORM'),
      _NavItemData(Icons.dashboard_outlined, 'Dashboard', '/admin'),

      const SizedBox(height: 8),
      _NavHeaderData('MANAGEMENT'),
      _NavItemData(Icons.report_problem_outlined, 'Complaints', '/admin/complaints'),
      _NavItemData(Icons.handyman_outlined, 'Requests', '/admin/requests'),
      _NavItemData(Icons.people_outline_rounded, 'Users', '/admin/users'),
      _NavItemData(Icons.forum_outlined, 'Community', '/admin/community'),
    ];
  }

  List<dynamic> _workerItems(BuildContext context, LanguageProvider lp, AuthProvider auth, FirestoreService firestore) {
    return [
      _NavHeaderData('ESPACE TRAVAILLEUR'),
      _NavItemData(Icons.build_outlined, 'Tableau de bord', '/worker-dashboard'),
      
      const SizedBox(height: 8),
      _NavHeaderData('COMMUNICATION'),
      _NavItemData(
        Icons.chat_bubble_outline_rounded,
        'Messages',
        '/chat',
        streamBadge: firestore.getAllChats().map((list) {
          final userId = auth.currentUserData?['uid'] ?? auth.currentStudent?.matricule ?? '';
          return list.where((c) => c['studentId'] == userId && c['hasUnreadStudent'] == true).length;
        }),
        badgeColor: const Color(0xFF3B82F6),
      ),
      _NavItemData(Icons.forum_outlined, 'Communauté', '/community'),
      _NavItemData(Icons.person_outline_rounded, 'Profil', '/profile'),
    ];
  }

  Widget _buildNavHeader(BuildContext context, _NavHeaderData data) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 8),
      child: Text(
        data.title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, _NavItemData data, String currentRoute, {bool isLogout = false}) {
    final nav = context.read<NavProvider>();
    final isSelected = !isLogout && (currentRoute == data.route || (data.route != '/' && currentRoute.startsWith(data.route)));

    final textColor = isLogout ? const Color(0xFFEF4444) : (isSelected ? _kDarkGreen : const Color(0xFF4B5563));
    final iconColor = isLogout ? const Color(0xFFEF4444) : (isSelected ? _kDarkGreen : const Color(0xFF6B7280));
    final bgColor = isSelected ? _kMintGreen : Colors.transparent;
    final iconData = isSelected ? _getFilledIcon(data.icon) : data.icon;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (isLogout) {
            _showLogoutConfirmation(context);
          } else {
            // Use NavProvider to close the root drawer immediately
            nav.closeDrawer();
            
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                context.push(data.route);
              }
            });
          }
        },
        child: Container(
          color: bgColor,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(iconData, size: 20, color: iconColor),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  data.title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              if ((data.badgeCount != null && data.badgeCount! > 0) || data.streamBadge != null)
                data.streamBadge != null 
                ? StreamBuilder<int>(
                    stream: data.streamBadge,
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      if (count == 0) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: data.badgeColor ?? const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          count.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      );
                    }
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: data.badgeColor ?? const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      data.badgeCount.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFilledIcon(IconData hollowIcon) {
    if (hollowIcon == Icons.home_outlined) return Icons.home_rounded;
    if (hollowIcon == Icons.restaurant_outlined) return Icons.restaurant_rounded;
    if (hollowIcon == Icons.report_problem_outlined) return Icons.report_problem_rounded;
    if (hollowIcon == Icons.warning_amber_rounded) return Icons.warning_rounded;
    if (hollowIcon == Icons.assignment_outlined) return Icons.assignment_rounded;
    if (hollowIcon == Icons.handyman_outlined) return Icons.handyman_rounded;
    if (hollowIcon == Icons.forum_outlined) return Icons.forum_rounded;
    if (hollowIcon == Icons.people_outline) return Icons.people_rounded;
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
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
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
  final int? badgeCount;
  final Stream<int>? streamBadge;
  final Color? badgeColor;
  
  _NavItemData(this.icon, this.title, this.route, {this.badgeCount, this.streamBadge, this.badgeColor});
}
