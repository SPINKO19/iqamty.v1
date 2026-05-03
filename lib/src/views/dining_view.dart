import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/colors.dart';
import '../services/firestore_service.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../models/types.dart';
import '../components/custom_menu_button.dart';

class DiningView extends StatefulWidget {
  const DiningView({super.key});

  @override
  State<DiningView> createState() => _DiningViewState();
}

class _DiningViewState extends State<DiningView> {
  int _selectedDayIndex = 0;

  @override
  Widget build(BuildContext context) {
    final firestore = context.watch<FirestoreService>();
    final auth = context.watch<AuthProvider>();
    final residenceId = auth.currentResidenceId ?? auth.currentUserData?['residenceId'] as String?;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userId = auth.currentUserData?['uid'] ?? '';

    final lp = context.watch<LanguageProvider>();
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: context.appBackground,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CustomMenuButton(
            backgroundColor: isDark 
                ? Colors.white.withValues(alpha: 0.05) 
                : AppColors.primary.withValues(alpha: 0.05),
            iconColor: isDark ? Colors.white : AppColors.primary,
          ),
        ),
        title: Text(
          lp.getText('restaurant_title'),
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: context.appTextPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<RestaurantInfo?>(
        stream: firestore.streamRestaurantInfo(residenceId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final info = snapshot.data;
          if (info == null || info.days.isEmpty) {
            return _buildEmptyState(context, lp);
          }

          final currentDay = info.days[_selectedDayIndex < info.days.length ? _selectedDayIndex : 0];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDateSelector(info.days, lp),
                const SizedBox(height: 24),
                
                _buildMealCard(context, lp.getText('breakfast_label'), currentDay.breakfast, Icons.coffee_rounded, const Color(0xFFF4A261), isDark, 'breakfast', residenceId!, userId, _selectedDayIndex, lp)
                    .animate().fade().slideY(begin: 0.2, duration: 400.ms),
                const SizedBox(height: 20),
                _buildMealCard(context, lp.getText('lunch_label'), currentDay.lunch, Icons.wb_sunny_rounded, const Color(0xFF2A9D8F), isDark, 'lunch', residenceId, userId, _selectedDayIndex, lp)
                    .animate().fade().slideY(begin: 0.2, delay: 100.ms, duration: 400.ms),
                const SizedBox(height: 20),
                _buildMealCard(context, lp.getText('dinner_label'), currentDay.dinner, Icons.nightlight_round, const Color(0xFF264653), isDark, 'dinner', residenceId, userId, _selectedDayIndex, lp)
                    .animate().fade().slideY(begin: 0.2, delay: 200.ms, duration: 400.ms),
                  
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateSelector(List<RestaurantDay> days, LanguageProvider lp) {
    return Container(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = _selectedDayIndex == index;
          final isDark = Theme.of(context).brightness == Brightness.dark;
          
          String dayName = '';
          final now = DateTime.now();
          final diff = DateTime(day.date.year, day.date.month, day.date.day).difference(DateTime(now.year, now.month, now.day)).inDays;
          
          if (diff == 0) dayName = lp.getText('today_label');
          else if (diff == 1) dayName = lp.getText('tomorrow_label');
          else {
            final daysList = [
              lp.getText('monday'), 
              lp.getText('tuesday'), 
              lp.getText('wednesday'), 
              lp.getText('thursday'), 
              lp.getText('friday'), 
              lp.getText('saturday'), 
              lp.getText('sunday')
            ];
            dayName = daysList[day.date.weekday - 1];
          }

          return GestureDetector(
            onTap: () => setState(() => _selectedDayIndex = index),
            child: AnimatedContainer(
              duration: 300.ms,
              width: 110,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: isSelected 
                  ? LinearGradient(colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)])
                  : null,
                color: isSelected ? null : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.transparent : context.appBorder.withValues(alpha: 0.5),
                ),
                boxShadow: isSelected ? [
                  BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))
                ] : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayName,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white.withValues(alpha: 0.8) : context.appTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.date.day}/${day.date.month}',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : context.appTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMealCard(BuildContext context, String title, RestaurantMeal meal, IconData icon, Color accentColor, bool isDark, String mealKey, String residenceId, String userId, int dayIndex, LanguageProvider lp) {
    final bool isReserved = meal.isReserved(userId);
    final bool hasRated = meal.hasRated(userId);
    return Container(
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: context.appBorder.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (meal.imageUrl != null && meal.imageUrl!.isNotEmpty)
              Stack(
                children: [
                  Image.network(
                    meal.imageUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: accentColor.withValues(alpha: 0.1),
                      child: Icon(Icons.broken_image_rounded, color: accentColor),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(icon, color: accentColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            title,
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: context.appTextPrimary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${meal.startTime} - ${meal.endTime}',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    meal.menu.isNotEmpty ? meal.menu : lp.getText('menu_not_available'),
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      height: 1.6,
                      color: context.appTextPrimary.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Interaction Row
                  Row(
                    children: [
                      // Reservation Button
                       Expanded(
                        child: _buildActionButton(
                          context,
                          isReserved ? Icons.check_circle_rounded : Icons.bookmark_add_rounded,
                          isReserved ? lp.getText('reserved_status') : lp.getText('reserve_action'),
                          isReserved ? Colors.green : AppColors.primary,
                          () => context.read<FirestoreService>().toggleRestaurantMealReservation(
                            residenceId, 
                            dayIndex,
                            mealKey, 
                            userId
                          ),
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Rating Button
                      Expanded(
                        child: _buildActionButton(
                          context,
                          hasRated ? Icons.star_rounded : Icons.star_outline_rounded,
                          hasRated ? '${meal.averageRating.toStringAsFixed(1)}' : lp.getText('rate_action'),
                          const Color(0xFFFFB703),
                          hasRated ? null : () => _showRatingDialog(context, residenceId, dayIndex, mealKey, userId, lp),
                          isDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label, Color color, VoidCallback? onTap, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRatingDialog(BuildContext context, String resId, int dayIndex, String mealKey, String userId, LanguageProvider lp) {
    double selectedRating = 5.0;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(lp.getText('rate_meal_title'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(lp.getText('how_was_meal'), style: GoogleFonts.inter(color: Colors.grey)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: const Color(0xFFFFB703),
                      size: 32,
                    ),
                    onPressed: () => setState(() => selectedRating = index + 1.0),
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(lp.getText('cancel_btn'), style: GoogleFonts.outfit(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<FirestoreService>().rateRestaurantMeal(resId, dayIndex, mealKey, selectedRating, userId);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(lp.getText('confirm_btn'), style: GoogleFonts.outfit(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, LanguageProvider lp) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu_rounded, size: 80, color: Colors.grey.withValues(alpha: 0.2)),
          const SizedBox(height: 20),
          Text(
            lp.getText('no_menu_published'),
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: context.appTextPrimary),
          ),
          Text(
            lp.getText('admin_not_configured_menu'),
            style: GoogleFonts.outfit(color: context.appTextSecondary),
          ),
        ],
      ),
    );
  }
}
