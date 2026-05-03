import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../services/firestore_service.dart';
import '../services/cloudinary_service.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../models/types.dart';
import '../core/theme/colors.dart';
import '../components/custom_menu_button.dart';
import 'package:intl/intl.dart';

class ComplaintsView extends StatelessWidget {
  const ComplaintsView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final firestore = context.read<FirestoreService>();
    final userId = auth.currentStudent?.matricule ?? auth.currentUserData?['uid'] ?? '';
    final residenceId = auth.currentResidenceId ?? '';
    final lp = context.watch<LanguageProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
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
        title: Text(lp.getText('my_complaints'), style: TextStyle(color: context.appTextPrimary)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<Complaint>>(
        stream: firestore.getMyComplaints(userId, residenceId: residenceId),
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
                      lp.getText('db_error'),
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: context.appTextPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: context.appTextSecondary, fontSize: 12),
                    ),
                    if (snapshot.error.toString().contains('index')) ...[
                      const SizedBox(height: 16),
                      Text(
                        lp.getText('firestore_index_msg'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.blue, fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final complaints = snapshot.data ?? [];
          if (complaints.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.assignment_turned_in_rounded, size: 64, color: AppColors.primary.withValues(alpha: 0.5)),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    lp.getText('all_in_order'),
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.appTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    lp.getText('no_complaints_msg'),
                    style: GoogleFonts.inter(color: context.appTextSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            itemCount: complaints.length,
            separatorBuilder: (context, index) => const SizedBox(height: 20),
            itemBuilder: (context, index) {
              final complaint = complaints[index];
              return _ModernComplaintCard(complaint: complaint);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSubmissionSheet(context),
        label: Text(lp.getText('new_complaint'), style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add_rounded),
        backgroundColor: AppColors.primary,
        elevation: 4,
      ),
    );
  }

  void _showSubmissionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _ComplaintSubmissionSheet(),
    );
  }

  static void showComplaintDetails(BuildContext context, Complaint complaint) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ComplaintDetailsSheet(complaint: complaint),
    );
  }
}

class _ModernComplaintCard extends StatelessWidget {
  final Complaint complaint;
  const _ModernComplaintCard({required this.complaint});

  @override
  Widget build(BuildContext context) {
    final statusColor = _ModernComplaintCard.getStatusColor(complaint.status);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lp = context.watch<LanguageProvider>();
    
    return Container(
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.appBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _ModernComplaintCard.getStatusLabel(complaint.status, lp).toUpperCase(),
                            style: GoogleFonts.inter(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${lp.getText('ref_label')}: #${(complaint.id ?? "000000").substring(0, 5)}',
                      style: GoogleFonts.robotoMono(
                        fontSize: 10,
                        color: context.appTextSecondary.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  complaint.title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: context.appTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  complaint.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: context.appTextSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => ComplaintsView.showComplaintDetails(context, complaint),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? context.appBackground.withValues(alpha: 0.5) : const Color(0xFFF1F5F9).withValues(alpha: 0.5),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.category_outlined, size: 14, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    complaint.category,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.appTextSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    lp.getText('details'),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String getStatusLabel(Status status, LanguageProvider lp) {
    switch (status) {
      case Status.received: return lp.getText('status_received');
      case Status.inProgress: return lp.getText('status_in_progress');
      case Status.resolved: return lp.getText('status_resolved');
      case Status.approved: return lp.getText('status_approved');
      case Status.rejected: return lp.getText('status_rejected');
    }
  }

  static Color getStatusColor(Status status) {
    switch (status) {
      case Status.received: return const Color(0xFF2D6A4F);
      case Status.inProgress: return const Color(0xFFF59E0B);
      case Status.resolved: return const Color(0xFF10B981);
      case Status.approved: return const Color(0xFF10B981);
      case Status.rejected: return const Color(0xFFEF4444);
    }
  }
}

class _ComplaintDetailsSheet extends StatelessWidget {
  final Complaint complaint;
  const _ComplaintDetailsSheet({required this.complaint});

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LanguageProvider>();
    final statusColor = _ModernComplaintCard.getStatusColor(complaint.status);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _ModernComplaintCard.getStatusLabel(complaint.status, lp).toUpperCase(),
                        style: GoogleFonts.inter(color: statusColor, fontWeight: FontWeight.w900, fontSize: 11),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  complaint.title,
                  style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: context.appTextPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('dd MMMM yyyy HH:mm').format(complaint.timestamp),
                  style: GoogleFonts.inter(color: context.appTextSecondary, fontSize: 13),
                ),
                const SizedBox(height: 32),
                Text(
                  lp.getText('detailed_description').toUpperCase(),
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 1),
                ),
                const SizedBox(height: 12),
                Text(
                  complaint.description,
                  style: GoogleFonts.inter(fontSize: 16, color: context.appTextPrimary, height: 1.6),
                ),
                
                if (complaint.imageUrl != null) ...[
                  const SizedBox(height: 32),
                  Text(
                    lp.getText('photo_optional').toUpperCase(),
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 1),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _showFullScreenImage(context, complaint.imageUrl!),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        complaint.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => Container(
                          height: 100,
                          color: Colors.grey.withValues(alpha: 0.1),
                          child: const Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey)),
                        ),
                      ),
                    ),
                  ),
                ],

                if (complaint.adminComment != null && complaint.adminComment!.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.admin_panel_settings_outlined, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              lp.getText('admin_response_title'),
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          complaint.adminComment!,
                          style: GoogleFonts.inter(fontSize: 14, color: context.appTextPrimary, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
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

class _ComplaintSubmissionSheet extends StatefulWidget {
  const _ComplaintSubmissionSheet();

  @override
  State<_ComplaintSubmissionSheet> createState() => _ComplaintSubmissionSheetState();
}

class _ComplaintSubmissionSheetState extends State<_ComplaintSubmissionSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedCategory = 'category_plumbing';
  XFile? _imageFile;
  bool _isUploading = false;
  bool _isUrgent = false;
  Uint8List? _previewBytes;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _imageFile = image;
        _previewBytes = bytes;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_titleController.text.isEmpty || _descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.read<LanguageProvider>().getText('err_fill_fields'))),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      String? imageUrl;
      if (_imageFile != null) {
        imageUrl = await CloudinaryService.uploadImage(_imageFile!);
      }

      if (!mounted) return;

      final auth = context.read<AuthProvider>();
      final firestore = context.read<FirestoreService>();
      final userId = auth.currentStudent?.matricule ?? auth.currentUserData?['uid'] ?? '';

      final residenceId = auth.currentResidenceId;

      final complaint = Complaint(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        category: context.read<LanguageProvider>().getText(_selectedCategory),
        userId: userId,
        priority: _isUrgent ? Priority.high : Priority.medium,
        status: Status.received,
        timestamp: DateTime.now(),
        imageUrl: imageUrl,
        isUrgent: _isUrgent,
      );

      await firestore.submitComplaint(complaint, residenceId: residenceId);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.read<LanguageProvider>().getText('complaint_success'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lp = context.watch<LanguageProvider>();
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                lp.getText('new_complaint'),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  color: context.appTextPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              IconButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/');
                  }
                },
                icon: const Icon(Icons.close_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: isDark ? context.appBackground : const Color(0xFFF1F5F9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel(lp.getText('complaint_title_label')),
                  const SizedBox(height: 10),
                  _buildModernTextField(
                    context: context,
                    controller: _titleController,
                    hint: lp.getText('complaint_title_hint'),
                  ),
                  const SizedBox(height: 24),
                  _buildFieldLabel(lp.getText('category') == 'category' ? 'Catégorie' : lp.getText('category')),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark ? context.appBackground : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.appBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        dropdownColor: isDark ? context.appCard : Colors.white,
                        items: ['category_plumbing', 'category_electricity', 'category_cleaning', 'category_furniture', 'category_security', 'category_other']
                            .map((catKey) => DropdownMenuItem(value: catKey, child: Text(lp.getText(catKey), style: GoogleFonts.inter(color: context.appTextPrimary))))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedCategory = val;
                              if (val != 'category_security') _isUrgent = false;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildFieldLabel(lp.getText('detailed_description')),
                  const SizedBox(height: 10),
                  _buildModernTextField(
                    context: context,
                    controller: _descController,
                    hint: lp.getText('describe_problem_hint'),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 24),
                  if (_selectedCategory == 'category_security') ...[
                    SwitchListTile(
                      value: _isUrgent,
                      onChanged: (val) => setState(() => _isUrgent = val),
                      title: Text(lp.getText('urgent_label'), style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: context.appTextPrimary)),
                      subtitle: Text(lp.getText('mark_as_urgent'), style: GoogleFonts.inter(fontSize: 12, color: context.appTextSecondary)),
                      secondary: Icon(Icons.warning_amber_rounded, color: _isUrgent ? Colors.red : Colors.grey),
                      contentPadding: EdgeInsets.zero,
                      activeColor: Colors.red,
                    ),
                    const SizedBox(height: 24),
                  ],
                  _buildFieldLabel(lp.getText('photo_optional')),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _isUploading ? null : _pickImage,
                    child: _previewBytes != null 
                      ? Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            image: DecorationImage(
                              image: MemoryImage(_previewBytes!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      : _UploadPlaceholder(),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isUploading 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(
                            lp.getText('submit_complaint'),
                            style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        color: Colors.grey,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildModernTextField({required BuildContext context, required TextEditingController controller, required String hint, int? maxLines = 1}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? context.appBackground : const Color(0xFFF1F5F9).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: context.appBorder) : null,
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(color: context.appTextPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: context.appTextSecondary, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }
}

class _UploadPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lp = context.watch<LanguageProvider>();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? context.appBackground : const Color(0xFFF1F5F9),
        border: Border.all(color: isDark ? context.appBorder : AppColors.primary.withValues(alpha: 0.3), style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            lp.getText('add_visual_proof'),
            style: GoogleFonts.inter(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            lp.getText('accepted_formats'),
            style: GoogleFonts.inter(color: Colors.grey, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
