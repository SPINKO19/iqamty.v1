import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../core/theme/colors.dart';
import 'package:go_router/go_router.dart';

class WeightliftingView extends StatelessWidget {
  const WeightliftingView({super.key});

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LanguageProvider>();
    
    final schedules = {
      'Lundi - Vendredi': ['08:00 - 22:00'],
      'Samedi': ['10:00 - 18:00'],
      'Dimanche': ['Fermé'],
    };

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        title: Text(
          lp.getText('weightlifting_schedule'),
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        physics: const BouncingScrollPhysics(),
        children: [
          ...schedules.entries.map((e) => _buildDayScheduleCard(context, e.key, e.value, Icons.fitness_center_rounded)),
        ],
      ),
    );
  }

  Widget _buildDayScheduleCard(BuildContext context, String day, List<String> slots, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Text(day, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: context.appTextPrimary)),
              ],
            ),
          ),
          ...slots.map((slot) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: context.appBackground.withOpacity(0.5), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(slot, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: context.appTextSecondary)),
                ],
              ),
            ),
          )).toList(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
