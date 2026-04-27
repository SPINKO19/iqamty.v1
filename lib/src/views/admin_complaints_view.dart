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
                hintStyle: GoogleFonts.inter(fontSize: 14, color: context.appTextSecondary),
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
            child: Text("Confirmer", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  static void showComplaintDetails(BuildContext context, Complaint complaint) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AdminComplaintDetailsSheet(complaint: complaint),
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

    return LayoutBuilder(
      builder: (context, constraints) {
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
                    Text(
                      complaint.description,
                      style: GoogleFonts.inter(fontSize: 14, color: context.appTextSecondary, height: 1.5, fontWeight: FontWeight.w500),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
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
              const SizedBox(height: 12),
              Divider(height: 1, color: context.appBorder),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: constraints.maxWidth > 350 ? (constraints.maxWidth - 44) / 2 : constraints.maxWidth - 32,
                      child: TextButton.icon(
                        onPressed: () => AdminComplaintsView.showComplaintDetails(context, complaint),
                        icon: const Icon(Icons.info_outline_rounded, size: 18),
                        label: FittedBox(child: Text(lp.getText('details'), style: const TextStyle(fontWeight: FontWeight.bold))),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          backgroundColor: AppColors.primary.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: constraints.maxWidth > 350 ? (constraints.maxWidth - 44) / 2 : constraints.maxWidth - 32,
                      child: TextButton.icon(
                        onPressed: complaint.status == Status.resolved ? null : () => const AdminComplaintsView()._showAssignSheet(context, complaint),
                        icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                        label: FittedBox(child: Text(lp.getText('assign'), style: const TextStyle(fontWeight: FontWeight.bold))),
                        style: TextButton.styleFrom(
                          foregroundColor: context.appTextPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          backgroundColor: context.appTextPrimary.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
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
              ),
            ],
          ),
        );
      },
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

class _AdminComplaintDetailsSheet extends StatelessWidget {
  final Complaint complaint;
  const _AdminComplaintDetailsSheet({required this.complaint});

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LanguageProvider>();
    final firestore = context.read<FirestoreService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      lp.getText('details').toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        letterSpacing: 1,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  complaint.title,
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: context.appTextPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 14, color: context.appTextSecondary),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('dd MMMM yyyy HH:mm').format(complaint.timestamp),
                      style: GoogleFonts.inter(color: context.appTextSecondary, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Submitter Info
                _buildSectionHeader(lp.getText('submitted_by')),
                const SizedBox(height: 12),
                FutureBuilder<Map<String, dynamic>?>(
                  future: firestore.getUserById(complaint.userId),
                  builder: (context, snapshot) {
                    final userData = snapshot.data;
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? context.appBackground : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            child: Text(
                              userData?['displayName']?[0] ?? 'U',
                              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userData?['displayName'] ?? 'Utilisateur ID: ${complaint.userId}',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: context.appTextPrimary),
                                ),
                                if (userData != null) ...[
                                  Text(
                                    "Matricule: ${userData['matricule'] ?? userData['uid'] ?? 'N/A'}",
                                    style: GoogleFonts.inter(fontSize: 12, color: context.appTextSecondary, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    "Bloc: ${userData['bloc'] ?? 'N/A'} • Chambre: ${userData['room'] ?? userData['chambre'] ?? 'N/A'}",
                                    style: GoogleFonts.inter(fontSize: 12, color: context.appTextSecondary),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 32),
                _buildSectionHeader(lp.getText('detailed_description')),
                const SizedBox(height: 12),
                Text(
                  complaint.description,
                  style: GoogleFonts.inter(fontSize: 16, color: context.appTextPrimary, height: 1.6),
                ),

                if (complaint.imageUrl != null) ...[
                  const SizedBox(height: 32),
                  _buildSectionHeader(lp.getText('photo_optional')),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      complaint.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                        height: 200,
                        width: double.infinity,
                        color: Colors.grey.withValues(alpha: 0.1),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image_outlined, color: Colors.grey, size: 40),
                            SizedBox(height: 8),
                            Text("Impossible de charger l'image", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],

                // Assigned Worker Info
                if (complaint.assignedWorkerId != null) ...[
                  const SizedBox(height: 32),
                  _buildSectionHeader(lp.getText('assigned_to')),
                  const SizedBox(height: 12),
                  FutureBuilder<Map<String, dynamic>?>(
                    future: firestore.getUserById(complaint.assignedWorkerId!),
                    builder: (context, snapshot) {
                      final workerData = snapshot.data;
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _kGreen.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _kGreen.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: _kGreen.withValues(alpha: 0.1),
                              child: Text(
                                workerData?['displayName']?[0] ?? 'W',
                                style: const TextStyle(color: _kGreen, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    workerData?['displayName'] ?? 'Ouvrier ID: ${complaint.assignedWorkerId}',
                                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: context.appTextPrimary),
                                  ),
                                  if (workerData != null)
                                    Text(
                                      workerData['department'] ?? 'Général',
                                      style: GoogleFonts.inter(fontSize: 12, color: context.appTextSecondary),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _kGreen,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                lp.getText('status_in_progress').toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],

                if (complaint.adminComment != null && complaint.adminComment!.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  _buildSectionHeader("RÉPONSE ADMINISTRATIVE"),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                    ),
                    child: Text(
                      complaint.adminComment!,
                      style: GoogleFonts.inter(fontSize: 15, color: context.appTextPrimary, height: 1.5),
                    ),
                  ),
                ],
                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        color: Colors.grey,
        letterSpacing: 1.2,
      ),
    );
  }
}
