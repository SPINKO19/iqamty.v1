import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../models/types.dart';
import '../core/theme/colors.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

const _kGreen = Color(0xFF2D6A4F);

class AdminComplaintsView extends StatelessWidget {
  const AdminComplaintsView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lp = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _kGreen,
        foregroundColor: Colors.white,
        title: Text(
          lp.getText('complaints_management'),
          style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.filter_list_rounded, color: Colors.white)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.search_rounded, color: Colors.white)),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<Complaint>>(
        stream: Stream.value([]),
        builder: (context, snapshot) {
          final complaints = snapshot.data ?? [];
          if (complaints.isEmpty) {
            return _buildMockComplaints(context, lp);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: complaints.length,
            separatorBuilder: (context, index) => const SizedBox(height: 20),
            itemBuilder: (context, index) => _AdminComplaintCard(complaint: complaints[index]),
          );
        },
      ),
    );
  }

  Widget _buildMockComplaints(BuildContext context, LanguageProvider lp) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      children: [
        _AdminComplaintCard(
          complaint: Complaint(
            userId: '202433294616',
            title: 'Fuite d\'eau majeure',
            description: 'Inondation importante dans la salle de bain du Bloc J, chambre 414.',
            category: 'Plomberie',
            priority: Priority.high,
            status: Status.received,
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          ),
        ),
        const SizedBox(height: 20),
        _AdminComplaintCard(
          complaint: Complaint(
            userId: '202433294000',
            title: 'Problème d\'éclairage',
            description: 'Ampoule grillée et court-circuit suspecté dans la chambre 201 du Bloc A.',
            category: 'Électricité',
            priority: Priority.medium,
            status: Status.inProgress,
            timestamp: DateTime.now().subtract(const Duration(hours: 5)),
          ),
        ),
        const SizedBox(height: 20),
        _AdminComplaintCard(
          complaint: Complaint(
            userId: '202433294123',
            title: 'Serrure bloquée',
            description: 'La clé ne tourne plus dans la serrure de la porte principale du Bloc B.',
            category: 'Sécurité',
            priority: Priority.low,
            status: Status.received,
            timestamp: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ),
      ],
    );
  }
}

class _AdminComplaintCard extends StatelessWidget {
  final Complaint complaint;
  const _AdminComplaintCard({required this.complaint});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final priorityColor = _getPriorityColor(complaint.priority);
    final timeStr = DateFormat('HH:mm').format(complaint.timestamp);
    final lp = context.watch<LanguageProvider>();

    return Container(
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
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 6, height: 6, decoration: BoxDecoration(color: priorityColor, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(
                        _getPriorityLabel(complaint.priority, lp),
                        style: GoogleFonts.inter(color: priorityColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
                Text(
                  'ID: ${complaint.userId}',
                  style: GoogleFonts.inter(color: context.appTextSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(complaint.title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: context.appTextPrimary, letterSpacing: -0.3)),
                const SizedBox(height: 8),
                Text(complaint.description, style: GoogleFonts.inter(fontSize: 14, color: context.appTextSecondary, height: 1.5, fontWeight: FontWeight.w500)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildMetaInfo(context, Icons.inventory_2_outlined, complaint.category),
                    const SizedBox(width: 16),
                    _buildMetaInfo(context, Icons.access_time_rounded, timeStr),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Divider(height: 1, color: context.appBorder),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: Text(lp.getText('assign'), style: const TextStyle(fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(
                      foregroundColor: context.appTextPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                    label: Text(lp.getText('resolve'), style: const TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaInfo(BuildContext context, IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: context.appTextSecondary.withValues(alpha: 0.7)),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.inter(color: context.appTextSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Color _getPriorityColor(Priority p) {
    switch (p) {
      case Priority.high: return const Color(0xFFEF4444);
      case Priority.medium: return const Color(0xFFF59E0B);
      case Priority.low: return const Color(0xFF10B981);
    }
  }

  String _getPriorityLabel(Priority p, LanguageProvider lp) {
    switch (p) {
      case Priority.high: return lp.getText('priority_urgent');
      case Priority.medium: return lp.getText('priority_medium');
      case Priority.low: return lp.getText('priority_normal');
    }
  }
}
