import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../core/theme/colors.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminAnnouncementsView extends StatelessWidget {
  const AdminAnnouncementsView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lp = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          lp.getText('announcements_comm'),
          style: GoogleFonts.inter(color: context.appTextPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildActionCard(context, lp.getText('create_announcement'), lp.getText('communicate_residents'), Icons.campaign_rounded, AppColors.primary),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                lp.getText('message_history'),
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: context.appTextPrimary),
              ),
              Text(
                lp.getText('view_all'),
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildModernAnnouncementCard(context, lp, 'Coupure d\'électricité planifiée', 'Une maintenance électrique aura lieu demain de 14h à 16h au Bloc J.', 'Hier, 14:30', true),
          const SizedBox(height: 16),
          _buildModernAnnouncementCard(context, lp, 'Menu Spécial Week-end', 'Le menu de ce samedi sera composé de spécialités traditionnelles.', 'Lundi, 10:00', false),
          const SizedBox(height: 16),
          _buildModernAnnouncementCard(context, lp, 'Rappel: Paiement de loyer', 'N\'oubliez pas de régulariser votre situation avant le 5 du mois.', '01 Mars, 09:00', false),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        label: Text(lp.getText('broadcast'), style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.send_rounded),
        backgroundColor: AppColors.primary,
        elevation: 4,
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(subtitle, style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildModernAnnouncementCard(BuildContext context, LanguageProvider lp, String title, String body, String time, bool isUrgent) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isUrgent ? Colors.red.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isUrgent ? lp.getText('urgent') : lp.getText('info'),
                  style: GoogleFonts.inter(
                    color: isUrgent ? Colors.red : AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Text(time, style: GoogleFonts.inter(color: context.appTextSecondary.withValues(alpha: 0.6), fontSize: 11)),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: context.appTextPrimary)),
          const SizedBox(height: 6),
          Text(body, style: GoogleFonts.inter(color: context.appTextSecondary, fontSize: 13, height: 1.5)),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInteractionStat(Icons.visibility_outlined, '1.2k'),
              const SizedBox(width: 16),
              _buildInteractionStat(Icons.favorite_border_rounded, '45'),
              const Spacer(),
              Icon(Icons.share_outlined, size: 18, color: context.appTextSecondary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionStat(IconData icon, String count) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text(count, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
