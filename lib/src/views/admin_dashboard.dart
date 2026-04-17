import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../providers/language_provider.dart';
import '../core/theme/colors.dart';
import 'package:go_router/go_router.dart';
import '../components/custom_menu_button.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firestore_service.dart';
import '../models/types.dart';

const _kGreen = Color(0xFF2D6A4F);
const _kHeaderGreen = Color(0xFF2D6A4F);
const _kOrange = Color(0xFFF4A261);

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LanguageProvider>();
    final firestore = context.read<FirestoreService>();

    return Scaffold(
      backgroundColor: context.appBackground,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Full-width Header with centered content
            Container(
              width: double.infinity,
              color: _kHeaderGreen,
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1400),
                  child: _buildHeader(context, lp),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Centered Content
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1400),
                child: Column(
                  children: [
                    _buildLiveStats(context, lp, firestore),
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth > 900) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 3, child: _buildAnalyticsSection(context, lp)),
                                const SizedBox(width: 24),
                                Expanded(flex: 2, child: _buildQuickManagementGrid(context, lp)),
                              ],
                            );
                          } else {
                            return Column(
                              children: [
                                _buildAnalyticsSection(context, lp),
                                const SizedBox(height: 32),
                                _buildQuickManagementGrid(context, lp),
                              ],
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, LanguageProvider lp) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        
        if (isMobile) {
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomMenuButton(
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      iconColor: Colors.white,
                    ),
                    Row(
                      children: [
                        _buildRoundedIconButton(
                          context,
                          icon: Icons.notifications_none_rounded,
                          onTap: () {},
                          bgColor: Colors.white.withValues(alpha: 0.1),
                          iconColor: Colors.white,
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              'AD',
                              style: GoogleFonts.inter(color: _kHeaderGreen, fontWeight: FontWeight.w800, fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  '${lp.getText('hello')}, Administrateur',
                  style: GoogleFonts.inter(
                    color: Colors.white, 
                    fontSize: 24, 
                    fontWeight: FontWeight.w900, 
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  lp.getText('manage_residence_one_place'),
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.7), 
                    fontSize: 13, 
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        // Desktop Layout
        return Container(
          padding: const EdgeInsets.fromLTRB(32, 48, 32, 48),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CustomMenuButton(
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                iconColor: Colors.white,
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${lp.getText('hello')}, Administrateur',
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1.0),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lp.getText('manage_residence_one_place'),
                      style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.8), fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 40),
              Row(
                children: [
                  _buildRoundedIconButton(
                    context,
                    icon: Icons.notifications_none_rounded,
                    onTap: () {},
                    bgColor: Colors.white.withValues(alpha: 0.1),
                    iconColor: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'AD',
                        style: GoogleFonts.inter(color: _kHeaderGreen, fontWeight: FontWeight.w800, fontSize: 17),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoundedIconButton(BuildContext context, {required IconData icon, required VoidCallback onTap, Color? bgColor, Color? iconColor}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor ?? context.appCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: (iconColor ?? context.appTextPrimary).withValues(alpha: 0.1)),
          ),
          child: Icon(icon, color: iconColor ?? context.appTextPrimary, size: 22),
        ),
      ),
    );
  }

  Widget _buildLiveStats(BuildContext context, LanguageProvider lp, FirestoreService firestore) {
    final isDark = context.isDark;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 900;
        
        return MultiStreamBuilder(
          streams: [
            firestore.getStudents(),
            firestore.getAllComplaints(),
          ],
          builder: (context, snapshots) {
            final students = snapshots[0].data as List<Map<String, dynamic>>? ?? [];
            final complaints = snapshots[1].data as List<Complaint>? ?? [];
            final handledComplaints = complaints.where((c) => c.status == Status.resolved || c.status == Status.rejected).length;

            final content = [
              _buildInfoStatCard(
                context,
                title: lp.getText('total_students'),
                value: students.length.toString(),
                icon: Icons.people_rounded,
                bgColor: isDark ? const Color(0xFF1E3A2F) : _kGreen,
                textColor: Colors.white,
                iconColor: Colors.white,
                onTap: () => context.go('/admin/users'),
              ),
              const SizedBox(width: 16),
              _buildInfoStatCard(
                context,
                title: lp.getText('complaints_handled'),
                value: handledComplaints.toString(),
                icon: Icons.check_circle_rounded,
                bgColor: context.appCard,
                textColor: context.appTextPrimary,
                iconColor: _kGreen,
                onTap: () => context.go('/admin/complaints'),
              ),
              const SizedBox(width: 16),
              _buildInfoStatCard(
                context,
                title: lp.getText('free_rooms'),
                value: '22', // Still hardcoded for now until we have Rooms collection
                icon: Icons.meeting_room_rounded,
                bgColor: isDark ? const Color(0xFF2A1B12) : const Color(0xFFFFF7EC),
                textColor: _kOrange,
                iconColor: _kOrange,
                onTap: () => context.go('/admin/resources'),
              ),
            ];

            if (isDesktop) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: content.map((w) => w is SizedBox ? w : Expanded(child: w)).toList(),
                ),
              );
            }

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              physics: const BouncingScrollPhysics(),
              child: Row(children: content),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color bgColor,
    required Color textColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 150,
          height: 150,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(color: textColor.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: GoogleFonts.inter(color: textColor, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsSection(BuildContext context, LanguageProvider lp) {
    final isDark = context.isDark;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: context.appBorder.withValues(alpha: 0.5)),
        boxShadow: isDark ? null : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(lp.getText('task_progress'), style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              _buildRoundedIconButton(context, icon: Icons.more_horiz_rounded, onTap: () {}),
            ],
          ),
          const SizedBox(height: 40),
          Center(
            child: SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(220, 220),
                    painter: _ProgressPainter(progress: 0.65, color: _kGreen, backgroundColor: context.appBorder),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('65%', style: GoogleFonts.inter(fontSize: 40, fontWeight: FontWeight.w900, color: _kGreen)),
                      Text(lp.getText('tasks_completed'), style: GoogleFonts.inter(fontSize: 12, color: context.appTextSecondary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem(lp.getText('completed'), _kGreen),
              _buildLegendItem(lp.getText('in_progress_legend'), _kGreen.withValues(alpha: 0.4)),
              _buildLegendItem(lp.getText('pending'), context.appBorder),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildQuickManagementGrid(BuildContext context, LanguageProvider lp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lp.getText('quick_management'),
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: context.appTextPrimary, letterSpacing: -0.5),
        ),
        const SizedBox(height: 20),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: [
            _buildActionTile(context, lp.getText('manage_students'), lp.getText('registered_users'), Icons.people_alt_rounded, const Color(0xFF10B981), () => context.push('/admin/users')),
            _buildActionTile(context, lp.getText('announcements'), lp.getText('broadcast_news'), Icons.campaign_rounded, const Color(0xFF3B82F6), () => context.push('/admin/announcements')),
            _buildActionTile(context, lp.getText('documents'), 'Share forms & guides', Icons.file_copy_rounded, Colors.purple, () => context.push('/admin/documents')),
            _buildActionTile(context, lp.getText('dining_menu'), lp.getText('update_cafeteria'), Icons.restaurant_rounded, const Color(0xFFF59E0B), () => context.push('/admin/dining-config')),
            _buildActionTile(context, lp.getText('maintenance'), lp.getText('resource_requests'), Icons.handyman_rounded, const Color(0xFF6366F1), () => context.push('/admin/requests')),
          ],
        ),
        const SizedBox(height: 24),
        // Desktop Primary Action Button
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: _kGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20),
            minimumSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: Text(lp.getText('add_task'), style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16)),
        ),
      ],
    );
  }

  Widget _buildActionTile(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    final isDark = context.isDark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        hoverColor: color.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.appCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.appBorder.withValues(alpha: 0.5)),
            boxShadow: isDark ? null : [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: context.appTextPrimary, fontSize: 15, letterSpacing: -0.3),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(color: context.appTextSecondary, fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _ProgressPainter({required this.progress, required this.color, required this.backgroundColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2);
    const strokeWidth = 14.0;

    final bgPaint = Paint()
      ..color = backgroundColor.withValues(alpha: 0.1)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), math.pi * 0.7, math.pi * 1.6, false, bgPaint);

    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), math.pi * 0.7, math.pi * 1.6 * progress, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
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
