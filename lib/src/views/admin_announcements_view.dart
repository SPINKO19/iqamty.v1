import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../core/theme/colors.dart';
import 'package:google_fonts/google_fonts.dart';

const _kGreen = Color(0xFF2D6A4F);

class AdminAnnouncementsView extends StatelessWidget {
  const AdminAnnouncementsView({super.key});

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _kGreen,
        foregroundColor: Colors.white,
        title: Text(
          lp.getText('announcements_comm'),
          style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        actions: [
          LayoutBuilder(
            builder: (context, constraints) {
              // We check against the screen width here
              final screenWidth = MediaQuery.of(context).size.width;
              if (screenWidth > 800) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: Text(lp.getText('broadcast'), style: const TextStyle(fontWeight: FontWeight.w900)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 800;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildActionCard(context, lp.getText('create_announcement'), lp.getText('communicate_residents'), Icons.campaign_rounded, _kGreen),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          lp.getText('message_history'),
                          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18, color: context.appTextPrimary, letterSpacing: -0.5),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            lp.getText('view_all'),
                            style: GoogleFonts.inter(fontSize: 13, color: _kGreen, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (isDesktop)
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 24,
                        mainAxisSpacing: 24,
                        childAspectRatio: 1.5,
                        children: [
                          _buildModernAnnouncementCard(context, lp, 'Coupure d\'électricité planifiée', 'Une maintenance électrique aura lieu demain de 14h à 16h au Bloc J.', 'Hier, 14:30', true),
                          _buildModernAnnouncementCard(context, lp, 'Menu Spécial Week-end', 'Le menu de ce samedi sera composé de spécialités traditionnelles.', 'Lundi, 10:00', false),
                          _buildModernAnnouncementCard(context, lp, 'Rappel: Paiement de loyer', 'N\'oubliez pas de régulariser votre situation avant le 5 du mois.', '01 Mars, 09:00', false),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _buildModernAnnouncementCard(context, lp, 'Coupure d\'électricité planifiée', 'Une maintenance électrique aura lieu demain de 14h à 16h au Bloc J.', 'Hier, 14:30', true),
                          const SizedBox(height: 16),
                          _buildModernAnnouncementCard(context, lp, 'Menu Spécial Week-end', 'Le menu de ce samedi sera composé de spécialités traditionnelles.', 'Lundi, 10:00', false),
                          const SizedBox(height: 16),
                          _buildModernAnnouncementCard(context, lp, 'Rappel: Paiement de loyer', 'N\'oubliez pas de régulariser votre situation avant le 5 du mois.', '01 Mars, 09:00', false),
                        ],
                      ),
                  ],
                ),
              );
            }
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        label: Text(lp.getText('broadcast'), style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 15)),
        icon: const Icon(Icons.send_rounded),
        backgroundColor: _kGreen,
        foregroundColor: Colors.white,
        elevation: 6,
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                const SizedBox(height: 8),
                Text(subtitle, style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildModernAnnouncementCard(BuildContext context, LanguageProvider lp, String title, String body, String time, bool isUrgent) {
    final isDark = context.isDark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark ? null : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 5)),
        ],
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
                  color: isUrgent ? Colors.red.withValues(alpha: 0.1) : _kGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isUrgent ? lp.getText('urgent') : lp.getText('info'),
                  style: GoogleFonts.inter(
                    color: isUrgent ? Colors.red : _kGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Text(time, style: GoogleFonts.inter(color: context.appTextSecondary.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 17, color: context.appTextPrimary, letterSpacing: -0.3)),
          const SizedBox(height: 8),
          Text(body, style: GoogleFonts.inter(color: context.appTextSecondary, fontSize: 13, height: 1.5, fontWeight: FontWeight.w500)),
          const SizedBox(height: 20),
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
        Icon(icon, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 6),
        Text(count, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.bold)),
      ],
    );
  }
}
