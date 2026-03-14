import 'package:flutter/material.dart';
import '../models/types.dart';
import '../core/theme/colors.dart';

class AdminComplaintsView extends StatelessWidget {
  const AdminComplaintsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Réclamations'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.filter_list_outlined)),
        ],
      ),
      body: StreamBuilder<List<Complaint>>(
        stream: Stream.value([]), 
        builder: (context, snapshot) {
          final complaints = snapshot.data ?? [];
          if (complaints.isEmpty) {
            return _buildMockComplaints();
          }
          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: complaints.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) => _AdminComplaintCard(complaint: complaints[index]),
          );
        },
      ),
    );
  }

  Widget _buildMockComplaints() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _AdminComplaintCard(
          complaint: Complaint(
            userId: '202433294616',
            title: 'Fuite d\'eau',
            description: 'Inondation dans la salle de bain du Bloc J.',
            category: 'Plomberie',
            priority: Priority.high,
            status: Status.received,
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          ),
        ),
        const SizedBox(height: 16),
        _AdminComplaintCard(
          complaint: Complaint(
            userId: '202433294000',
            title: 'Ampoule grillée',
            description: 'Besoin d\'un électricien pour la chambre 201.',
            category: 'Électricité',
            priority: Priority.low,
            status: Status.inProgress,
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
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderColor),
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
                  color: _getPriorityColor(complaint.priority).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  complaint.priority.toString().split('.').last.toUpperCase(),
                  style: TextStyle(color: _getPriorityColor(complaint.priority), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                'ID: ${complaint.userId}',
                style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(complaint.title, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(complaint.description, style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text('Assigner'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text('Résoudre', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Color _getPriorityColor(Priority p) {
    switch (p) {
      case Priority.high: return Colors.red;
      case Priority.medium: return Colors.orange;
      case Priority.low: return Colors.green;
    }
  }
}
