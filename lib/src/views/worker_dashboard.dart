import 'package:flutter/material.dart';
import '../components/custom_menu_button.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../core/theme/colors.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/firestore_service.dart';
import '../providers/auth_provider.dart';
import '../models/types.dart';

const _kGreen = Color(0xFF2D6A4F);

class WorkerDashboard extends StatelessWidget {
  const WorkerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LanguageProvider>();
    final firestore = context.watch<FirestoreService>();
    final workerId = context.read<AuthProvider>().currentUserData?['uid'] ?? '';

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
        title: Text(
          lp.getText('worker_space'),
          style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded, color: Colors.white)),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<ServiceRequest>>(
        stream: firestore.getWorkerTasks(workerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final tasks = snapshot.data ?? [];
          final todoCount = tasks.where((t) => t.workerStatus != 'done').length.toString();
          final doneCount = tasks.where((t) => t.workerStatus == 'done').length.toString();

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWorkerStats(context, todoCount, doneCount),
                const SizedBox(height: 32),
                Text(
                  lp.getText('my_assigned_tasks'),
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: context.appTextPrimary, letterSpacing: -0.5),
                ),
                const SizedBox(height: 16),
                if (tasks.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          const Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune tâche assignée',
                            style: GoogleFonts.inter(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w600),
                          ),
                        ],
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
                      return _buildTaskCard(context, tasks[index], firestore);
                    },
                  ),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWorkerStats(BuildContext context, String todoCount, String doneCount) {
    return Row(
      children: [
        _buildStatItem(context, 'À faire', todoCount, const Color(0xFFF4A261)),
        const SizedBox(width: 12),
        _buildStatItem(context, 'Terminés', doneCount, const Color(0xFF10B981)),
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

  Widget _buildTaskCard(BuildContext context, ServiceRequest request, FirestoreService firestore) {
    final isDark = context.isDark;
    
    String statusLabel = '';
    Color statusColor = _kGreen;
    
    if (request.workerStatus == 'assigned') {
      statusLabel = 'Nouveau';
      statusColor = _kGreen;
    } else if (request.workerStatus == 'in_progress') {
      statusLabel = 'En cours';
      statusColor = Colors.orange;
    } else if (request.workerStatus == 'done') {
      statusLabel = 'Terminé';
      statusColor = Colors.green;
    } else {
      statusLabel = request.workerStatus ?? 'Inconnu';
      statusColor = Colors.grey;
    }

    final title = '${request.category.toUpperCase()} - ${request.description}';

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
        crossAxisAlignment: CrossAxisAlignment.start,
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
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: context.appTextPrimary, letterSpacing: -0.3)),
                    const SizedBox(height: 4),
                    Text(request.priority, style: GoogleFonts.inter(color: context.appTextSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.inter(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          if (request.workerStatus == 'assigned') ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => firestore.updateWorkerTaskStatus(requestId: request.id!, workerStatus: 'in_progress'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: statusColor.withValues(alpha: 0.1),
                  foregroundColor: statusColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text('Marquer en cours', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
          if (request.workerStatus == 'in_progress') ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => firestore.updateWorkerTaskStatus(requestId: request.id!, workerStatus: 'done'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.withValues(alpha: 0.1),
                  foregroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text('Marquer terminé', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
