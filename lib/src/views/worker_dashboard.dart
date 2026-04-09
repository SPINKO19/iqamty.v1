import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../core/theme/colors.dart';
import 'package:google_fonts/google_fonts.dart';

const _kGreen = Color(0xFF2D6A4F);

class WorkerDashboard extends StatelessWidget {
  const WorkerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _kGreen,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/login');
            }
          },
        ),
        title: Text(
          lp.getText('worker_space'),
          style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded, color: Colors.white)),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWorkerStats(context, lp),
            const SizedBox(height: 32),
            Text(
              lp.getText('my_assigned_tasks'),
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: context.appTextPrimary, letterSpacing: -0.5),
            ),
            const SizedBox(height: 16),
            _buildTaskCard(context, 'Réparation Plomberie', 'Bloc J - Chambre 414', lp.getText('urgent_status'), Colors.red),
            const SizedBox(height: 16),
            _buildTaskCard(context, 'Vérification Électricité', 'Bloc A - Couloir 2', lp.getText('new_status'), _kGreen),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerStats(BuildContext context, LanguageProvider lp) {
    return Row(
      children: [
        _buildStatItem(context, lp.getText('to_do'), '5', const Color(0xFFF4A261)),
        const SizedBox(width: 12),
        _buildStatItem(context, lp.getText('done_tasks'), '12', const Color(0xFF10B981)),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, Color color) {
    final isDark = context.isDark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.appCard,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isDark ? null : [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w900, color: color, letterSpacing: -1)),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.inter(color: context.appTextSecondary, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, String title, String location, String status, Color statusColor) {
    final isDark = context.isDark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark ? null : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: _kGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.assignment_outlined, color: _kGreen, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: context.appTextPrimary, letterSpacing: -0.3)),
                const SizedBox(height: 4),
                Text(location, style: GoogleFonts.inter(color: context.appTextSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(
              status,
              style: GoogleFonts.inter(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
