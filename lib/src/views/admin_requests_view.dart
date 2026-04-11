import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firestore_service.dart';
import '../models/types.dart';
import '../core/theme/colors.dart';

import '../components/custom_menu_button.dart';

const _kGreen = Color(0xFF2D6A4F);

class AdminRequestsView extends StatelessWidget {
  const AdminRequestsView({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CustomMenuButton(
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            iconColor: Colors.white,
          ),
        ),
        title: Text(
          'Gestion des Demandes',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _kGreen,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<ServiceRequest>>(
        stream: firestore.getAllRequests(),
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
              child: Text(
                'Aucune demande',
                style: TextStyle(color: context.appTextSecondary),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final request = requests[index];
              return _buildRequestCard(context, request, firestore);
            },
          );
        },
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
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                ),
            ],
          ),
          if (request.status != 'completed') ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showWorkerSelection(context, request, firestore),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Text('Assigner', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
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
                  stream: firestore.getWorkers(),
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
