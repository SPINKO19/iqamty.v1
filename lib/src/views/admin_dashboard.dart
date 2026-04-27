import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../providers/language_provider.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../models/types.dart';
import '../core/theme/colors.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LanguageProvider>();
    final auth = context.watch<AuthProvider>();
    final firestore = context.read<FirestoreService>();
    final resId = auth.currentResidenceId;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Grid
          _buildKpiGrid(context, lp, firestore, resId),
          const SizedBox(height: 16),

          // Middle Section (Tasks + Occupation)
          _buildMiddleSection(context, lp, firestore, resId),
          const SizedBox(height: 16),

          // Bottom Section (Recent Activity + Recent Requests)
          _buildBottomSection(context, lp, firestore, resId),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(BuildContext context, LanguageProvider lp, FirestoreService firestore, String? resId) {
    return MultiStreamBuilder(
      streams: [
        firestore.getStudents(residenceId: resId),
        firestore.getAllComplaints(residenceId: resId),
        firestore.getAllRequests(residenceId: resId),
      ],
      builder: (context, snapshots) {
        final students = (snapshots[0].data as List?) ?? [];
        final complaints = (snapshots[1].data as List<Complaint>?) ?? [];
        final requests = (snapshots[2].data as List<ServiceRequest>?) ?? [];

        final openComplaints = complaints.where((c) => c.status != Status.resolved).length;
        final resolvedComplaintsCount = complaints.where((c) => c.status == Status.resolved).length;
        final pendingRequests = requests.where((r) => r.status == 'pending').length;
        final urgentRequests = requests.where((r) => r.priority == 'Haute' && r.status == 'pending').length;

        final resolvedPercent = complaints.isEmpty ? 0 : (resolvedComplaintsCount / complaints.length * 100).toInt();

        return LayoutBuilder(
          builder: (context, constraints) {
            final cardsPerRow = constraints.maxWidth > 800 ? 4 : 2;
            final cardWidth = (constraints.maxWidth - (cardsPerRow - 1) * 10) / cardsPerRow;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildKpiCard(
                  context,
                  title: lp.getText('total_students'),
                  value: students.length.toString(),
                  tag: '+${students.length > 10 ? 12 : 0}',
                  isDark: true,
                  width: cardWidth,
                  onTap: () => context.go('/admin/users'),
                ),
                _buildKpiCard(
                  context,
                  title: lp.getText('complaints_open'),
                  value: openComplaints.toString(),
                  tag: '+3 auj.',
                  tagColor: context.appAlertBg,
                  tagTextColor: context.appErrorText,
                  width: cardWidth,
                  onTap: () => context.go('/admin/complaints'),
                ),
                _buildKpiCard(
                  context,
                  title: lp.getText('complaints_resolved_kpi'),
                  value: resolvedComplaintsCount.toString(),
                  tag: '$resolvedPercent%',
                  tagColor: context.appSuccessBg,
                  tagTextColor: context.appSuccessText,
                  width: cardWidth,
                  onTap: () => context.go('/admin/complaints'),
                ),
                _buildKpiCard(
                  context,
                  title: lp.getText('pending_requests_kpi'),
                  value: pendingRequests.toString(),
                  tag: '$urgentRequests urgent',
                  tagColor: context.appWarningBg,
                  tagTextColor: context.appWarningText,
                  width: cardWidth,
                  onTap: () => context.go('/admin/requests'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildKpiCard(
    BuildContext context, {
    required String title, 
    required String value, 
    required String tag, 
    Color? tagColor, 
    Color? tagTextColor, 
    bool isDark = false, 
    required double width,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0E2318) : context.appCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.appBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(color: isDark ? Colors.white54 : context.appTextSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value, style: GoogleFonts.inter(color: isDark ? Colors.white : context.appTextPrimary, fontSize: 24, fontWeight: FontWeight.w600)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: tagColor ?? Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(tag, style: GoogleFonts.inter(color: tagTextColor ?? (isDark ? Colors.white70 : Colors.black54), fontSize: 10, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiddleSection(BuildContext context, LanguageProvider lp, FirestoreService firestore, String? resId) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _buildPriorityActions(context, lp, firestore, resId)),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: _buildOccupationCard(context, lp, firestore, resId)),
            ],
          );
        } else {
          return Column(
            children: [
              _buildPriorityActions(context, lp, firestore, resId),
              const SizedBox(height: 16),
              _buildOccupationCard(context, lp, firestore, resId),
            ],
          );
        }
      },
    );
  }

  Widget _buildPriorityActions(BuildContext context, LanguageProvider lp, FirestoreService firestore, String? resId) {
    return _buildCardWrapper(
      context,
      title: lp.getText('priority_actions'),
      subtitle: lp.getText('manage_residence'),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: firestore.getAdminActivityFeed(residenceId: resId),
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];
          final urgentItems = items.where((item) => 
            (item['type'] == 'complaint' && item['priority'] != 'low' && item['status'] != 'Status.resolved') || 
            (item['type'] == 'request' && item['priority'] == 'Haute' && item['status'] == 'pending')
          ).take(5).toList();

          if (urgentItems.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('Aucune tâche prioritaire.', style: TextStyle(color: Colors.grey, fontSize: 12))),
            );
          }

          return Column(
            children: urgentItems.map((item) => _buildPriorityItem(context, item)).toList(),
          );
        },
      ),
    );
  }

  Widget _buildPriorityItem(BuildContext context, Map<String, dynamic> item) {
    final type = item['type'];
    final isComplaint = type == 'complaint';
    final title = item['title'] ?? item['category'] ?? 'Action requise';
    final who = isComplaint ? (item['department'] ?? 'Admin') : 'Admin';
    final color = item['status'] == 'resolved' ? Colors.green : (item['priority'] == 'Haute' || isComplaint ? Colors.red : Colors.orange);
    final route = isComplaint ? '/admin/complaints' : '/admin/requests';

    return InkWell(
      onTap: () => context.go(route),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: context.appBorder))),
        child: Row(
          children: [
            const SizedBox(width: 4),
            Expanded(
              child: Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: context.appTextPrimary)),
            ),
            Text(who, style: GoogleFonts.inter(fontSize: 10, color: context.appTextSecondary)),
            const SizedBox(width: 8),
            Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          ],
        ),
      ),
    );
  }

  Widget _buildOccupationCard(BuildContext context, LanguageProvider lp, FirestoreService firestore, String? resId) {
    return _buildCardWrapper(
      context,
      title: lp.getText('occupation_title'),
      child: StreamBuilder<Map<String, dynamic>>(
        stream: firestore.getResidenceSettings(resId ?? ''),
        builder: (context, snapshot) {
          final settings = snapshot.data ?? {};
          final total = settings['totalCapacity'] ?? 250;
          final occupied = settings['occupiedCount'] ?? 198;
          final percent = total == 0 ? 0 : (occupied / total * 100).toInt();

          return Column(
            children: [
              const SizedBox(height: 10),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      value: occupied / total,
                      strokeWidth: 10,
                      backgroundColor: context.isDark ? AppColors.primary.withValues(alpha: 0.1) : const Color(0xFFEAF3DE),
                      valueColor: AlwaysStoppedAnimation<Color>(context.isDark ? AppColors.primary : const Color(0xFF0E2318)),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$percent%', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: context.appTextPrimary)),
                      Text(lp.getText('occupied_label').toLowerCase(), style: GoogleFonts.inter(fontSize: 8, color: context.appTextSecondary)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildOccupationRow(context, lp.getText('occupied_label'), occupied, context.isDark ? AppColors.primary : const Color(0xFF0E2318)),
              _buildOccupationRow(context, lp.getText('free_label'), total - occupied, const Color(0xFF97C459)),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () => _showOccupationEditDialog(context, firestore, resId, total, occupied, lp),
                icon: const Icon(Icons.edit_rounded, size: 14),
                label: Text(lp.getText('edit'), style: const TextStyle(fontSize: 11)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOccupationRow(BuildContext context, String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 11, color: context.appTextSecondary))),
          Text(value.toString(), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: context.appTextPrimary)),
        ],
      ),
    );
  }

  Widget _buildBottomSection(BuildContext context, LanguageProvider lp, FirestoreService firestore, String? resId) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildActivityFeed(context, lp, firestore, resId)),
              const SizedBox(width: 16),
              Expanded(child: _buildRecentRequests(context, lp, firestore, resId)),
            ],
          );
        } else {
          return Column(
            children: [
              _buildActivityFeed(context, lp, firestore, resId),
              const SizedBox(height: 16),
              _buildRecentRequests(context, lp, firestore, resId),
            ],
          );
        }
      },
    );
  }

  Widget _buildActivityFeed(BuildContext context, LanguageProvider lp, FirestoreService firestore, String? resId) {
    return _buildCardWrapper(
      context,
      title: lp.getText('recent_activity_title'),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: firestore.getAdminActivityFeed(residenceId: resId),
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];
          if (items.isEmpty) return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text(lp.getText('no_posts'), style: const TextStyle(fontSize: 12, color: Colors.grey))));
          
          return Column(
            children: items.take(5).map((item) => _buildFeedItem(context, item, lp)).toList(),
          );
        },
      ),
    );
  }

  Widget _buildFeedItem(BuildContext context, Map<String, dynamic> item, LanguageProvider lp) {
    final type = item['type'];
    final title = item['title'] ?? item['category'] ?? lp.getText('activity_label');
    final subtitle = item['content'] ?? item['description'] ?? '';
    final timestamp = (item['feedTimestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    final timeStr = _formatTimeAgo(timestamp);
    
    Color dotColor = Colors.blue;
    String route = '/admin/announcements';
    if (type == 'complaint') {
      dotColor = Colors.red;
      route = '/admin/complaints';
    }
    if (type == 'request') {
      dotColor = item['status'] == 'completed' ? Colors.green : Colors.orange;
      route = '/admin/requests';
    }

    return InkWell(
      onTap: () => context.go(route),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: context.appBorder))),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 12),
              child: Container(width: 7, height: 7, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: context.appTextPrimary)),
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 11, color: context.appTextSecondary)),
                  const SizedBox(height: 4),
                  Text(timeStr, style: GoogleFonts.inter(fontSize: 9, color: context.appTextSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentRequests(BuildContext context, LanguageProvider lp, FirestoreService firestore, String? resId) {
    return _buildCardWrapper(
      context,
      title: lp.getText('recent_requests_title'),
      child: StreamBuilder<List<ServiceRequest>>(
        stream: firestore.getAllRequests(residenceId: resId),
        builder: (context, snapshot) {
          final requests = snapshot.data ?? [];
          if (requests.isEmpty) return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text(lp.getText('no_complaints_msg'), style: const TextStyle(fontSize: 12, color: Colors.grey))));

          return Column(
            children: requests.take(5).map((req) => _buildRequestItem(context, req, lp)).toList(),
          );
        },
      ),
    );
  }

  Widget _buildRequestItem(BuildContext context, ServiceRequest req, LanguageProvider lp) {
    final cat = req.category;
    Color chipColor = Colors.blue.shade100;
    Color textColor = Colors.blue.shade800;
    if (cat.contains('Renouvellement')) { chipColor = Colors.green.shade100; textColor = Colors.green.shade800; }
    if (cat.contains('Maintenance')) { chipColor = Colors.orange.shade100; textColor = Colors.orange.shade800; }

    return InkWell(
      onTap: () => context.go('/admin/requests'),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: context.appCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.appBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Center(child: Text('ST', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold))),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lp.getText('student'), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: context.appTextPrimary)),
                  Text('Ch.${req.userId.hashCode % 500}', style: GoogleFonts.inter(fontSize: 10, color: context.appTextSecondary)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: chipColor, borderRadius: BorderRadius.circular(20)),
              child: Text(cat, style: GoogleFonts.inter(color: textColor, fontSize: 9, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardWrapper(BuildContext context, {required String title, String? subtitle, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: context.appTextPrimary)),
                  if (subtitle != null) Text(subtitle, style: GoogleFonts.inter(fontSize: 10, color: context.appTextSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return DateFormat('dd/MM HH:mm').format(dateTime);
  }

  void _showOccupationEditDialog(BuildContext context, FirestoreService firestore, String? resId, int total, int occupied, LanguageProvider lp) {
    if (resId == null) return;
    final totalController = TextEditingController(text: total.toString());
    final occupiedController = TextEditingController(text: occupied.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.appCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: totalController, decoration: InputDecoration(labelText: lp.getText('total')), keyboardType: TextInputType.number),
            TextField(controller: occupiedController, decoration: InputDecoration(labelText: lp.getText('occupied_label')), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(lp.getText('cancel'))),
          ElevatedButton(
            onPressed: () {
              firestore.updateResidenceSettings(resId, {
                'totalCapacity': int.tryParse(totalController.text) ?? total,
                'occupiedCount': int.tryParse(occupiedController.text) ?? occupied,
              });
              Navigator.pop(context);
            },
            child: Text(lp.getText('confirm')),
          ),
        ],
      ),
    );
  }
}

// Helper widget for multiple streams
class MultiStreamBuilder extends StatelessWidget {
  final List<Stream> streams;
  final Widget Function(BuildContext, List<AsyncSnapshot>) builder;

  const MultiStreamBuilder({super.key, required this.streams, required this.builder});

  @override
  Widget build(BuildContext context) {
    return _buildStream(0, []);
  }

  Widget _buildStream(int index, List<AsyncSnapshot> snapshots) {
    return StreamBuilder(
      stream: streams[index],
      builder: (context, snapshot) {
        final currentSnapshots = List<AsyncSnapshot>.from(snapshots)..add(snapshot);
        if (index + 1 < streams.length) {
          return _buildStream(index + 1, currentSnapshots);
        }
        return builder(context, currentSnapshots);
      },
    );
  }
}
