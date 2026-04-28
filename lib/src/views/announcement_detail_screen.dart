import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../providers/auth_provider.dart';
import 'dart:ui';
import '../components/custom_menu_button.dart';
import '../models/types.dart';
import '../core/theme/colors.dart';

class AnnouncementDetailScreen extends StatelessWidget {
  final Announcement announcement;

  const AnnouncementDetailScreen({super.key, required this.announcement});

  String _formatDate(DateTime dt) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} • $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final primaryColor = AppColors.primary;
    final auth = context.watch<AuthProvider>();
    final userId = auth.currentUserData?['uid'] ?? '';
    final firestore = context.watch<FirestoreService>();

    return Scaffold(
      backgroundColor: context.appBackground,
      body: StreamBuilder<Announcement>(
        stream: firestore.streamAnnouncement(announcement.id!, residenceId: announcement.residenceId),
        initialData: announcement,
        builder: (context, snapshot) {
          final ann = snapshot.data ?? announcement;
          final bool isLiked = ann.likedBy.contains(userId);

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Premium App Bar ───────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                stretch: true,
                backgroundColor: const Color(0xFF2D6A4F),
                elevation: 0,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground,
                  ],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [const Color(0xFF2D6A4F), const Color(0xFF2D6A4F).withValues(alpha: 0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                      Positioned(
                        right: -20,
                        top: -20,
                        child: Transform.rotate(
                          angle: -0.2,
                          child: Icon(
                            Icons.campaign_rounded,
                            size: 200,
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 40,
                        left: 24,
                        right: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                "OFFICIAL ANNOUNCEMENT",
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              ann.title,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                height: 1.2,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    offset: const Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Content Card ──────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -25),
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.appCard,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, -10),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 60),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _buildMetaBadge(primaryColor, 'NEWS'),
                              const Spacer(),
                              Icon(Icons.event_note_rounded, size: 16, color: context.appTextSecondary),
                              const SizedBox(width: 6),
                              Text(
                                _formatDate(ann.timestamp),
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: context.appTextSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          _buildElegantDivider(primaryColor, context),
                          const SizedBox(height: 32),
                          ann.content.isEmpty
                              ? _buildEmptyState(isDark)
                              : Text(
                                  ann.content,
                                  style: GoogleFonts.inter(
                                    fontSize: 17,
                                    height: 1.8,
                                    fontWeight: FontWeight.w400,
                                    color: context.appTextPrimary,
                                  ),
                                ),
                          const SizedBox(height: 32),
                          if (ann.imageUrls.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.network(ann.imageUrls.first, width: double.infinity, fit: BoxFit.cover),
                            ),
                          const SizedBox(height: 40),
                          
                          // Interaction Row
                          Row(
                            children: [
                              _buildInteractionBtn(
                                context,
                                isLiked ? Icons.thumb_up_rounded : Icons.thumb_up_off_alt_rounded,
                                isLiked ? 'Liked' : 'Like',
                                isLiked ? Colors.blue : context.appTextSecondary,
                                () => firestore.toggleLike(ann.id!, userId, collection: 'announcements'),
                              ),
                              const SizedBox(width: 16),
                              _buildInteractionBtn(
                                context,
                                Icons.chat_bubble_outline_rounded,
                                '${ann.commentsCount} Comments',
                                primaryColor,
                                () => _showRepliesSheet(context, ann, userId),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 48),
                          _buildFooter(primaryColor, context),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetaBadge(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.label_important_rounded, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(color: color, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildElegantDivider(Color color, BuildContext context) {
    return Row(
      children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: context.appBorder.withValues(alpha: 0.5), thickness: 1)),
      ],
    );
  }

  Widget _buildInteractionBtn(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: context.appCard,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: color.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(label, style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRepliesSheet(BuildContext context, Announcement ann, String userId) {
    // We can't directly reuse _RepliesSheet from ForumView because it's private there.
    // However, I can create a similar one or refactor. For now, I'll navigate to ForumView 
    // or just show a simplified version.
    // Actually, I'll just show the same sheet logic but adapted.
    // Wait, it's better to show the full experience.
    
    // I'll show a simple bottom sheet with comments for now.
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SimpleRepliesSheet(announcement: ann, userId: userId),
    );
  }

  Widget _buildFooter(Color color, BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: context.appBackground, shape: BoxShape.circle),
            child: Icon(Icons.verified_user_rounded, color: color.withValues(alpha: 0.3), size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            "Iqamty Communications",
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: context.appTextSecondary.withValues(alpha: 0.5),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.notes_rounded, size: 64, color: AppColors.primary.withValues(alpha: 0.1)),
            const SizedBox(height: 16),
            const Text(
              "No details provided for this announcement.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimpleRepliesSheet extends StatefulWidget {
  final Announcement announcement;
  final String userId;
  const _SimpleRepliesSheet({required this.announcement, required this.userId});

  @override
  State<_SimpleRepliesSheet> createState() => _SimpleRepliesSheetState();
}

class _SimpleRepliesSheetState extends State<_SimpleRepliesSheet> {
  final _replyController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final firestore = context.watch<FirestoreService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Container(
        margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 60),
        decoration: BoxDecoration(
          color: context.appCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Comments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: StreamBuilder<List<ForumReply>>(
                stream: firestore.streamForumReplies(widget.announcement.id!, collection: 'announcements'),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  final replies = snapshot.data ?? [];
                  if (replies.isEmpty) return const Center(child: Text('No comments yet. Be the first!'));

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: replies.length,
                    itemBuilder: (context, index) {
                      final r = replies[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(r.authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text(r.content),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          child: Text(r.authorName.isNotEmpty ? r.authorName[0].toUpperCase() : '?', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyController,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        filled: true,
                        fillColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () async {
                      if (_replyController.text.trim().isEmpty) return;
                      final auth = context.read<AuthProvider>();
                      final reply = ForumReply(
                        content: _replyController.text.trim(),
                        authorId: widget.userId,
                        authorName: auth.currentUserData?['displayName'] ?? 'Student',
                        createdAt: DateTime.now(),
                      );
                      await firestore.addForumReply(widget.announcement.id!, reply, collection: 'announcements');
                      _replyController.clear();
                    },
                    icon: Icon(Icons.send_rounded, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
