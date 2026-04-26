import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/language_provider.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../models/types.dart';
import '../core/theme/colors.dart';
import '../components/custom_menu_button.dart';
import 'package:intl/intl.dart';

extension StringExtension on String {
  String capitalize() => "${this[0].toUpperCase()}${substring(1)}";
}

String _formatTime(DateTime time) {

  final now = DateTime.now();
  final diff = now.difference(time);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return DateFormat('dd/MM HH:mm').format(time);
}

class ForumView extends StatelessWidget {
  const ForumView({super.key});
  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LanguageProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: context.appBackground,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: context.appBackground,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CustomMenuButton(
              backgroundColor: isDark 
                  ? Colors.white.withValues(alpha: 0.05) 
                  : AppColors.primary.withValues(alpha: 0.05),
              iconColor: isDark ? Colors.white : AppColors.primary,
            ),
          ),
          title: Text(
            lp.getText('community'),
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: context.appTextPrimary,
            ),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: context.appTextSecondary,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(text: 'Annonces'),
                  Tab(text: 'Posts'),
                  Tab(text: 'Polls'),
                ],
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            _FeedTab(postType: 'announcement'),
            _FeedTab(postType: 'post'),
            _FeedTab(postType: 'poll'),
          ],
        ),
      ),
    );
  }
}

class _FeedTab extends StatelessWidget {
  final String postType;
  const _FeedTab({required this.postType});

  @override
  Widget build(BuildContext context) {
    final firestore = context.watch<FirestoreService>();
    final auth = context.watch<AuthProvider>();
    final userData = auth.currentUserData;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Stack(
      children: [
        StreamBuilder(
          stream: postType == 'announcement' 
            ? firestore.getAnnouncements(residenceId: auth.currentResidenceId)
            : firestore.streamForumPosts(type: postType, limit: 20, residenceId: auth.currentResidenceId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_off_rounded, color: Colors.grey, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Une erreur est survenue',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: context.appTextPrimary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(color: context.appTextSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 4,
                itemBuilder: (ctx, i) => _buildSkeleton(context, isDark),
              );
            }

            final List<ForumPost> posts;
            if (postType == 'announcement') {
              final annDocs = snapshot.data as List<Announcement>? ?? [];
              posts = annDocs.map((a) => ForumPost(
                id: a.id,
                type: 'announcement',
                title: a.title,
                content: a.content,
                authorId: 'admin',
                authorName: 'Administration',
                createdAt: a.timestamp,
                attachments: a.imageUrls.isNotEmpty ? a.imageUrls : (a.imageUrl != null ? [a.imageUrl!] : null),
                isPinned: true,
                residenceId: a.residenceId,
              )).toList();
            } else {
              posts = snapshot.data as List<ForumPost>? ?? [];
            }

            if (posts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.forum_outlined, size: 48, color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Aucun contenu trouvé', 
                      style: GoogleFonts.outfit(color: context.appTextSecondary, fontWeight: FontWeight.w500)
                    ),
                  ],
                ),
              );
            }
            
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _PostCard(post: posts[index], userId: userData?['uid'] ?? '').animate().fade(duration: 400.ms).slideY(begin: 0.05, end: 0, curve: Curves.easeOutQuad),
                );
              },
            );
          },
        ),
        
        if (postType != 'announcement' || userData?['role'] == 'administrator')
          Positioned(
            bottom: 24,
            right: 24,
            child: FloatingActionButton(
              backgroundColor: AppColors.primary,
              elevation: 4,
              onPressed: () {
                 if (postType == 'announcement' && userData?['role'] != 'administrator') {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Accès restreint à l\'administration')));
                    return;
                 }
                 _showCreateSheet(context, postType);
              },
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
            ),
          ),
      ],
    );
  }

  Widget _buildSkeleton(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 180,
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appBorder.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 20, backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 100, height: 12, decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(4))),
                    const SizedBox(height: 6),
                    Container(width: 60, height: 8, decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(4))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(width: double.infinity, height: 12, decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 8),
            Container(width: 200, height: 12, decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(4))),
          ],
        ),
      ),
    ).animate(onPlay: (controller) => controller.repeat()).shimmer(duration: 1500.ms, color: Colors.white12);
  }
}

class _PostCard extends StatefulWidget {
  final ForumPost post;
  final String userId;

  const _PostCard({required this.post, required this.userId});

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isLiked = widget.post.likedBy.contains(widget.userId);
    final isOfficial = widget.post.type == 'announcement';

    return Container(
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOfficial 
              ? AppColors.primary.withValues(alpha: 0.2) 
              : context.appBorder.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isOfficial)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Annonce Officielle',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 1.5),
                  ),
                  child: CircleAvatar(
                    radius: 18, 
                    backgroundColor: isOfficial ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1), 
                    child: Icon(
                      isOfficial ? Icons.admin_panel_settings_rounded : Icons.person_rounded, 
                      size: 20, 
                      color: isOfficial ? AppColors.primary : Colors.grey[600]
                    )
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.post.authorName, 
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: context.appTextPrimary), 
                              overflow: TextOverflow.ellipsis
                            )
                          ),
                          if (isOfficial) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 14),
                          ]
                        ],
                      ),
                      Text(
                        _formatTime(widget.post.createdAt), 
                        style: GoogleFonts.outfit(fontSize: 11, color: context.appTextSecondary, fontWeight: FontWeight.w500)
                      ),
                    ],
                  ),
                ),
                if (widget.post.isPinned) 
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.push_pin_rounded, size: 14, color: Colors.red),
                  ),
                _buildCardMenu(),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.post.title.isNotEmpty) 
                  Text(
                    widget.post.title, 
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17, color: context.appTextPrimary, letterSpacing: -0.2)
                  ),
                if (widget.post.title.isNotEmpty) const SizedBox(height: 8),
                Text(
                  widget.post.content, 
                  style: GoogleFonts.inter(fontSize: 14, height: 1.6, color: context.appTextPrimary.withValues(alpha: 0.9))
                ),
              ],
            ),
          ),
          
          if (widget.post.attachments != null && widget.post.attachments!.isNotEmpty)
            Padding(
               padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
               child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    widget.post.attachments!.first, 
                    width: double.infinity, 
                    fit: BoxFit.cover, 
                    height: 220,
                    errorBuilder: (ctx, err, stack) => Container(
                      height: 150, 
                      color: Colors.grey.withValues(alpha: 0.1),
                      child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
                    ),
                  ),
               ),
            ),
          
          if (widget.post.type == 'poll' && widget.post.pollOptions != null)
            Padding(
               padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
               child: _buildPollOptions(context),
            ),
            
          const SizedBox(height: 12),
          
          Padding(
             padding: const EdgeInsets.symmetric(horizontal: 16),
             child: Row(
                children: [
                   if (widget.post.likesCount > 0) ...[
                     _buildStatBadge(Icons.thumb_up_rounded, '${widget.post.likesCount}', Colors.blue),
                     const SizedBox(width: 8),
                   ],
                   if (widget.post.commentsCount > 0)
                     _buildStatBadge(Icons.chat_bubble_rounded, '${widget.post.commentsCount}', AppColors.primary),
                   const Spacer(),
                   if (widget.post.type == 'poll')
                     Text(
                       '${widget.post.votersCount} votes', 
                       style: GoogleFonts.outfit(fontSize: 11, color: context.appTextSecondary, fontWeight: FontWeight.bold)
                     ),
                ],
             ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Divider(height: 1, thickness: 0.5),
          ),
          
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInteractionBtn(
                  isLiked ? Icons.thumb_up_rounded : Icons.thumb_up_outlined, 
                  'Like', 
                  isLiked ? Colors.blue : context.appTextSecondary, 
                  () => _toggleLike(isLiked)
                ),
                _buildInteractionBtn(
                  Icons.chat_bubble_outline_rounded, 
                  'Comment', 
                  context.appTextSecondary, 
                  () => _showRepliesSheet(context, widget.post, widget.userId)
                ),
                _buildInteractionBtn(
                  Icons.share_outlined, 
                  'Share', 
                  context.appTextSecondary, 
                  () {}
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(count, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildInteractionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 6),
                Text(label, style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPollOptions(BuildContext context) {
    final opts = widget.post.pollOptions!;
    final totalVotes = widget.post.votersCount > 0 ? widget.post.votersCount : 1; 
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: List.generate(opts.length, (index) {
        final opt = opts[index];
        final pct = opt.voteCount / totalVotes;
        final hasVoted = opt.votedBy.contains(widget.userId);
        
        return GestureDetector(
          onTap: () => context.read<FirestoreService>().voteInPoll(widget.post.id!, index, widget.userId),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            height: 44,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: pct,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          hasVoted ? AppColors.primary : const Color(0xFF2D6A4F).withValues(alpha: 0.4),
                          hasVoted ? AppColors.primary.withValues(alpha: 0.7) : const Color(0xFF2D6A4F).withValues(alpha: 0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            opt.text, 
                            style: GoogleFonts.outfit(
                              fontWeight: hasVoted ? FontWeight.bold : FontWeight.w500,
                              fontSize: 14,
                              color: hasVoted ? Colors.white : context.appTextPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          children: [
                            if (hasVoted) const Icon(Icons.check_circle_rounded, size: 14, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              '${(pct * 100).toInt()}%', 
                              style: GoogleFonts.outfit(
                                fontSize: 12, 
                                fontWeight: FontWeight.bold,
                                color: hasVoted ? Colors.white : context.appTextSecondary
                              )
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
  void _toggleLike(bool isLiked) async {
    try {
      await context.read<FirestoreService>().toggleLike(widget.post.id!, widget.userId);
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de la mise à jour.')));
    }
  }

  Widget _buildCardMenu() {
    return IconButton(
      icon: Icon(Icons.more_horiz_rounded, color: Colors.grey[500]),
      onPressed: () {},
      splashRadius: 20,
    );
  }
}


void _showRepliesSheet(BuildContext context, ForumPost post, String currentUserId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _RepliesSheet(post: post, currentUserId: currentUserId),
  );
}

class _RepliesSheet extends StatefulWidget {
  final ForumPost post;
  final String currentUserId;
  const _RepliesSheet({required this.post, required this.currentUserId});

  @override
  State<_RepliesSheet> createState() => _RepliesSheetState();
}

class _RepliesSheetState extends State<_RepliesSheet> {
  final _replyController = TextEditingController();
  String? _replyingToId;
  String? _replyingToName;
  bool _isLoading = false;

  Future<void> _submitReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    setState(() => _isLoading = true);
    final authData = context.read<AuthProvider>().currentUserData;
    final reply = ForumReply(
      content: text,
      authorId: authData?['uid'] ?? widget.currentUserId,
      authorName: authData?['displayName'] ?? 'User',
      createdAt: DateTime.now(),
      parentReplyId: _replyingToId,
    );
    await context.read<FirestoreService>().addForumReply(widget.post.id!, reply);
    if (!mounted) return;
    _replyController.clear();
    setState(() {
      _replyingToId = null;
      _replyingToName = null;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                stream: context.read<FirestoreService>().streamForumReplies(widget.post.id!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  final replies = snapshot.data ?? [];
                  
                  final mainReplies = replies.where((r) => r.parentReplyId == null).toList();
                  final subReplies = replies.where((r) => r.parentReplyId != null).toList();

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: mainReplies.length,
                    itemBuilder: (context, index) {
                      final mainR = mainReplies[index];
                      final children = subReplies.where((r) => r.parentReplyId == mainR.id).toList();
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ReplyTile(reply: mainR, onReply: () => setState(() {
                            _replyingToId = mainR.id;
                            _replyingToName = mainR.authorName;
                          })),
                          if (children.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 44),
                              child: Column(
                                children: children.map((c) => _ReplyTile(reply: c, isChild: true)).toList(),
                              ),
                            ),
                          const Divider(height: 24, thickness: 0.5),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            
            Container(
              padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16),
              decoration: BoxDecoration(
                color: context.appCard, 
                boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0,-2))]
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    if (_replyingToId != null)
                      ...[
                        Row(
                          children: [
                            Text(
                              'En réponse à $_replyingToName',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 16),
                              onPressed: () => setState(() => _replyingToId = null),
                            ),
                          ],
                        ),
                      ].animate().fade().slideY(begin: 0.5),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _replyController,
                            style: GoogleFonts.outfit(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Ajouter un commentaire...',
                              hintStyle: TextStyle(color: context.appTextSecondary.withValues(alpha: 0.5)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                              filled: true,
                              fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            maxLines: null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _isLoading
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                            : Container(
                                decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                child: IconButton(
                                  onPressed: _submitReply,
                                  icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                                ),
                              ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ).animate().slideY(begin: 1, end: 0, duration: 400.ms, curve: Curves.easeOutQuart);
  }
}

class _ReplyTile extends StatelessWidget {
  final ForumReply reply;
  final bool isChild;
  final VoidCallback? onReply;

  const _ReplyTile({required this.reply, this.isChild = false, this.onReply});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: isChild ? 14 : 18, 
            backgroundColor: AppColors.primary.withValues(alpha: 0.1), 
            child: Icon(Icons.person_rounded, size: isChild ? 14 : 18, color: AppColors.primary)
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      reply.authorName, 
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: context.appTextPrimary)
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(reply.createdAt), 
                      style: GoogleFonts.outfit(fontSize: 10, color: context.appTextSecondary)
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  reply.content, 
                  style: GoogleFonts.inter(fontSize: 14, color: context.appTextPrimary, height: 1.4)
                ),
                if (!isChild && onReply != null)
                  GestureDetector(
                    onTap: onReply,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Répondre', 
                        style: GoogleFonts.outfit(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void _showCreateSheet(BuildContext context, String postType) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: _CreatePostSheet(postType: postType),
    ),
  );
}

class _CreatePostSheet extends StatefulWidget {
  final String postType;
  const _CreatePostSheet({required this.postType});
  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final _contentController = TextEditingController();
  final _titleController = TextEditingController();
  final List<TextEditingController> _pollOptControllers = [TextEditingController(), TextEditingController()];
  bool _isLoading = false;

  void _submit() async {
    final content = _contentController.text.trim();
    if (content.isEmpty && widget.postType != 'poll') return;
    
    setState(() => _isLoading = true);
    final authData = context.read<AuthProvider>().currentUserData;
    
    List<PollOption>? opts;
    if (widget.postType == 'poll') {
      opts = _pollOptControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).map((t) => PollOption(text: t, votedBy: [])).toList();
      if (opts.length < 2) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Au moins 2 options requises')));
         setState(() => _isLoading = false);
         return;
      }
    }

    final post = ForumPost(
      type: widget.postType,
      title: widget.postType == 'announcement' ? _titleController.text.trim() : '',
      content: content,
      authorId: authData?['uid'] ?? 'unknown',
      authorName: authData?['displayName'] ?? 'Utilisateur',
      createdAt: DateTime.now(),
      pollOptions: opts,
      residenceId: context.read<AuthProvider>().currentResidenceId,
    );

    await context.read<FirestoreService>().addForumPost(post, residenceId: context.read<AuthProvider>().currentResidenceId);
    if(mounted) {
       setState(() => _isLoading = false);
       Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Créer un ${widget.postType}', 
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)
              ),
              const Spacer(),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.postType == 'announcement') ...[
            _buildInput(_titleController, 'Titre', Icons.title_rounded, isDark),
            const SizedBox(height: 12),
          ],
          _buildInput(_contentController, 'Quoi de neuf ?', Icons.chat_bubble_outline_rounded, isDark, maxLines: 4),
          if (widget.postType == 'poll') ...[
            const SizedBox(height: 20),
            Text('Options du sondage', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: context.appTextSecondary)),
            const SizedBox(height: 12),
            ...List.generate(_pollOptControllers.length, (index) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(child: _buildInput(_pollOptControllers[index], 'Option ${index + 1}', Icons.list_rounded, isDark)),
                  if (index > 1) 
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.red), 
                      onPressed: () => setState(() => _pollOptControllers.removeAt(index))
                    ),
                ],
              ),
            )),
            TextButton.icon(
              onPressed: () => setState(() => _pollOptControllers.add(TextEditingController())), 
              icon: const Icon(Icons.add_rounded), 
              label: const Text('Ajouter une option')
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit, 
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                : Text('Publier', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String hint, IconData icon, bool isDark, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.outfit(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: context.appTextSecondary.withValues(alpha: 0.6)),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}
