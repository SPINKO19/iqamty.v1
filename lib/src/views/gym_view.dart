import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../core/theme/colors.dart';
import '../components/custom_menu_button.dart';

class GymView extends StatelessWidget {
  const GymView({super.key});

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LanguageProvider>();

    final schedules = {
      'Samedi': ['17:00 - 19:00 (Foot INT)', '21:00 - 23:30 (Foot NAT/INT)'],
      'Dimanche': ['17:00 - 18:30 (Volley-ball NAT/INT)', '18:30 - 21:30 (Foot ET/NAT)', '21:30 - 23:30 (Foot ET/INT)'],
      'Lundi': ['17:00 - 18:30 (Basket-ball NAT/INT)', '18:30 - 20:00 (Volley-ball NAT/INT)', '20:00 - 21:30 (Foot ET/INT)', '21:30 - 23:30 (Foot ET/NAT)'],
      'Mardi': ['17:00 - 18:30 (Hand-ball NAT/INT)', '18:30 - 21:30 (Foot ET/NAT)', '21:30 - 23:30 (Foot ET/INT)'],
      'Mercredi': ['17:00 - 18:30 (Basket-ball NAT/INT)', '18:30 - 20:30 (Foot ET/INT)', '20:30 - 23:30 (Foot ET/NAT)'],
      'Jeudi': ['17:00 - 18:30 (Hand-ball NAT/INT)', '18:30 - 20:30 (Foot ET/INT)', '20:30 - 23:30 (Foot ET/NAT)'],
      'Vendredi': ['17:00 - 20:00 (Foot ET/NAT)', '20:30 - 21:30 (Volley-ball)', '21:30 - 23:30 (Foot ET/INT)'],
    };

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        title: Text(
          lp.getText('gym_schedule'),
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
          ...schedules.entries.map((e) => _buildDayScheduleCard(context, e.key, e.value, Icons.sports_basketball_rounded)),
          const SizedBox(height: 24),
          _buildSectionHeader(context, lp.getText('team_registration'), Icons.group_add_rounded),
          const SizedBox(height: 16),
          _buildTeamCard(context, lp.getText('football'), Icons.sports_soccer_rounded, lp),
          const SizedBox(height: 12),
          _buildTeamCard(context, lp.getText('volleyball'), Icons.sports_volleyball_rounded, lp),
          const SizedBox(height: 12),
          _buildTeamCard(context, lp.getText('basketball'), Icons.sports_basketball_rounded, lp),
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

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(width: 16),
        Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: context.appTextPrimary)),
      ],
    );
  }

  Widget _buildTeamCard(BuildContext context, String teamName, IconData icon, LanguageProvider lp) {
    return Container(
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(teamName, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: context.appTextPrimary)),
        trailing: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          child: Text(lp.getText('join_team')),
        ),
      ),
    );
  }
}
