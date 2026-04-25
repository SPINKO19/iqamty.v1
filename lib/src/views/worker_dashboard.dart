import 'package:flutter/material.dart';
import '../components/custom_menu_button.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../core/theme/colors.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firestore_service.dart';
import '../providers/auth_provider.dart';
import '../models/types.dart';
import 'package:go_router/go_router.dart';

const _kGreen = Color(0xFF2D6A4F);

class WorkerDashboard extends StatelessWidget {
  const WorkerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LanguageProvider>();
    final auth = context.watch<AuthProvider>();
    final firestore = context.watch<FirestoreService>();
    final userId = auth.currentUserData?['id']?.toString() ?? auth.currentUserData?['uid']?.toString() ?? '';

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _kGreen,
        foregroundColor: Colors.white,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CustomMenuButton(
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            iconColor: Colors.white,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lp.getText('worker_space'),
              style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: -0.5, fontSize: 18),
            ),
            if (auth.currentUserData?['residenceName'] != null)
              Text(
                auth.currentUserData!['residenceName'],
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70),
              ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => context.go('/profile'), 
            icon: const Icon(Icons.person_outline_rounded, color: Colors.white),
          ),
          IconButton(
            onPressed: () {}, 
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<ServiceRequest>>(
        stream: firestore.getWorkerTasks(userId),
        builder: (context, taskSnapshot) {
          return StreamBuilder<List<Complaint>>(
            stream: firestore.getAllComplaints(residenceId: auth.currentResidenceId),
            builder: (context, complaintSnapshot) {
              if (taskSnapshot.connectionState == ConnectionState.waiting && complaintSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: _kGreen));
              }
              final tasks = taskSnapshot.data ?? [];
              final allComplaints = complaintSnapshot.data ?? [];
              
              // Only show active complaints that are not resolved globally
              final pendingComplaints = allComplaints.where((c) => c.status != Status.resolved).toList();

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuickActions(context, lp, firestore, userId, auth.currentResidenceId, auth.currentUserData?['displayName'] ?? 'Ouvrier'),
                    const SizedBox(height: 32),
                    Text(
                      lp.getText('statistics') == 'statistics' ? 'Statistiques' : lp.getText('statistics'),
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: context.appTextPrimary, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 16),
                    _buildWorkerStats(context, lp, tasks, pendingComplaints),
                    const SizedBox(height: 32),
                    Text(
                      lp.getText('my_assigned_tasks') == 'my_assigned_tasks' ? 'Mes tâches assignées' : lp.getText('my_assigned_tasks'),
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: context.appTextPrimary, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 16),
                    if (tasks.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Text(
                            "Aucune tâche assignée",
                            style: GoogleFonts.inter(color: context.appTextSecondary),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: tasks.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          Color statusColor = _kGreen;
                          if (task.priority.toLowerCase() == 'haute' || task.priority.toLowerCase() == 'high') statusColor = Colors.red;
                          if (task.status.toLowerCase() == 'completed' || task.status.toLowerCase() == 'resolved') statusColor = const Color(0xFF10B981);
                          if (task.status.toLowerCase() == 'pending') statusColor = const Color(0xFFF4A261);
                          
                          return _buildTaskCard(context, task, statusColor, firestore);
                        },
                      ),
                    
                    if (pendingComplaints.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      Text(
                        'Réclamations globales (À gérer)',
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: context.appTextPrimary, letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 16),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: pendingComplaints.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          return _buildComplaintCard(context, pendingComplaints[index], firestore);
                        },
                      ),
                    ],
                    const SizedBox(height: 100),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildWorkerStats(BuildContext context, LanguageProvider lp, List<ServiceRequest> tasks, List<Complaint> pendingComplaints) {
    final done = tasks.where((t) => t.status.toLowerCase() == 'completed' || t.status.toLowerCase() == 'resolved').length;
    final toDo = tasks.length - done + pendingComplaints.length;

    return Row(
      children: [
        _buildStatItem(context, lp.getText('to_do') == 'to_do' ? 'À faire' : lp.getText('to_do'), toDo.toString(), const Color(0xFFF4A261)),
        const SizedBox(width: 12),
        _buildStatItem(context, lp.getText('done_tasks') == 'done_tasks' ? 'Terminées' : lp.getText('done_tasks'), done.toString(), const Color(0xFF10B981)),
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

  Widget _buildTaskCard(BuildContext context, ServiceRequest task, Color statusColor, FirestoreService firestore) {
    final isDark = context.isDark;
    final isCompleted = task.status.toLowerCase() == 'completed' || task.status.toLowerCase() == 'resolved';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark ? null : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          Row(
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
                    Text(task.category.toUpperCase(), style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: context.appTextPrimary, letterSpacing: -0.3)),
                    const SizedBox(height: 4),
                    Text(task.description, style: GoogleFonts.inter(color: context.appTextSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  task.status,
                  style: GoogleFonts.inter(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          if (!isCompleted && task.id != null) ...[
            const SizedBox(height: 16),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    await firestore.updateWorkerTaskStatus(
                      requestId: task.id!,
                      workerStatus: 'done',
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 18),
                  label: Text('Marquer comme terminé', style: GoogleFonts.inter(color: const Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12)),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildComplaintCard(BuildContext context, Complaint complaint, FirestoreService firestore) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark ? null : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(complaint.title.toUpperCase(), style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: context.appTextPrimary, letterSpacing: -0.3)),
                    const SizedBox(height: 4),
                    Text(complaint.description, style: GoogleFonts.inter(color: context.appTextSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () async {
                  await firestore.updateComplaintStatus(
                    complaint.id!,
                    Status.resolved,
                    adminComment: 'Problème pris en charge et résolu par l\'équipe technique.',
                  );
                },
                icon: const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 18),
                label: Text('Prendre en charge et terminer', style: GoogleFonts.inter(color: const Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12)),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.1),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, LanguageProvider lp, FirestoreService firestore, String userId, String? residenceId, String userName) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        mainAxisExtent: 130,
      ),
      children: [
        _buildActionCard(
          context,
          'Réclamation Admin',
          'Signaler un problème',
          Icons.report_problem_rounded,
          const Color(0xFFEF4444),
          () => _showReclamationDialog(context, lp, firestore, userId, residenceId),
        ),
        _buildActionCard(
          context,
          'Discussion Admin',
          'Contacter la direction',
          Icons.chat_bubble_rounded,
          const Color(0xFF3B82F6),
          () async {
             final chatId = await firestore.startOrGetChat(userId, userName, residenceId: residenceId, role: 'worker');
             if (context.mounted) {
               context.push('/chat/$chatId', extra: {'name': 'Administration', 'isAdmin': false});
             }
          },
          badgeStream: firestore.getAllChats().map((list) {
            return list.any((c) => c['studentId'] == userId && c['hasUnreadStudent'] == true);
          }),
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap, {Stream<bool>? badgeStream}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark ? null : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Stack(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const Spacer(),
                    Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: context.appTextPrimary)),
                    Text(subtitle, style: GoogleFonts.inter(fontSize: 9, color: context.appTextSecondary)),
                  ],
                ),
              ),
            ),
          ),
          if (badgeStream != null)
            Positioned(
              top: 12,
              right: 12,
              child: StreamBuilder<bool>(
                stream: badgeStream,
                initialData: false,
                builder: (context, snapshot) {
                  if (snapshot.data == true) {
                    return Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
        ],
      ),
    );
  }

  void _showReclamationDialog(BuildContext context, LanguageProvider lp, FirestoreService firestore, String userId, String? residenceId) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final deptController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déposer une réclamation'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Sujet')),
              TextField(controller: deptController, decoration: const InputDecoration(labelText: 'Département concerné')),
              TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              final complaint = Complaint(
                userId: userId,
                title: titleController.text.trim(),
                description: descController.text.trim(),
                category: 'Personnel',
                priority: Priority.medium,
                status: Status.received,
                timestamp: DateTime.now(),
                department: deptController.text.trim(),
              );
              await firestore.submitComplaint(complaint, residenceId: residenceId);
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }
}
