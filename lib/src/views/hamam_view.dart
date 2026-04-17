import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../core/theme/colors.dart';
import '../components/custom_menu_button.dart';

class HamamView extends StatelessWidget {
  const HamamView({super.key});

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LanguageProvider>();
    
    final schedules = {
      'Dimanche': ['20:00 - 00:00'],
      'Lundi': ['17:00 - 22:00'],
      'Mardi': ['09:00 - 11:30', '17:00 - 22:00'],
      'Mercredi': ['17:30 - 23:00'],
      'Jeudi': ['17:30 - 23:00'],
      'Vendredi': ['07:00 - 11:30', '21:00 - 00:00'],
      'Samedi': ['07:00 - 11:30', '21:00 - 00:00'],
    };

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        title: Text(
          lp.getText('hamam_schedule'),
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
        ),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CustomMenuButton(
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            iconColor: Colors.white,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        physics: const BouncingScrollPhysics(),
        children: [
          ...schedules.entries.map((e) => _buildDayScheduleCard(context, e.key, e.value, Icons.shower_rounded)),
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
              decoration: BoxDecoration(color: context.appBackground.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(slot, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: context.appTextSecondary)),
                ],
              ),
            ),
          )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
