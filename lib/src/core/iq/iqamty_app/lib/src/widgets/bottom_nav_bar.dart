import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/colors.dart';

class BottomNavBar extends StatelessWidget {
  final String currentPath;

  const BottomNavBar({super.key, required this.currentPath});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tabs = [
      _TabItem(icon: Icons.home_rounded, label: 'Accueil', path: '/home'),
      _TabItem(icon: Icons.restaurant_rounded, label: 'Resto', path: '/restauration'),
      null, // FAB placeholder
      _TabItem(icon: Icons.assignment_rounded, label: 'Demandes', path: '/demandes'),
      _TabItem(icon: Icons.person_rounded, label: 'Profil', path: '/profile'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : const Color(0xFFF0F0F0),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: tabs.asMap().entries.map((entry) {
              final tab = entry.value;
              if (tab == null) {
                // FAB center button
                return Expanded(
                  child: Center(
                    child: GestureDetector(
                      onTap: () => context.go('/reclamations'),
                      child: Container(
                        width: 56,
                        height: 56,
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.greenDark, AppColors.greenAccent],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.greenAccent.withValues(alpha: 0.5),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                );
              }

              final isActive = currentPath == tab.path ||
                  (tab.path == '/home' && currentPath == '/');

              return Expanded(
                child: GestureDetector(
                  onTap: () => context.go(tab.path),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        tab.icon,
                        size: 24,
                        color: isActive
                            ? AppColors.greenPrimary
                            : AppColors.textMuted,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tab.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                          color: isActive
                              ? AppColors.greenPrimary
                              : AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 3),
                      if (isActive)
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: AppColors.greenPrimary,
                            shape: BoxShape.circle,
                          ),
                        )
                      else
                        const SizedBox(height: 4),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final String label;
  final String path;
  const _TabItem({required this.icon, required this.label, required this.path});
}
