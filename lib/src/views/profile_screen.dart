import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/theme/colors.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final student = context.watch<AuthProvider>().currentStudent;
    final textTheme = Theme.of(context).textTheme;

    // Formatting date
    String dobFormatted = "01/01/2000";
    if (student?.dateNaissance != null) {
       try {
         // Assuming API format is something like "2000-01-01" or parseable date string
         DateTime parseDate = DateTime.parse(student!.dateNaissance!);
         dobFormatted = DateFormat('dd/MM/yyyy').format(parseDate);
       } catch (e) {
         dobFormatted = student!.dateNaissance!;
       }
    }

    final safeNomFr = student?.nomFr ?? '';
    final safePrenomFr = student?.prenomFr ?? '';
    final displayName = '$safeNomFr $safePrenomFr'.trim().isEmpty 
        ? "No Name Found" 
        : '$safeNomFr $safePrenomFr'.trim();

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: Text('Profil', style: TextStyle(color: context.appTextPrimary)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: context.appTextPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // User Header
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: context.appBorder,
                        child: ClipOval(
                          child: student?.photoBase64 != null 
                              ? Image.memory(
                                  base64Decode(student!.photoBase64!),
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                )
                              : student?.photo != null 
                                  ? Image.network(
                                      student!.photo!,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    )
                                  : Icon(Icons.person, size: 40, color: context.appTextSecondary),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 12),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    displayName,
                    style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    student?.residence ?? "Non assigné", 
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Action List
            _buildActionItem(context, Icons.article_outlined, 'Mes Annonces', () {}),
            const SizedBox(height: 12),
            _buildActionItem(context, Icons.person_outline, 'Informations Personnelles', () {}),
            const SizedBox(height: 12),
            _buildActionItem(
              context, 
              Icons.logout, 
              'Déconnexion', 
              () => _showLogoutConfirmation(context),
              isDestructive: true,
            ),
            
            const SizedBox(height: 40),
            
            // "MA CARTE DE RÉSIDENT" Title
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'MA CARTE DE RÉSIDENT',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ID Card Widget
            Container(
              decoration: BoxDecoration(
                color: context.appCard,
                borderRadius: BorderRadius.circular(24),
                boxShadow: context.isDark ? null : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(color: context.appBorder),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top of card: Logo & Republic Text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.school, color: Colors.white, size: 24),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                           Text(
                            'RÉPUBLIQUE ALGÉRIENNE',
                            style: textTheme.bodyMedium?.copyWith(fontSize: 8, fontWeight: FontWeight.bold),
                           ),
                           Text(
                            'DÉMOCRATIQUE ET POPULAIRE',
                            style: textTheme.bodyMedium?.copyWith(fontSize: 8, fontWeight: FontWeight.bold),
                           ),
                           const SizedBox(height: 8),
                           Text(
                            'CARTE RÉSIDENT',
                            style: textTheme.bodyMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                           ),
                           Text(
                            'بطاقة الإقامة',
                            style: textTheme.bodyMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                           ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Middle of card: Photo & Info
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo
                      Column(
                        children: [
                          Container(
                            width: 70,
                            height: 90,
                            decoration: BoxDecoration(
                              color: context.appBorder,
                              borderRadius: BorderRadius.circular(8),
                              image: student?.photoBase64 != null 
                                  ? DecorationImage(
                                      image: MemoryImage(base64Decode(student!.photoBase64!)),
                                      fit: BoxFit.cover,
                                    )
                                  : student?.photoEtudiant != null 
                                      ? DecorationImage(
                                          image: NetworkImage(student!.photoEtudiant!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                            ),
                            child: (student?.photoEtudiant == null && student?.photoBase64 == null) 
                                ? Icon(Icons.person, color: context.appTextSecondary) 
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NOM & PRÉNOM / الإسم و اللقب',
                              style: textTheme.bodyMedium?.copyWith(fontSize: 8, color: context.appTextSecondary),
                            ),
                            Text(
                              displayName.toUpperCase(),
                              style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 14, color: context.appTextPrimary),
                            ),
                            Text(
                              '${student?.nomAr ?? ''} ${student?.prenomAr ?? ''}'.trim().isEmpty 
                                  ? 'لا يوجد اسم' 
                                  : '${student?.nomAr ?? ''} ${student?.prenomAr ?? ''}'.trim(),
                              style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 14, color: context.appTextPrimary),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildInfoColumn(context, 'BLOC', student?.bloc ?? '—', textTheme),
                                _buildInfoColumn(context, 'N° CHAMBRE', student?.chambre ?? '—', textTheme),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildInfoColumn(context, 'DATE DE NAISSANCE', dobFormatted, textTheme),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Bottom of Card: Barcode & Validation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 30,
                            height: 40,
                            decoration: BoxDecoration(
                              border: Border.all(color: context.appBorder),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(Icons.qr_code, size: 20, color: context.appTextPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text('SCAN ID', style: textTheme.bodyMedium?.copyWith(fontSize: 8, color: context.appTextPrimary)),
                        ],
                      ),
                      // Fake barcode visual representation
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                               SizedBox(
                                height: 30,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: List.generate(30, (index) => Container(
                                    width: index % 3 == 0 ? 3 : index % 2 == 0 ? 1.5 : 2,
                                    height: index % 4 == 0 ? 20 : 30,
                                    color: Colors.black87,
                                  )),
                                ),
                               ),
                               const SizedBox(height: 4),
                               Text(
                                student?.matricule ?? '181831086934', 
                                textAlign: TextAlign.center,
                                style: textTheme.bodyMedium?.copyWith(fontSize: 10, letterSpacing: 2),
                               ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Divider(color: context.appBorder),
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ANNÉE: 2023/2024',
                        style: textTheme.bodyMedium?.copyWith(fontSize: 10, fontWeight: FontWeight.bold, color: context.appTextPrimary),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                             const Icon(Icons.circle, color: AppColors.success, size: 6),
                             const SizedBox(width: 4),
                             Text(
                              'VALIDE',
                              style: textTheme.bodyMedium?.copyWith(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.bold),
                             ),
                          ],
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(BuildContext context, String title, String value, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.bodyMedium?.copyWith(fontSize: 8, color: context.appTextSecondary),
        ),
        Text(
          value,
          style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 12, color: context.appTextPrimary),
        ),
      ],
    );
  }

  Widget _buildActionItem(BuildContext context, IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    final color = isDestructive ? AppColors.error : context.appTextPrimary;
    final iconColor = isDestructive ? AppColors.error : AppColors.primary;
    final bgIconColor = isDestructive ? AppColors.error.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.appCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.appBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgIconColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: context.appTextSecondary),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );
  }
}

