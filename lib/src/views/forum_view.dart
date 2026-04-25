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

    // Make sure 'announcements', 'posts', 'polls' exist in language JSON or fallback
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: context.appBackground,
        appBar: AppBar(
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CustomMenuButton(
              backgroundColor: isDark 
                  ? Colors.white.withValues(alpha: 0.1) 
                  : AppColors.primary.withValues(alpha: 0.1),
              iconColor: isDark ? Colors.white : AppColors.primary,
            ),
          ),
          title: Text(lp.getText('community')),
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: context.appTextSecondary,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: '📢 Announcements'),
              Tab(text: '💬 Posts'),
              Tab(text: '🗳️ Polls'),
            ],
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
            : firestore.streamForumPosts(type: postType, limit: 10, residenceId: auth.currentResidenceId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.amber, size: 40),
                      const SizedBox(height: 12),
                      Text(
                        'Impossible de charger le forum',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: context.appTextPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(color: context.appTextSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView.builder(
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
              )).toList();
            } else {
              posts = snapshot.data as List<ForumPost>? ?? [];
            }

            if (posts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Text(
                      'No ${postType}s yet', 
                      style: const TextStyle(color: Colors.grey)
                    ),
                  ],
                ),
              );
            }
            
            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 80, top: 16, left: 16, right: 16),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _PostCard(post: posts[index], userId: userData?['uid'] ?? '').animate().fade(duration: 300.ms).slideY(begin: 0.1, end: 0, duration: 300.ms),
                );
              },
            );
          },
        ),
        
        if (postType != 'announcement' || userData?['role'] == 'administrator')
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              backgroundColor: AppColors.primary,
              onPressed: () {
                 if (postType == 'announcement' && userData?['role'] != 'administrator') {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Only admins can post announcements')));
                    return;
                 }
                 _showCreateSheet(context, postType);
              },
              child: const Icon(Icons.edit, color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _buildSkeleton(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16, top: 16),
      height: 120,
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.black12,
        borderRadius: BorderRadius.circular(16)
      ),
    ).animate(onPlay: (controller) => controller.repeat()).shimmer(duration: 1200.ms, color: Colors.white24);
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

    Widget card = Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder.withValues(alpha: 0.4)),
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20, 
                  backgroundColor: isOfficial ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2), 
                  child: Icon(isOfficial ? Icons.verified_rounded : Icons.person_rounded, size: 20, color: isOfficial ? AppColors.primary : Colors.grey[600])
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(child: Text(widget.post.authorName, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: context.appTextPrimary), overflow: TextOverflow.ellipsis)),
                          if (isOfficial) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.check_circle_rounded, color: Colors.blue, size: 14),
                          ]
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(_formatTime(widget.post.createdAt), style: GoogleFonts.inter(fontSize: 12, color: context.appTextSecondary)),
                          const SizedBox(width: 4),
                          Icon(Icons.public, size: 12, color: context.appTextSecondary),
                        ],
                      ),
                    ],
                  ),
                ),
                if (widget.post.isPinned) const Icon(Icons.push_pin_rounded, size: 18, color: Colors.red),
                _buildCardMenu(),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.post.title.isNotEmpty) Text(widget.post.title, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: context.appTextPrimary, letterSpacing: -0.3)),
                if (widget.post.title.isNotEmpty) const SizedBox(height: 6),
                Text(widget.post.content, style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: context.appTextPrimary)),
              ],
            ),
          ),
          
          if (widget.post.attachments != null && widget.post.attachments!.isNotEmpty)
            Padding(
               padding: const EdgeInsets.only(top: 12),
               child: Image.network(widget.post.attachments!.first, width: double.infinity, fit: BoxFit.cover, height: 250),
            ),
          
          if (widget.post.type == 'poll' && widget.post.pollOptions != null)
            Padding(
               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
               child: _buildPollOptions(context),
            ),
            
          const SizedBox(height: 12),
          
          if (widget.post.likesCount > 0 || widget.post.commentsCount > 0)
            Padding(
               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
               child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     Row(
                        children: [
                           if(widget.post.likesCount > 0) ... [
                             Container(
                               padding: const EdgeInsets.all(4),
                               decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                               child: const Icon(Icons.thumb_up_rounded, color: Colors.white, size: 10),
                             ),
                             const SizedBox(width: 6),
                             Text('${widget.post.likesCount}', style: GoogleFonts.inter(color: context.appTextSecondary, fontSize: 13)),
                           ]
                        ],
                     ),
                     if(widget.post.commentsCount > 0)
                       Text('${widget.post.commentsCount} commentaires', style: GoogleFonts.inter(color: context.appTextSecondary, fontSize: 13)),
                  ],
               ),
            ),

          const Divider(height: 1, thickness: 0.5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(child: _buildActionButton(isLiked ? Icons.thumb_up_rounded : Icons.thumb_up_outlined, 'J\'aime', isLiked ? Colors.blue : context.appTextSecondary, () => _toggleLike(isLiked))),
                Expanded(child: _buildActionButton(Icons.chat_bubble_outline_rounded, 'Commenter', context.appTextSecondary, () => _showRepliesSheet(context, widget.post, widget.userId))),
                Expanded(child: _buildActionButton(Icons.share_outlined, 'Partager', context.appTextSecondary, () {})),
              ],
            ),
          ),
        ],
      ),
    );

    if (widget.post.type == 'announcement') {
      return card.animate(onPlay: (controller) => controller.repeat(reverse: true))
          .tint(color: Colors.red.withValues(alpha: 0.05), duration: 2.seconds);
    }
    return card;
  }

  Widget _buildPollOptions(BuildContext context) {
    final opts = widget.post.pollOptions!;
    final totalVotes = widget.post.votersCount > 0 ? widget.post.votersCount : 1; 
    
    return Column(
      children: List.generate(opts.length, (index) {
        final opt = opts[index];
        final pct = opt.voteCount / totalVotes;
        final hasVoted = opt.votedBy.contains(widget.userId);
        
        return GestureDetector(
          onTap: () => context.read<FirestoreService>().voteInPoll(widget.post.id!, index, widget.userId),
          child: Container(
            margin: const EdgeInsets.only(top: 8),
            height: 36,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: pct,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    decoration: BoxDecoration(
                      color: hasVoted ? AppColors.primary.withValues(alpha: 0.2) : const Color(0xFF2D6A4F).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(opt.text, style: TextStyle(fontWeight: hasVoted ? FontWeight.bold : FontWeight.normal)),
                        Text('${(pct * 100).toInt()}%', style: const TextStyle(fontSize: 12, color: Colors.grey)),
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

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
         onTap: onTap,
         borderRadius: BorderRadius.circular(8),
         child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                  Icon(icon, color: color, size: 22),
                  const SizedBox(width: 6),
                  Text(label, style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
               ],
            ),
         ),
      ),
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
                              padding: const EdgeInsets.only(left: 40),
                              child: Column(
                                children: children.map((c) => _ReplyTile(reply: c, isChild: true)).toList(),
                              ),
                            ),
                          const Divider(height: 16),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            
            Container(
              padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16),
              decoration: BoxDecoration(color: context.appCard, boxShadow: isDark ? null : const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0,-2))]),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   if (_replyingToId != null) ...[
                     Row(
                       children: [
                         Text('Replying to $_replyingToName', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                         const Spacer(),
                         IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => setState(() => _replyingToId = null)),
                       ],
                     ),
                   ].animate().fade().slideY(begin: 0.5),
                   Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _replyController,
                          decoration: InputDecoration(
                            hintText: 'Write a comment...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                            filled: true,
                            fillColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          maxLines: null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                          : IconButton(onPressed: _submitReply, icon: Icon(Icons.send, color: AppColors.primary)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().slideY(begin: 1, end: 0, duration: 300.ms, curve: Curves.easeOut);
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: isChild ? 12 : 16, backgroundColor: Colors.grey[300], child: Icon(Icons.person, size: isChild ? 12 : 16, color: Colors.black54)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(reply.authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 8),
                    Text(_formatTime(reply.createdAt), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(reply.content, style: const TextStyle(fontSize: 14)),
                if (!isChild && onReply != null)
                  InkWell(
                    onTap: onReply,
                    child: const Padding(
                      padding: EdgeInsets.only(top: 4, bottom: 4),
                      child: Text('Reply', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
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
    builder: (context) => _CreatePostSheet(postType: postType),
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
    if (content.isEmpty) return;
    
    setState(() => _isLoading = true);
    final authData = context.read<AuthProvider>().currentUserData;
    
    List<PollOption>? opts;
    if (widget.postType == 'poll') {
      opts = _pollOptControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).map((t) => PollOption(text: t, votedBy: [])).toList();
      if (opts.length < 2) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('At least 2 poll options required')));
         setState(() => _isLoading = false);
         return;
      }
    }

    final post = ForumPost(
      type: widget.postType,
      title: widget.postType == 'announcement' ? _titleController.text.trim() : '',
      content: content,
      authorId: authData?['uid'] ?? 'unknown',
      authorName: authData?['displayName'] ?? 'User',
      createdAt: DateTime.now(),
      pollOptions: opts,
    );

    await context.read<FirestoreService>().addForumPost(post, residenceId: context.read<AuthProvider>().currentResidenceId);
    if(mounted) {
       setState(() => _isLoading = false);
       Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Create ${widget.postType.capitalize()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (widget.postType == 'announcement') ...[
            TextField(controller: _titleController, decoration: const InputDecoration(hintText: 'Title')),
            const SizedBox(height: 12),
          ],
          TextField(controller: _contentController, maxLines: 4, decoration: const InputDecoration(hintText: 'What\'s on your mind?', border: OutlineInputBorder())),
          if (widget.postType == 'poll') ...[
            const SizedBox(height: 12),
            ...List.generate(_pollOptControllers.length, (index) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(child: TextField(controller: _pollOptControllers[index], decoration: InputDecoration(hintText: 'Option ${index + 1}'))),
                  if (index > 1) IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => setState(() => _pollOptControllers.removeAt(index))),
                ],
              ),
            )),
            TextButton.icon(onPressed: () => setState(() => _pollOptControllers.add(TextEditingController())), icon: const Icon(Icons.add), label: const Text('Add Option')),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: _isLoading ? null : _submit, child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Post')),
          ),
        ],
      ),
    );
  }
}
