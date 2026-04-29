import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../core/theme/colors.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firestore_service.dart';
import '../services/cloudinary_service.dart';
import '../providers/auth_provider.dart';
import '../models/types.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

const _kGreen = Color(0xFF2D6A4F);

class AdminAnnouncementsView extends StatelessWidget {
  const AdminAnnouncementsView({super.key});

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LanguageProvider>();
    final auth = context.watch<AuthProvider>();
    final residenceId = auth.currentResidenceId ?? auth.currentUserData?['residenceId'] as String?;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (residenceId == null || residenceId.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off_rounded, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Aucune résidence configurée',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: context.appTextPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Veuillez associer une résidence à votre compte administrateur.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 14, color: context.appTextSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gestion Communauté',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 24, color: context.appTextPrimary, letterSpacing: -0.5),
                      ),
                      Text(
                        'Gérez les annonces et le forum de votre résidence',
                        style: GoogleFonts.outfit(fontSize: 13, color: context.appTextSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
                gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)]),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2)),
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
          Expanded(
            child: TabBarView(
              children: [
                _AdminFeedTab(postType: 'announcement', residenceId: residenceId),
                _AdminFeedTab(postType: 'post', residenceId: residenceId),
                _AdminFeedTab(postType: 'poll', residenceId: residenceId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminFeedTab extends StatelessWidget {
  final String postType;
  final String residenceId;
  const _AdminFeedTab({required this.postType, required this.residenceId});

  @override
  Widget build(BuildContext context) {
    final firestore = context.watch<FirestoreService>();
    final lp = context.watch<LanguageProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        StreamBuilder(
          stream: postType == 'announcement'
              ? firestore.getAnnouncements(residenceId: residenceId)
              : firestore.streamForumPosts(type: postType, residenceId: residenceId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Erreur de chargement', style: GoogleFonts.outfit(color: Colors.red)));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final List<dynamic> items = snapshot.data ?? [];
            if (items.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome_motion_outlined, size: 48, color: Colors.grey.withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                    Text('Aucun contenu publié', style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.w500)),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
              itemCount: items.length,
              itemBuilder: (context, index) {
                if (postType == 'announcement') {
                  return _AdminAnnouncementCard(ann: items[index] as Announcement, lp: lp);
                } else {
                  return _AdminForumCard(post: items[index] as ForumPost, lp: lp);
                }
              },
            );
          },
        ),
        Positioned(
          bottom: 24,
          right: 24,
          child: FloatingActionButton.extended(
            onPressed: () => _showCreateDialog(context, postType, residenceId),
            backgroundColor: AppColors.primary,
            elevation: 4,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: Text(
              postType == 'announcement' ? 'Diffuser' : (postType == 'poll' ? 'Sondage' : 'Poster'), 
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)
            ),
          ),
        ),
      ],
    );
  }

  void _showCreateDialog(BuildContext context, String type, String residenceId) {
    if (type == 'announcement') {
      _showCreateAnnouncementDialog(context, residenceId);
    } else {
      _showCreateForumPostDialog(context, type, residenceId);
    }
  }

  void _showCreateAnnouncementDialog(BuildContext context, String residenceId) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    List<XFile> selectedImages = [];
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: context.appCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Nouvelle Annonce', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildInput(context, titleController, 'Titre de l\'annonce', Icons.title_rounded, isDark),
                  const SizedBox(height: 16),
                  _buildInput(context, contentController, 'Message à diffuser...', Icons.message_rounded, isDark, maxLines: 4),
                  const SizedBox(height: 16),
                  if (selectedImages.isNotEmpty)
                     SizedBox(
                       height: 80,
                       child: ListView.builder(
                         scrollDirection: Axis.horizontal,
                         itemCount: selectedImages.length,
                         itemBuilder: (context, index) => Container(
                           margin: const EdgeInsets.only(right: 8),
                           width: 80,
                           decoration: BoxDecoration(
                             borderRadius: BorderRadius.circular(12),
                             image: DecorationImage(image: NetworkImage(selectedImages[index].path), fit: BoxFit.cover),
                           ),
                           child: Align(
                             alignment: Alignment.topRight,
                             child: GestureDetector(
                               onTap: () => setState(() => selectedImages.removeAt(index)),
                               child: Container(
                                 margin: const EdgeInsets.all(4),
                                 padding: const EdgeInsets.all(2),
                                 decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                 child: const Icon(Icons.close, color: Colors.white, size: 12),
                               ),
                             ),
                           ),
                         ),
                       ),
                     ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final images = await ImagePicker().pickMultiImage();
                      setState(() => selectedImages.addAll(images));
                    },
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('Ajouter des images'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text('Annuler', style: TextStyle(color: context.appTextSecondary))),
              ElevatedButton(
                onPressed: isUploading ? null : () async {
                  if (titleController.text.isEmpty || contentController.text.isEmpty) return;
                  setState(() => isUploading = true);
                  
                  List<String> urls = [];
                  if (selectedImages.isNotEmpty) {
                    for (var img in selectedImages) {
                      final url = await CloudinaryService.uploadImage(img);
                      if (url != null) urls.add(url);
                    }
                  }

                  await context.read<FirestoreService>().addAnnouncement(
                    Announcement(
                      title: titleController.text.trim(),
                      content: contentController.text.trim(),
                      timestamp: DateTime.now(),
                      imageUrls: urls,
                      residenceId: residenceId,
                    ),
                    residenceId: residenceId,
                  );
                  if (context.mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, 
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isUploading 
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                  : const Text('Diffuser'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCreateForumPostDialog(BuildContext context, String type, String residenceId) {
    final contentController = TextEditingController();
    final titleController = TextEditingController();
    final List<TextEditingController> pollOptControllers = [TextEditingController(), TextEditingController()];
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: context.appCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(type == 'poll' ? 'Nouveau Sondage' : 'Nouveau Post', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (type == 'poll') ...[
                    _buildInput(context, titleController, 'Question du sondage', Icons.help_outline_rounded, isDark),
                    const SizedBox(height: 16),
                  ],
                  _buildInput(context, contentController, type == 'poll' ? 'Description (optionnel)' : 'Quoi de neuf ?', Icons.chat_bubble_outline_rounded, isDark, maxLines: 4),
                  if (type == 'poll') ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Text('Options de réponse', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: context.appTextSecondary)),
                        const Spacer(),
                        IconButton(
                          onPressed: () => setState(() => pollOptControllers.add(TextEditingController())),
                          icon: Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 20),
                        ),
                      ],
                    ),
                    ...List.generate(pollOptControllers.length, (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Expanded(child: _buildInput(context, pollOptControllers[index], 'Option ${index + 1}', Icons.list_rounded, isDark)),
                          if (index > 1) 
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.red, size: 20), 
                              onPressed: () => setState(() => pollOptControllers.removeAt(index))
                            ),
                        ],
                      ),
                    )),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text('Annuler', style: TextStyle(color: context.appTextSecondary))),
              ElevatedButton(
                onPressed: isUploading ? null : () async {
                  if (contentController.text.isEmpty && type != 'poll') return;
                  if (type == 'poll' && (titleController.text.isEmpty || pollOptControllers.any((c) => c.text.isEmpty))) return;
                  
                  setState(() => isUploading = true);
                  final auth = context.read<AuthProvider>();
                  
                  List<PollOption>? opts;
                  if (type == 'poll') {
                    opts = pollOptControllers.map((c) => PollOption(text: c.text.trim(), votedBy: [])).toList();
                  }

                  await context.read<FirestoreService>().addForumPost(
                    ForumPost(
                      type: type,
                      title: type == 'poll' ? titleController.text.trim() : '',
                      content: contentController.text.trim(),
                      authorId: auth.currentUserData?['uid'] ?? 'admin',
                      authorName: 'Administration',
                      createdAt: DateTime.now(),
                      pollOptions: opts,
                      isPinned: true,
                      residenceId: residenceId,
                    ),
                    residenceId: residenceId,
                  );
                  if (context.mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, 
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isUploading 
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                  : const Text('Publier'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInput(BuildContext context, TextEditingController controller, String label, IconData icon, bool isDark, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.outfit(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: context.appTextSecondary),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}

class _AdminAnnouncementCard extends StatelessWidget {
  final Announcement ann;
  final LanguageProvider lp;
  const _AdminAnnouncementCard({required this.ann, required this.lp});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(20),
        border: ann.isPinned 
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5)
            : Border.all(color: context.appBorder.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (ann.isPinned)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomRight: Radius.circular(12)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.push_pin_rounded, size: 12, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text('ÉPINGLÉ', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: 1)),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(backgroundColor: AppColors.primary.withValues(alpha: 0.1), child: Icon(Icons.campaign_rounded, color: AppColors.primary)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ann.title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: context.appTextPrimary)),
                      Text(DateFormat('dd MMM, HH:mm').format(ann.timestamp), style: GoogleFonts.outfit(color: context.appTextSecondary, fontSize: 11)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(ann.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined, 
                    color: ann.isPinned ? AppColors.primary : context.appTextSecondary, size: 20),
                  onPressed: () => context.read<FirestoreService>().toggleAnnouncementPin(ann.id!, !ann.isPinned),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 22),
                  onPressed: () => _confirmDelete(context, () => context.read<FirestoreService>().deleteAnnouncement(ann.id!)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(ann.content, style: GoogleFonts.inter(color: context.appTextPrimary.withValues(alpha: 0.8), height: 1.5)),
          ),
          if (ann.imageUrls.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(ann.imageUrls.first, width: double.infinity, height: 180, fit: BoxFit.cover),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Row(
              children: [
                _buildStat(Icons.thumb_up_off_alt_rounded, '${ann.likesCount}', Colors.blue),
                const SizedBox(width: 16),
                _buildStat(Icons.chat_bubble_outline_rounded, '${ann.commentsCount}', AppColors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(IconData icon, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color.withValues(alpha: 0.7)),
        const SizedBox(width: 6),
        Text(value, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: color.withValues(alpha: 0.8))),
      ],
    );
  }

  void _confirmDelete(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: const Text('Voulez-vous vraiment supprimer cette annonce ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); onConfirm(); },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

class _AdminForumCard extends StatelessWidget {
  final ForumPost post;
  final LanguageProvider lp;
  const _AdminForumCard({required this.post, required this.lp});

  @override
  Widget build(BuildContext context) {
    final totalVotes = post.pollOptions?.fold<int>(0, (prev, opt) => prev! + opt.voteCount) ?? 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appBorder.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(backgroundColor: Colors.grey.withValues(alpha: 0.1), child: Icon(post.type == 'poll' ? Icons.poll_rounded : Icons.forum_rounded, color: context.appTextSecondary, size: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.title.isNotEmpty ? post.title : 'Discussion', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(DateFormat('dd MMM, HH:mm').format(post.createdAt), style: GoogleFonts.outfit(color: context.appTextSecondary, fontSize: 11)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 22),
                  onPressed: () => _confirmDelete(context, () => context.read<FirestoreService>().deleteForumPost(post.id!)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(post.content, style: GoogleFonts.inter(color: context.appTextPrimary.withValues(alpha: 0.8), height: 1.5)),
          ),
          if (post.type == 'poll' && post.pollOptions != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(color: context.appBorder.withValues(alpha: 0.5)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.analytics_outlined, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text('Résultats ($totalVotes votes)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...post.pollOptions!.map((opt) {
                    final percent = totalVotes == 0 ? 0.0 : opt.voteCount / totalVotes;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(opt.text, style: GoogleFonts.outfit(fontSize: 13, color: context.appTextPrimary)),
                              Text('${opt.voteCount} (${(percent * 100).toInt()}%)', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: percent,
                              backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Row(
              children: [
                _buildStat(Icons.thumb_up_off_alt_rounded, '${post.likesCount}', Colors.blue),
                const SizedBox(width: 16),
                _buildStat(Icons.chat_bubble_outline_rounded, '${post.commentsCount}', AppColors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(IconData icon, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color.withValues(alpha: 0.7)),
        const SizedBox(width: 6),
        Text(value, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: color.withValues(alpha: 0.8))),
      ],
    );
  }

  void _confirmDelete(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: const Text('Voulez-vous vraiment supprimer ce contenu ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); onConfirm(); },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

