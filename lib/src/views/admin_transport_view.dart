import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../models/types.dart';
import '../core/theme/colors.dart';

class AdminTransportView extends StatefulWidget {
  const AdminTransportView({super.key});

  @override
  State<AdminTransportView> createState() => _AdminTransportViewState();
}

class _AdminTransportViewState extends State<AdminTransportView> {
  void _showAddDialog(BuildContext context, FirestoreService firestore, String residenceId) {
    final titleController = TextEditingController();
    final timeController = TextEditingController();
    final fromController = TextEditingController();
    final toController = TextEditingController();
    final busNumberController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.appCard,
        title: Text(
          "Ajouter un transport",
          style: GoogleFonts.inter(color: context.appTextPrimary, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(titleController, "Titre (ex: Bus Université)", context),
              const SizedBox(height: 12),
              _buildTextField(timeController, "Heure (ex: 08:00)", context),
              const SizedBox(height: 12),
              _buildTextField(fromController, "Lieu de départ", context),
              const SizedBox(height: 12),
              _buildTextField(toController, "Lieu d'arrivée", context),
              const SizedBox(height: 12),
              _buildTextField(busNumberController, "Numéro du bus", context),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Annuler", style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (titleController.text.isEmpty || timeController.text.isEmpty) return;

              final schedule = TransportSchedule(
                title: titleController.text.trim(),
                time: timeController.text.trim(),
                from: fromController.text.trim(),
                to: toController.text.trim(),
                busNumber: busNumberController.text.trim(),
                residenceId: residenceId,
              );

              await firestore.addTransportSchedule(schedule, residenceId: residenceId);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Ajouter"),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, BuildContext context) {
    return TextField(
      controller: controller,
      style: TextStyle(color: context.appTextPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: context.appTextSecondary),
        filled: true,
        fillColor: context.appBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final firestore = context.watch<FirestoreService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String residenceId = auth.currentResidenceId ?? '';

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.appTextPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          "Gestion Transport",
          style: GoogleFonts.inter(
            color: context.appTextPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, firestore, residenceId),
        backgroundColor: const Color(0xFF3B82F6),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<List<TransportSchedule>>(
        stream: firestore.getTransportSchedules(residenceId: residenceId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Erreur de chargement", style: GoogleFonts.inter(color: Colors.red)));
          }

          final schedules = snapshot.data ?? [];

          if (schedules.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_bus_filled_outlined, size: 64, color: Colors.grey.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text(
                    "Aucun transport programmé",
                    style: GoogleFonts.inter(color: context.appTextSecondary, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            physics: const BouncingScrollPhysics(),
            itemCount: schedules.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final schedule = schedules[index];
              return Container(
                decoration: BoxDecoration(
                  color: context.appCard,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.directions_bus_rounded, color: Color(0xFF3B82F6), size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              schedule.title,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: context.appTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${schedule.time} • De ${schedule.from ?? "-"} à ${schedule.to ?? "-"}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: context.appTextSecondary,
                              ),
                            ),
                            if (schedule.busNumber != null && schedule.busNumber!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Bus ${schedule.busNumber}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF3B82F6),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                        onPressed: () => firestore.deleteTransportSchedule(schedule.id!),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
