import 'package:flutter/material.dart';
import '../components/custom_menu_button.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../models/types.dart';
import '../core/theme/colors.dart';
import '../providers/auth_provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firestore_service.dart';

const _kGreen = Color(0xFF2D6A4F);

class AdminComplaintsView extends StatelessWidget {
  const AdminComplaintsView({super.key});

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LanguageProvider>();
    final auth = context.watch<AuthProvider>();
    final firestore = context.read<FirestoreService>();
    final residenceId = auth.currentResidenceId;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreamBuilder<List<Complaint>>(
            stream: firestore.getAllComplaints(residenceId: residenceId),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              
              final complaints = snapshot.data ?? [];
              if (complaints.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      lp.getText('no_complaints_msg'),
                      style: GoogleFonts.inter(color: context.appTextSecondary),
                    ),
                  ),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final cardsPerRow = constraints.maxWidth > 800 ? 2 : 1;
                  return GridView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cardsPerRow,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                      mainAxisExtent: 250,
                    ),
                    itemCount: complaints.length,
                    itemBuilder: (context, index) => _AdminComplaintCard(complaint: complaints[index]),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAssignSheet(BuildContext context, Complaint complaint) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.appCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => _AssignWorkerSheet(complaintId: complaint.id!),
    );
  }

  void _showResolveDialog(BuildContext context, Complaint complaint) {
    final commentController = TextEditingController();
    final lp = context.read<LanguageProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.appCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(lp.getText('resolve'), style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: context.appTextPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Ajouter une réponse pour l'étudiant :", style: GoogleFonts.inter(color: context.appTextSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: commentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Expliquez comment le problème a été réglé...",
                hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
                filled: true,
                fillColor: context.appBackground.withValues(alpha: 0.5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              await context.read<FirestoreService>().updateComplaintStatus(
                complaint.id!,
                Status.resolved,
                adminComment: commentController.text,
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Confirmer", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
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
                    onPressed: complaint.status == Status.resolved ? null : () => const AdminComplaintsView()._showAssignSheet(context, complaint),
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
                    onPressed: complaint.status == Status.resolved ? null : () => const AdminComplaintsView()._showResolveDialog(context, complaint),
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                    label: Text(complaint.status == Status.resolved ? "Résolu" : lp.getText('resolve'), style: const TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: complaint.status == Status.resolved ? Colors.grey : _kGreen,
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

class _AssignWorkerSheet extends StatelessWidget {
  final String complaintId;
  const _AssignWorkerSheet({required this.complaintId});

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final lp = context.read<LanguageProvider>();

    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(lp.getText('assign'), style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: context.appTextPrimary)),
          const SizedBox(height: 8),
          Text("Sélectionnez un membre du personnel pour traiter cette réclamation.", style: GoogleFonts.inter(color: context.appTextSecondary)),
          const SizedBox(height: 24),
          Flexible(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: firestore.getWorkers(residenceId: context.read<AuthProvider>().currentResidenceId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final workers = snapshot.data ?? [];
                
                if (workers.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text("Aucun employé trouvé dans le système.", style: GoogleFonts.inter(color: Colors.red)),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: workers.length,
                  itemBuilder: (context, index) {
                    final worker = workers[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: _kGreen.withValues(alpha: 0.1),
                        child: Text(worker['displayName']?[0] ?? 'W', style: const TextStyle(color: _kGreen, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(worker['displayName'] ?? 'Unknown Worker', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: context.appTextPrimary)),
                      subtitle: Text(worker['department'] ?? 'General', style: GoogleFonts.inter(color: context.appTextSecondary, fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () async {
                        await firestore.assignComplaintToWorker(
                          complaintId: complaintId,
                          workerId: worker['uid'] ?? worker['id'],
                        );
                        if (context.mounted) Navigator.pop(context);
                      },
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
