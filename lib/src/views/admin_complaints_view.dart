import 'package:flutter/material.dart';
import '../models/types.dart';
import '../core/theme/colors.dart';
import 'package:intl/intl.dart';

class AdminComplaintsView extends StatelessWidget {
  const AdminComplaintsView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Gestion des Réclamations',
          style: TextStyle(
            color: context.appTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.filter_list_rounded, color: context.appTextPrimary),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.search_rounded, color: context.appTextPrimary),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<Complaint>>(
        stream: Stream.value([]),
        builder: (context, snapshot) {
          final complaints = snapshot.data ?? [];
          if (complaints.isEmpty) {
            return _buildMockComplaints(context);
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

  Widget _buildMockComplaints(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      children: [
        _AdminComplaintCard(
          complaint: Complaint(
            userId: '202433294616',
            title: 'Fuite d\'eau majeure',
            description: 'Inondation importante dans la salle de bain du Bloc J, chambre 414. L\'eau commence à couler dans le couloir.',
            category: 'Plomberie',
            priority: Priority.high,
            status: Status.received,
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
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
            createdAt: DateTime.now().subtract(const Duration(hours: 5)),
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
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
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
    final timeStr = DateFormat('HH:mm').format(complaint.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.appBorder),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header with Priority and ID
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: priorityColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getPriorityLabel(complaint.priority),
                        style: TextStyle(
                          color: priorityColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'ID: ${complaint.userId}',
                  style: TextStyle(
                    color: context.appTextSecondary,
                    fontSize: 12,
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Content Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  complaint.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.appTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  complaint.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: context.appTextSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
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

          const SizedBox(height: 20),
          Divider(height: 1, color: context.appBorder),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: const Text('Assigner'),
                    style: TextButton.styleFrom(
                      foregroundColor: context.appTextPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                    label: const Text('Résoudre'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
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
        Icon(icon, size: 16, color: context.appTextSecondary),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: context.appTextSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
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

  String _getPriorityLabel(Priority p) {
    switch (p) {
      case Priority.high: return 'URGENT';
      case Priority.medium: return 'MOYEN';
      case Priority.low: return 'NORMAL';
    }
  }
}
