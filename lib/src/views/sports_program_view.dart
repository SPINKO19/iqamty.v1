import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../core/theme/colors.dart';
import 'package:go_router/go_router.dart';

class SportsProgramView extends StatelessWidget {
  const SportsProgramView({super.key});

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LanguageProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header with Background Image
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            stretch: true,
            backgroundColor: isDark ? const Color(0xFF121212) : AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
              title: Text(
                lp.getText('sports_and_showers'),
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: -0.5,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                   // Image representing a sports hall with volleyball, football, basketball
                  Image.network(
                    'https://images.unsplash.com/photo-1541534741688-6078c6bfb5c5?q=80&w=1000&auto=format&fit=crop',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                       return Container(
                         color: AppColors.primary,
                         child: const Center(child: Icon(Icons.sports_basketball, color: Colors.white54, size: 80)),
                       );
                    },
                  ),
                  // Dark gradient overlay
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.1),
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(24.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionHeader(context, lp.getText('sports_program'), Icons.sports_volleyball_rounded),
                const SizedBox(height: 16),
                _buildSportsSchedule(context),
                
                const SizedBox(height: 32),
                
                _buildSectionHeader(context, lp.getText('team_registration'), Icons.group_add_rounded),
                const SizedBox(height: 16),
                _buildTeamRegistrationSection(context, lp),
                
                const SizedBox(height: 32),
                
                _buildSectionHeader(context, lp.getText('mens_showers'), Icons.shower_rounded),
                const SizedBox(height: 16),
                _buildShowerSchedule(context),
                
                const SizedBox(height: 48), // Bottom padding
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSportsSchedule(BuildContext context) {
    final schedules = {
      'Samedi': ['17:00 - 19:00 (Foot INT)', '21:00 - 23:30 (Foot NAT/INT)'],
      'Dimanche': ['17:00 - 18:30 (Volley-ball NAT/INT)', '18:30 - 21:30 (Foot ET/NAT)', '21:30 - 23:30 (Foot ET/INT)'],
      'Lundi': ['17:00 - 18:30 (Basket-ball NAT/INT)', '18:30 - 20:00 (Volley-ball NAT/INT)', '20:00 - 21:30 (Foot ET/INT)', '21:30 - 23:30 (Foot ET/NAT)'],
      'Mardi': ['17:00 - 18:30 (Hand-ball NAT/INT)', '18:30 - 21:30 (Foot ET/NAT)', '21:30 - 23:30 (Foot ET/INT)'],
      'Mercredi': ['17:00 - 18:30 (Basket-ball NAT/INT)', '18:30 - 20:30 (Foot ET/INT)', '20:30 - 23:30 (Foot ET/NAT)'],
      'Jeudi': ['17:00 - 18:30 (Hand-ball NAT/INT)', '18:30 - 20:30 (Foot ET/INT)', '20:30 - 23:30 (Foot ET/NAT)'],
      'Vendredi': ['17:00 - 20:00 (Foot ET/NAT)', '20:30 - 21:30 (Volley-ball)', '21:30 - 23:30 (Foot ET/INT)'],
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: schedules.entries.map((e) => _buildDayScheduleCard(context, e.key, e.value, Icons.sports_kabaddi_rounded)).toList(),
    );
  }

  Widget _buildShowerSchedule(BuildContext context) {
    final schedules = {
      'Dimanche': ['20:00 - 00:00'],
      'Lundi': ['17:00 - 22:00'],
      'Mardi': ['09:00 - 11:30', '17:00 - 22:00'],
      'Mercredi': ['17:30 - 23:00'],
      'Jeudi': ['17:30 - 23:00'],
      'Vendredi': ['07:00 - 11:30', '21:00 - 00:00'],
      'Samedi': ['07:00 - 11:30', '21:00 - 00:00'],
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: schedules.entries.map((e) => _buildDayScheduleCard(context, e.key, e.value, Icons.shower_rounded)).toList(),
    );
  }

  Widget _buildDayScheduleCard(BuildContext context, String day, List<String> slots, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF333333) : const Color(0xFFE2E8F0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  day,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: slots.map((slot) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 14, color: AppColors.primary.withValues(alpha: 0.7)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        slot,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).textTheme.bodyLarge?.color,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamRegistrationSection(BuildContext context, LanguageProvider lp) {
    return Column(
      children: [
        _buildTeamCard(context, lp.getText('football'), Icons.sports_soccer_rounded, lp),
        const SizedBox(height: 12),
        _buildTeamCard(context, lp.getText('volleyball'), Icons.sports_volleyball_rounded, lp),
        const SizedBox(height: 12),
        _buildTeamCard(context, lp.getText('basketball'), Icons.sports_basketball_rounded, lp),
      ],
    );
  }

  Widget _buildTeamCard(BuildContext context, String teamName, IconData icon, LanguageProvider lp) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF333333) : const Color(0xFFE2E8F0);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(
          teamName,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        trailing: ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(lp.getText('registration_sent_msg')),
                backgroundColor: AppColors.primary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: Text(
            lp.getText('join_team'),
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ),
    );
  }
}
