import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firestore_service.dart';
import '../models/types.dart';
import '../core/theme/colors.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';

import '../components/custom_menu_button.dart';
import 'package:intl/intl.dart';

const _kGreen = Color(0xFF2D6A4F);

class AdminRequestsView extends StatelessWidget {
  const AdminRequestsView({super.key});

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
          StreamBuilder<List<ServiceRequest>>(
            stream: firestore.getAllRequests(residenceId: residenceId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: _kGreen));
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Erreur: ${snapshot.error}',
                    style: TextStyle(color: context.appTextPrimary),
                  ),
                );
              }

              final requests = snapshot.data ?? [];
              if (requests.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
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
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cardsPerRow,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      mainAxisExtent: 215,
                    ),
                    itemCount: requests.length,
                    itemBuilder: (context, index) => _buildRequestCard(context, requests[index], firestore),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, ServiceRequest request, FirestoreService firestore) {
    Color statusColor = Colors.orange;
    String statusLabel = 'En attente';
    if (request.status == 'reviewed') {
      statusColor = Colors.blue;
      statusLabel = 'Assignée';
    } else if (request.status == 'completed') {
      statusColor = Colors.green;
      statusLabel = 'Terminée';
    }

    Color priorityColor = Colors.orange;
    if (request.priority.toLowerCase() == 'haute') priorityColor = Colors.red;
    if (request.priority.toLowerCase() == 'faible') priorityColor = Colors.green;

    final isAssigned = request.assignedWorkerId != null;

    return Container(
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                request.category.toUpperCase(),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: context.appTextPrimary,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: priorityColor),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    request.priority,
                    style: TextStyle(color: context.appTextSecondary, fontSize: 12),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 8),
          Text(
            request.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: context.appTextSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.inter(fontSize: 12, color: statusColor, fontWeight: FontWeight.w600),
                ),
              ),
              const Spacer(),
              if (isAssigned)
                Text(
                  'Assigné ✓',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                )
              else
                Text(
                  'Non assigné',
                  style: GoogleFonts.inter(fontSize: 12, color: context.appTextSecondary),
                ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => AdminRequestsView.showRequestDetails(context, request),
                  icon: const Icon(Icons.info_outline_rounded, size: 18),
                  label: const Text('Détails', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.05),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (request.status != 'completed')
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showWorkerSelection(context, request, firestore),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Assigner', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static void showRequestDetails(BuildContext context, ServiceRequest request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AdminRequestDetailsSheet(request: request),
    );
  }
}

class _AdminRequestDetailsSheet extends StatelessWidget {
  final ServiceRequest request;
  const _AdminRequestDetailsSheet({required this.request});

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
                  request.category,
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
                      DateFormat('dd MMMM yyyy HH:mm').format(request.createdAt),
                      style: GoogleFonts.inter(color: context.appTextSecondary, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Submitter Info
                _buildSectionHeader(lp.getText('submitted_by')),
                const SizedBox(height: 12),
                FutureBuilder<Map<String, dynamic>?>(
                  future: firestore.getUserById(request.userId),
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
                                  userData?['displayName'] ?? 'Utilisateur ID: ${request.userId}',
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
                  request.description,
                  style: GoogleFonts.inter(fontSize: 16, color: context.appTextPrimary, height: 1.6),
                ),

                if (request.imageUrl != null) ...[
                  const SizedBox(height: 32),
                  _buildSectionHeader(lp.getText('photo_optional')),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      request.imageUrl!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],

                // Assigned Worker Info
                if (request.assignedWorkerId != null) ...[
                  const SizedBox(height: 32),
                  _buildSectionHeader(lp.getText('assigned_to')),
                  const SizedBox(height: 12),
                  FutureBuilder<Map<String, dynamic>?>(
                    future: firestore.getUserById(request.assignedWorkerId!),
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
                                    workerData?['displayName'] ?? 'Ouvrier ID: ${request.assignedWorkerId}',
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
                          ],
                        ),
                      );
                    },
                  ),
                ],

                if (request.adminResponseText != null && request.adminResponseText!.isNotEmpty) ...[
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
                      request.adminResponseText!,
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

  void _showWorkerSelection(BuildContext context, ServiceRequest request, FirestoreService firestore) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.appCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Choisir un travailleur',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.appTextPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: firestore.getWorkers(residenceId: context.read<AuthProvider>().currentResidenceId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: _kGreen));
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Erreur de récupération : ${snapshot.error}',
                          style: TextStyle(color: context.appTextPrimary),
                        ),
                      );
                    }

                    final workers = snapshot.data ?? [];
                    if (workers.isEmpty) {
                      return Center(
                        child: Text(
                          'Aucun travailleur trouvé',
                          style: TextStyle(color: context.appTextSecondary),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: workers.length,
                      itemBuilder: (context, index) {
                        final worker = workers[index];
                        final workerId = worker['id'] ?? worker['uid'] ?? '';
                        final displayName = worker['displayName'] ?? worker['name'] ?? 'Inconnu';
                        final department = worker['department'] ?? 'Général';
                        final initial = displayName.toString().isNotEmpty 
                            ? displayName.toString()[0].toUpperCase() 
                            : 'W';

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _kGreen.withValues(alpha: 0.2),
                            child: Text(initial, style: const TextStyle(color: _kGreen, fontWeight: FontWeight.bold)),
                          ),
                          title: Text(
                            displayName,
                            style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            department,
                            style: TextStyle(color: context.appTextSecondary),
                          ),
                          onTap: () async {
                            if (request.id != null && workerId.isNotEmpty) {
                              try {
                                await firestore.assignRequestToWorker(
                                  requestId: request.id!,
                                  workerId: workerId,
                                );
                                if (bottomSheetContext.mounted) {
                                  Navigator.pop(bottomSheetContext);
                                }
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Demande assignée avec succès'),
                                      backgroundColor: _kGreen,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Erreur: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
