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

class DiningView extends StatelessWidget {
  const DiningView({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = context.watch<FirestoreService>();
    final auth = context.watch<AuthProvider>();
    final residenceId = auth.currentResidenceId ?? auth.currentUserData?['residenceId'] as String?;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          'Restaurant',
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
          if (info == null) {
            return _buildEmptyState(context);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusBanner(context, info.isOpen),
                const SizedBox(height: 24),
                
                if (info.isOpen) ...[
                  _buildMealCard(context, 'Petit-déjeuner', info.breakfast, Icons.coffee_rounded, const Color(0xFFF4A261), isDark)
                      .animate().fade().slideY(begin: 0.2, duration: 400.ms),
                  const SizedBox(height: 20),
                  _buildMealCard(context, 'Déjeuner', info.lunch, Icons.wb_sunny_rounded, const Color(0xFF2A9D8F), isDark)
                      .animate().fade().slideY(begin: 0.2, delay: 100.ms, duration: 400.ms),
                  const SizedBox(height: 20),
                  _buildMealCard(context, 'Dîner', info.dinner, Icons.nightlight_round, const Color(0xFF264653), isDark)
                      .animate().fade().slideY(begin: 0.2, delay: 200.ms, duration: 400.ms),
                ] else
                  _buildClosedState(context),
                  
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBanner(BuildContext context, bool isOpen) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOpen 
            ? [const Color(0xFF2D6A4F), const Color(0xFF40916C)]
            : [const Color(0xFF9B2226), const Color(0xFFBB3E03)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isOpen ? const Color(0xFF2D6A4F) : const Color(0xFF9B2226)).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOpen ? Icons.restaurant_rounded : Icons.no_food_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOpen ? 'Le Restaurant est Ouvert' : 'Restaurant Fermé',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  isOpen ? 'Bon appétit à tous les étudiants !' : 'Revenez plus tard pour le prochain repas.',
                  style: GoogleFonts.outfit(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (isOpen)
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            ).animate(onPlay: (c) => c.repeat()).scale(duration: 1.seconds, begin: const Offset(1,1), end: const Offset(1.5, 1.5)).fade(begin: 1, end: 0),
        ],
      ),
    );
  }

  Widget _buildMealCard(BuildContext context, String title, RestaurantMeal meal, IconData icon, Color accentColor, bool isDark) {
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
                    meal.menu.isNotEmpty ? meal.menu : 'Menu non disponible pour le moment.',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      height: 1.6,
                      color: context.appTextPrimary.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu_rounded, size: 80, color: Colors.grey.withValues(alpha: 0.2)),
          const SizedBox(height: 20),
          Text(
            'Aucun menu publié',
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: context.appTextPrimary),
          ),
          Text(
            'L\'administration n\'a pas encore configuré le menu.',
            style: GoogleFonts.outfit(color: context.appTextSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildClosedState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.no_food_rounded, size: 80, color: Colors.red.withValues(alpha: 0.3)),
          ),
          const SizedBox(height: 24),
          Text(
            'Période de Fermeture',
            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: context.appTextPrimary),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Le restaurant est actuellement fermé. Veuillez consulter les horaires d\'ouverture habituels.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: context.appTextSecondary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
