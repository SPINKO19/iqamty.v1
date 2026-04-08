import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../models/types.dart';
import '../services/firestore_service.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../core/theme/colors.dart';

class RequestListScreen extends StatefulWidget {
  final String category;

  const RequestListScreen({super.key, required this.category});

  @override
  State<RequestListScreen> createState() => _RequestListScreenState();
}

class _RequestListScreenState extends State<RequestListScreen> {
  String _selectedFilter = 'Tous'; // 'Tous', 'En cours', 'Résolus'

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

    const kMediumGreen = Color(0xFF2D6A4F);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: Text(
          _getCategoryTitle(widget.category, lp),
          style: GoogleFonts.inter(
            color: isDark ? context.appCard : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: const Color(0xFF2D6A4F),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              children: [
                _buildFilterChip('Tous'),
                const SizedBox(width: 8),
                _buildFilterChip('En cours'),
                const SizedBox(width: 8),
                _buildFilterChip('Résolus'),
              ],
            ),
          ),
          
          // Request List
          Expanded(
            child: StreamBuilder<List<ServiceRequest>>(
              stream: firestore.getMyRequests(userId, category: widget.category),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var requests = snapshot.data ?? [];

                // Secondary Filtering logic
                if (_selectedFilter == 'En cours') {
                  requests = requests.where((r) => r.status.toLowerCase() != 'completed' && r.status.toLowerCase() != 'résolu').toList();
                } else if (_selectedFilter == 'Résolus') {
                  requests = requests.where((r) => r.status.toLowerCase() == 'completed' || r.status.toLowerCase() == 'résolu').toList();
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/create-request', arguments: widget.category),
        backgroundColor: kMediumGreen,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2D6A4F) : context.appCard,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isSelected ? Colors.transparent : context.appBorder,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: isSelected ? Colors.white : context.appTextPrimary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
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
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Box
                _buildIconBox(),
                const SizedBox(width: 16),
                
                // Content
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
                                color: Colors.grey,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          _buildStatusChip(),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        request.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: context.appTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
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

  Widget _buildIconBox() {
    IconData icon;
    Color color;
    
    switch (request.category.toLowerCase()) {
      case 'repair':
      case 'réparation':
        icon = Icons.plumbing_rounded;
        color = const Color(0xFF3B82F6); // Blue
        break;
      case 'cleaning':
      case 'nettoyage':
        icon = Icons.ac_unit_rounded;
        color = const Color(0xFF14B8A6); // Teal
        break;
      case 'housing':
      case 'hébergement':
        icon = Icons.electrical_services_rounded;
        color = const Color(0xFFF59E0B); // Yellow/Orange
        break;
      default:
        icon = Icons.assignment_rounded;
        color = const Color(0xFF10B981); // Green
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: color, size: 26),
    );
  }

  Widget _buildStatusChip() {
    String label;
    Color color;
    
    switch (request.status.toLowerCase()) {
      case 'pending':
      case 'en attente':
        label = 'En attente';
        color = Colors.orange;
        break;
      case 'reviewed':
      case 'en cours':
        label = 'En cours';
        color = Colors.blue;
        break;
      case 'completed':
      case 'résolu':
        label = 'Résolu';
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
}
