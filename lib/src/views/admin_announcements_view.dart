import 'package:flutter/material.dart';
import '../components/custom_menu_button.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    final firestore = context.read<FirestoreService>();
    final residenceId = auth.currentResidenceId;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Action Row
          Row(
            children: [
              Expanded(
                child: Text(
                  lp.getText('message_history'),
                  style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18, color: context.appTextPrimary, letterSpacing: -0.5),
                ),
              ),
              const SizedBox(width: 12),
              _buildHeaderAction(
                context: context,
                icon: Icons.send_rounded,
                onTap: () => _showCreateAnnouncementDialog(context, lp),
                label: lp.getText('broadcast'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          StreamBuilder<List<Announcement>>(
            stream: firestore.getAnnouncements(residenceId: residenceId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              final announcements = snapshot.data ?? [];
              if (announcements.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Text(
                      "Aucune communication trouvée",
                      style: GoogleFonts.inter(color: context.appTextSecondary),
                    ),
                  ),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final cardsPerRow = constraints.maxWidth > 800 ? 2 : 1;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cardsPerRow,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                      mainAxisExtent: 280,
                    ),
                    itemCount: announcements.length,
                    itemBuilder: (context, index) {
                      final ann = announcements[index];
                      return _buildModernAnnouncementCard(
                        context,
                        lp,
                        ann,
                        DateFormat('dd MMM, HH:mm', 'fr').format(ann.timestamp),
                        false,
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderAction({required BuildContext context, required IconData icon, required VoidCallback onTap, required String label}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark ? AppColors.primary : const Color(0xFF0E2318),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showCreateAnnouncementDialog(BuildContext context, LanguageProvider lp) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    List<XFile> selectedImages = [];
    bool isUploading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: context.appCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(lp.getText('create_announcement'), style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: context.appTextPrimary)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Rédigez une annonce pour tous les résidents.", style: GoogleFonts.inter(color: context.appTextSecondary, fontSize: 13)),
                  const SizedBox(height: 24),
                  _buildModernInput(
                    context: context,
                    controller: titleController,
                    label: lp.getText('title') == 'title' ? 'Titre' : lp.getText('title'),
                    icon: Icons.title_rounded,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildModernInput(
                    context: context,
                    controller: bodyController,
                    label: lp.getText('description') == 'description' ? 'Message' : lp.getText('description'),
                    icon: Icons.message_rounded,
                    isDark: isDark,
                    maxLines: 4,
                  ),
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
                            borderRadius: BorderRadius.circular(8),
                            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[200],
                            image: DecorationImage(
                              image: NetworkImage(selectedImages[index].path),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Align(
                            alignment: Alignment.topRight,
                            child: InkWell(
                              onTap: () => setState(() => selectedImages.removeAt(index)),
                              child: Container(
                                margin: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                child: const Icon(Icons.close, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final ImagePicker picker = ImagePicker();
                      final List<XFile> images = await picker.pickMultiImage();
                      setState(() {
                         selectedImages.addAll(images);
                      });
                    },
                    icon: const Icon(Icons.add_photo_alternate_rounded),
                    label: const Text('Ajouter des photos'),
                    style: OutlinedButton.styleFrom(
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                       side: BorderSide(color: AppColors.primary),
                       foregroundColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (!isUploading)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(lp.getText('cancel')),
                ),
              ElevatedButton(
                onPressed: isUploading ? null : () async {
                  final title = titleController.text.trim();
                  final body = bodyController.text.trim();
                  if (title.isEmpty || body.isEmpty) return;

                  setState(() => isUploading = true);
                  
                  try {
                    List<String> uploadedUrls = [];
                    if (selectedImages.isNotEmpty) {
                       final futures = selectedImages.map((img) => CloudinaryService.uploadImage(img));
                       uploadedUrls = (await Future.wait(futures)).whereType<String>().toList();
                    }

                    final auth = context.read<AuthProvider>();
                    final firestore = context.read<FirestoreService>();
                    
                    final announcement = Announcement(
                      title: title,
                      content: body,
                      timestamp: DateTime.now(),
                      imageUrls: uploadedUrls,
                    );

                    await firestore.addAnnouncement(announcement, residenceId: auth.currentResidenceId);

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(lp.getText('announcement_created') == 'announcement_created' ? 'Annonce diffusée avec succès !' : lp.getText('announcement_created')),
                          backgroundColor: _kGreen,
                        ),
                      );
                    }
                  } catch (e) {
                    setState(() => isUploading = false);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Erreur lors de la diffusion'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: _kGreen, foregroundColor: Colors.white),
                child: isUploading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Diffuser'),
              )
            ],
          );
        }
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                    const SizedBox(height: 8),
                    Text(subtitle, style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Icon(icon, color: Colors.white, size: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernAnnouncementCard(BuildContext context, LanguageProvider lp, Announcement ann, String time, bool isUrgent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? null : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isUrgent ? Colors.red.withValues(alpha: 0.1) : _kGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isUrgent ? lp.getText('urgent') : lp.getText('info'),
                  style: GoogleFonts.inter(
                    color: isUrgent ? Colors.red : _kGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Row(
                children: [
                  Text(time, style: GoogleFonts.inter(color: context.appTextSecondary.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 12),
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      if (ann.id != null) {
                        showDialog(context: context, builder: (ctx) => AlertDialog(
                          title: const Text('Supprimer l\'annonce ?'),
                          content: const Text('Cette action est irréversible.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
                            ElevatedButton(
                              onPressed: () async {
                                Navigator.pop(ctx);
                                await context.read<FirestoreService>().deleteAnnouncement(ann.id!);
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
                            )
                          ]
                        ));
                      }
                    },
                    child: Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(ann.title, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 17, color: context.appTextPrimary, letterSpacing: -0.3)),
          const SizedBox(height: 8),
          Text(ann.content, style: GoogleFonts.inter(color: context.appTextSecondary, fontSize: 14, height: 1.5, fontWeight: FontWeight.w400)),
        ],
      ),
    );
  }
  Widget _buildModernInput({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    String? hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.inter(color: context.appTextPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.inter(color: context.appTextSecondary, fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
