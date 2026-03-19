import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/types.dart';
import '../services/firestore_service.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../core/theme/colors.dart';

class RequestListScreen extends StatelessWidget {
  final String category;

  const RequestListScreen({super.key, required this.category});

  String _getCategoryTitle(String category, LanguageProvider lp) {
    switch (category.toLowerCase()) {
      case 'repair':
      case 'réparation':
        return lp.getText('repair');
      case 'cleaning':
      case 'nettoyage':
        return lp.getText('cleaning');
      case 'housing':
      case 'hébergement':
        return lp.getText('housing');
      default:
        return category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LanguageProvider>();
    final auth = context.watch<AuthProvider>();
    final userId = auth.currentStudent?.matricule ?? auth.currentUserData?['uid'] ?? '';
    final firestore = context.watch<FirestoreService>();

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: Text(_getCategoryTitle(category, lp), style: TextStyle(color: context.appTextPrimary)),
        backgroundColor: context.appCard,
        iconTheme: IconThemeData(color: context.appTextPrimary),
        elevation: 0,
      ),
      body: StreamBuilder<List<ServiceRequest>>(
        stream: firestore.getMyRequests(userId, category: category),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data ?? [];

          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_late_outlined, size: 80, color: context.appTextSecondary.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text(
                    lp.getText('no_requests_found').isEmpty ? "Vous n'avez encore fait aucune demande." : lp.getText('no_requests_found'),
                    style: TextStyle(color: context.appTextSecondary, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return _RequestCard(request: request);
            },
          );
        },
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final ServiceRequest request;

  const _RequestCard({required this.request});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'reviewed':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(request.category),
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.category.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(request.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: context.appTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(request.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    request.status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(request.status),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              request.description,
              style: TextStyle(
                fontSize: 14,
                color: context.appTextPrimary,
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (request.imageUrl != null) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  request.imageUrl!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 150,
                    color: context.appBackground,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'repair':
      case 'réparation':
        return Icons.build_outlined;
      case 'cleaning':
      case 'nettoyage':
        return Icons.cleaning_services_outlined;
      case 'housing':
      case 'hébergement':
        return Icons.hotel_outlined;
      default:
        return Icons.help_outline;
    }
  }
}
