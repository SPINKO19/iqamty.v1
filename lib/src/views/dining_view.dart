import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../providers/language_provider.dart';
import '../models/types.dart';
import '../core/theme/colors.dart';

class DiningView extends StatelessWidget {
  const DiningView({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = context.watch<FirestoreService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lp = context.watch<LanguageProvider>();

    final now = DateTime.now();
    final currentTimeInMinutes = now.hour * 60 + now.minute;
    final bool isRestaurantOpen = (currentTimeInMinutes >= 420 && currentTimeInMinutes <= 510) || // 07:00 - 08:30
                                  (currentTimeInMinutes >= 720 && currentTimeInMinutes <= 840) || // 12:00 - 14:00
                                  (currentTimeInMinutes >= 1110 && currentTimeInMinutes <= 1230); // 18:30 - 20:30

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark 
                    ? [const Color(0xFF121212), Colors.black]
                    : [const Color(0xFF121212), const Color(0xFF000000)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.restaurant_menu_rounded, color: Color(0xFFEF4444), size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lp.getText('service_of'),
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              lp.getText('dining_service'),
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: isRestaurantOpen ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: isRestaurantOpen ? const Color(0xFF10B981) : const Color(0xFFEF4444), 
                                    blurRadius: 4
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              isRestaurantOpen ? lp.getText('restaurant_open') : (lp.currentLocale.languageCode == 'ar' ? 'المطعم مغلق' : (lp.currentLocale.languageCode == 'en' ? 'Restaurant Closed' : 'Restaurant Fermé')),
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          lp.getText('today'),
                          style: GoogleFonts.inter(
                            color: Colors.white60,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          StreamBuilder<List<Meal>>(
            stream: firestore.getTodayMeals(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())));
              }
              if (snapshot.hasError) {
                return SliverToBoxAdapter(child: Center(child: Text('Erreur: ${snapshot.error}')));
              }
              final meals = snapshot.data ?? [];
              if (meals.isEmpty) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.restaurant_menu_outlined, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun repas prévu pour aujourd\'hui',
                            style: GoogleFonts.inter(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final meal = meals[index];
                      final type = meal.type;
                      final menu = meal.menu;

                      String time = '';
                      String title = '';
                      IconData icon = Icons.restaurant;
                      Color color = const Color(0xFFEF4444);

                      if (type == 'Breakfast' || type == 'Petit-déjeuner') {
                        time = '07:00 - 08:30';
                        title = lp.getText('breakfast');
                        icon = Icons.coffee_rounded;
                        color = const Color(0xFFF59E0B);
                      } else if (type == 'Lunch' || type == 'Déjeuner') {
                        time = '12:00 - 14:00';
                        title = lp.getText('lunch');
                        icon = Icons.lunch_dining_rounded;
                        color = color;
                      } else if (type == 'Dinner' || type == 'Dîner') {
                        time = '18:30 - 20:00';
                        title = lp.getText('dinner');
                        icon = Icons.dinner_dining_rounded;
                        color = const Color(0xFF6366F1);
                      } else {
                        title = type;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: _buildModernMealCard(
                          context,
                          lp: lp,
                          title: title,
                          time: time,
                          menu: menu,
                          icon: icon,
                          color: color,
                          isHighlight: type == 'Lunch' || type == 'Déjeuner',
                        ),
                      );
                    },
                    childCount: meals.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModernMealCard(
    BuildContext context, {
    required LanguageProvider lp,
    required String title,
    required String time,
    required String menu,
    required IconData icon,
    required Color color,
    bool isHighlight = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isHighlight ? color.withValues(alpha: 0.3) : context.appBorder,
          width: isHighlight ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          color: context.appTextPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        time,
                        style: GoogleFonts.inter(
                          color: context.appTextSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isHighlight)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      lp.getText('in_progress'),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.03),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lp.getText('menu_composition'),
                  style: GoogleFonts.inter(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  menu,
                  style: GoogleFonts.inter(
                    color: context.appTextPrimary,
                    fontSize: 15,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showRatingDialog(context, title),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: List.generate(5, (index) => 
                        Icon(Icons.star_rounded, color: index < 4 ? Colors.amber : Colors.grey.withValues(alpha: 0.3), size: 18)
                      ),
                    ),
                    Text(
                      lp.getText('rate_meal'),
                      style: GoogleFonts.inter(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog(BuildContext context, String mealName) {
    int rating = 0;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: context.appCard,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(
                'Noter $mealName',
                style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Comment était votre repas ?',
                    style: TextStyle(color: context.appTextSecondary),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: Colors.amber,
                          size: 40,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          setState(() {
                            rating = index + 1;
                          });
                        },
                      );
                    }).map((w) => Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: w)).toList(),
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Annuler', style: TextStyle(color: context.appTextSecondary, fontWeight: FontWeight.w600)),
                ),
                ElevatedButton(
                  onPressed: rating > 0
                      ? () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Merci pour votre évaluation !'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(100, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Envoyer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

