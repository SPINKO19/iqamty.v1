import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/language_provider.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../models/types.dart';
import '../core/theme/colors.dart';
import '../components/custom_menu_button.dart';

class RequestsView extends StatefulWidget {
  const RequestsView({super.key});

  @override
  State<RequestsView> createState() => _RequestsViewState();
}

class _RequestsViewState extends State<RequestsView> {
  String _selectedCategory = 'all_filter'; 

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LanguageProvider>();
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final firestore = context.watch<FirestoreService>();
    final userId = auth.currentStudent?.matricule ?? auth.currentUserData?['uid'] ?? '';
    final residenceId = auth.currentResidenceId ?? '';

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: Text(lp.getText('my_requests'), style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: context.appCard,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CustomMenuButton(
            backgroundColor: isDark 
                ? Colors.white.withValues(alpha: 0.1) 
                : AppColors.primary.withValues(alpha: 0.1),
            iconColor: isDark ? Colors.white : AppColors.primary,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: context.appCard,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildFilterChip('all_filter', lp.getText('all_filter')),
                  const SizedBox(width: 8),
                  _buildFilterChip('repair_category', lp.getText('repair_category')),
                  const SizedBox(width: 8),
                  _buildFilterChip('cleaning_category', lp.getText('cleaning_category')),
                  const SizedBox(width: 8),
                  _buildFilterChip('housing_category', lp.getText('housing_category')),
                ],
              ),
            ),
          ),
          
          Expanded(
            child: StreamBuilder<List<ServiceRequest>>(
              stream: firestore.getMyRequests(userId, residenceId: residenceId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'Erreur de base de données',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: context.appTextPrimary),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var requests = snapshot.data ?? [];

                if (_selectedCategory != 'all_filter') {
                  requests = requests.where((r) {
                    final cat = r.category.toLowerCase();
                    if (_selectedCategory == 'repair_category') return cat == 'repair' || cat == 'réparation';
                    if (_selectedCategory == 'cleaning_category') return cat == 'cleaning' || cat == 'nettoyage';
                    if (_selectedCategory == 'housing_category') return cat == 'housing' || cat == 'hébergement';
                    return true;
                  }).toList();
                }

                if (requests.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_late_outlined, size: 80, color: context.appTextSecondary.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text(
                          lp.getText('no_requests_found').isEmpty ? "Aucune demande trouvée." : lp.getText('no_requests_found'),
                          style: TextStyle(color: context.appTextSecondary, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    return _RequestCard(request: requests[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create-request'),
        label: Text(lp.getText('new_request'), style: const TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedCategory == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = key),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : context.appCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : context.appBorder,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : context.appTextPrimary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final ServiceRequest request;

  const _RequestCard({required this.request});

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
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIconBox(context),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              request.category.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: context.appTextSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          _buildStatusChip(context),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        request.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: context.appTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (request.imageUrl != null && request.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GestureDetector(
                  onTap: () => _showFullScreenImage(context, request.imageUrl!),
                  child: Image.network(
                    request.imageUrl!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(request.createdAt),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: context.appTextSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                _buildPriorityIndicator(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

   Widget _buildIconBox(BuildContext context) {
    IconData icon;
    Color color;
    
    switch (request.category.toLowerCase()) {
      case 'repair':
      case 'réparation':
        icon = Icons.plumbing_rounded;
        color = const Color(0xFF3B82F6); 
        break;
      case 'cleaning':
      case 'nettoyage':
        icon = Icons.ac_unit_rounded;
        color = const Color(0xFF14B8A6); 
        break;
      case 'housing':
      case 'hébergement':
        icon = Icons.electrical_services_rounded;
        color = const Color(0xFFF59E0B); 
        break;
      default:
        icon = Icons.assignment_rounded;
        color = const Color(0xFF10B981); 
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

   Widget _buildStatusChip(BuildContext context) {
    String label;
    Color color;
    
    switch (request.status.toLowerCase()) {
      case 'pending':
      case 'en attente':
        label = context.read<LanguageProvider>().getText('status_received');
        color = Colors.orange;
        break;
      case 'reviewed':
      case 'en cours':
        label = context.read<LanguageProvider>().getText('status_in_progress');
        color = Colors.blue;
        break;
      case 'completed':
      case 'résolu':
        label = context.read<LanguageProvider>().getText('status_resolved');
        color = Colors.green;
        break;
      default:
        label = request.status;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildPriorityIndicator(BuildContext context) {
    Color color;
    switch (request.priority) {
      case 'Haute':
        color = Colors.red;
        break;
      case 'Normale':
        color = Colors.orange;
        break;
      case 'Faible':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          request.priority,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: context.appTextSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  },
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
