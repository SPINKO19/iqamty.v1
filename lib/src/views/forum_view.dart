import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../models/types.dart';
import '../core/theme/colors.dart';
import 'package:intl/intl.dart';

class ForumView extends StatefulWidget {
  const ForumView({super.key});

  @override
  State<ForumView> createState() => _ForumViewState();
}

class _ForumViewState extends State<ForumView> {
  late Stream<List<ForumPost>> _postsStream;

  @override
  void initState() {
    super.initState();
    _postsStream = Provider.of<FirestoreService>(context, listen: false).streamForumPosts();
  }

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LanguageProvider>();
    final auth = context.watch<AuthProvider>();
    final userData = auth.currentUserData;

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: Text(lp.getText('community'), style: TextStyle(color: context.appTextPrimary)),
        backgroundColor: context.appCard,
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<List<ForumPost>>(
        stream: _postsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final posts = snapshot.data ?? [];
          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.forum_outlined, size: 64, color: context.appTextSecondary.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(lp.getText('no_posts'), style: TextStyle(color: context.appTextSecondary)),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return _PostCard(post: post, userId: userData?['uid'] ?? '');
                  },
                ),
              ),
              _SimplePostInput(userId: userData?['uid'] ?? ''),
            ],
          );
        },
      ),
    );
  }
}

class _SimplePostInput extends StatefulWidget {
  final String userId;
  const _SimplePostInput({required this.userId});

  @override
  State<_SimplePostInput> createState() => _SimplePostInputState();
}

class _SimplePostInputState extends State<_SimplePostInput> {
  final _controller = TextEditingController();
  bool _isPosting = false;

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isPosting) return;

    setState(() => _isPosting = true);
    final auth = context.read<AuthProvider>();
    final firestore = context.read<FirestoreService>();

    try {
      final post = ForumPost(
        userId: widget.userId,
        authorName: auth.currentUserData?['displayName'] ?? 'User',
        text: text,
        isPoll: false,
        timestamp: DateTime.now(),
      );
      await firestore.addForumPost(post);
      _controller.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LanguageProvider>();
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      decoration: BoxDecoration(
        color: context.appCard,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: lp.getText('post_text_hint'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                filled: true,
                fillColor: context.appBackground,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              maxLines: null,
            ),
          ),
          const SizedBox(width: 8),
          _isPosting
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
              : IconButton(
                  onPressed: _submit,
                  icon: Icon(Icons.send, color: AppColors.primary),
                ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final ForumPost post;
  final String userId;

  const _PostCard({required this.post, required this.userId});

  @override
  Widget build(BuildContext context) {
    final isOfficial = post.isOfficial;
    final isLiked = post.likedBy.contains(userId);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOfficial ? AppColors.primary.withOpacity(0.05) : context.appCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isOfficial ? AppColors.primary.withOpacity(0.2) : context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: isOfficial ? AppColors.primary : Colors.grey[600],
                child: Icon(isOfficial ? Icons.verified : Icons.person, size: 14, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Text(post.authorName, style: TextStyle(fontWeight: FontWeight.bold, color: isOfficial ? AppColors.primary : context.appTextPrimary)),
              const Spacer(),
              Text(_formatTime(post.timestamp), style: TextStyle(fontSize: 10, color: context.appTextSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          Text(post.text, style: TextStyle(color: context.appTextPrimary)),
          const SizedBox(height: 12),
          Row(
            children: [
              InkWell(
                onTap: () => context.read<FirestoreService>().toggleLike(post.id!, userId),
                child: Row(
                  children: [
                    Icon(isLiked ? Icons.favorite : Icons.favorite_border, size: 18, color: isLiked ? Colors.red : context.appTextSecondary),
                    const SizedBox(width: 4),
                    Text('${post.likedBy.length}', style: TextStyle(fontSize: 12, color: context.appTextSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              InkWell(
                onTap: () => _showRepliesSheet(context, post),
                child: Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 18, color: context.appTextSecondary),
                    const SizedBox(width: 4),
                    Text('${post.replyCount}', style: TextStyle(fontSize: 12, color: context.appTextSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _formatTime(DateTime time) {
  final now = DateTime.now();
  final diff = now.difference(time);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return DateFormat('dd/MM HH:mm').format(time);
}

void _showRepliesSheet(BuildContext context, ForumPost post) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _RepliesSheet(post: post),
  );
}


class _RepliesSheet extends StatefulWidget {
  final ForumPost post;
  const _RepliesSheet({required this.post});

  @override
  State<_RepliesSheet> createState() => _RepliesSheetState();
}

class _RepliesSheetState extends State<_RepliesSheet> {
  final _replyController = TextEditingController();
  bool _isLoading = false;
  late Stream<List<ForumReply>> _repliesStream;

  @override
  void initState() {
    super.initState();
    _repliesStream = Provider.of<FirestoreService>(context, listen: false).streamForumReplies(widget.post.id!);
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _submitReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final firestore = context.read<FirestoreService>();

    final reply = ForumReply(
      userId: auth.currentUserData?['uid'] ?? 'unknown',
      authorName: auth.currentUserData?['displayName'] ?? 'User',
      text: text,
      timestamp: DateTime.now(),
    );

    try {
      await firestore.addForumReply(widget.post.id!, reply);
      _replyController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lp = context.read<LanguageProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 100),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(lp.getText('replies'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: StreamBuilder<List<ForumReply>>(
              stream: _repliesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final replies = snapshot.data ?? [];
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: replies.length,
                  itemBuilder: (context, index) {
                    final reply = replies[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(radius: 12, child: Icon(Icons.person, size: 12)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(reply.authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    const Spacer(),
                                    Text(_formatTime(reply.timestamp), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(reply.text, style: const TextStyle(fontSize: 14)),
                              ],
                            ),
                          ),
                        ],
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
                      hintText: lp.getText('write_reply'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(onPressed: _isLoading ? null : _submitReply, icon: Icon(Icons.send, color: AppColors.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
