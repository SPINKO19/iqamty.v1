import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../providers/auth_provider.dart';
import '../models/types.dart';
import '../core/theme/colors.dart';

class ComplaintsView extends StatelessWidget {
  const ComplaintsView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final firestore = context.read<FirestoreService>();
    final userId = auth.currentStudent?.matricule ?? auth.currentUserData?['uid'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Réclamations'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Complaint>>(
        stream: firestore.getMyComplaints(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final complaints = snapshot.data ?? [];
          if (complaints.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_turned_in_outlined, size: 64, color: AppColors.textSecondary),
                  SizedBox(height: 16),
                  Text('Vous n\'avez aucune réclamation', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: complaints.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) => _ComplaintCard(complaint: complaints[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSubmissionSheet(context),
        label: const Text('Nouvelle Réclamation'),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showSubmissionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _ComplaintSubmissionSheet(),
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  final Complaint complaint;
  const _ComplaintCard({required this.complaint});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(complaint.status);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                complaint.category.toUpperCase(),
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  complaint.status.toString().split('.').last,
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(complaint.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            complaint.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(Status status) {
    switch (status) {
      case Status.received: return Colors.blue;
      case Status.inProgress: return Colors.orange;
      case Status.resolved: return Colors.green;
    }
  }
}

class _ComplaintSubmissionSheet extends StatelessWidget {
  const _ComplaintSubmissionSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Nouvelle Réclamation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 24),
          const TextField(
            decoration: InputDecoration(
              hintText: 'Titre de la réclamation',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Expanded(
            child: TextField(
              maxLines: null,
              expands: true,
              decoration: InputDecoration(
                hintText: 'Décrivez votre problème en détail...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _UploadPlaceholder(),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Envoyer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderColor, style: BorderStyle.solid), // Should be dashed in premium but solid for now
        borderRadius: BorderRadius.circular(12),
        color: AppColors.backgroundLight,
      ),
      child: const Column(
        children: [
          Icon(Icons.camera_alt_outlined, color: AppColors.primary),
          SizedBox(height: 8),
          Text('Ajouter une photo (Optionnel)'),
        ],
      ),
    );
  }
}
