import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/types.dart';
import '../services/firestore_service.dart';
import '../services/cloudinary_service.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../core/theme/colors.dart';
import '../components/custom_menu_button.dart';

class CreateRequestScreen extends StatefulWidget {
  final String? initialCategory;

  const CreateRequestScreen({super.key, this.initialCategory});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String? _selectedCategory;
  File? _imageFile;
  bool _isSubmitting = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du choix de l\'image: $e')),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez sélectionner une catégorie')),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final firestoreService = context.read<FirestoreService>();
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);

      final userId = authProvider.currentStudent?.matricule ?? authProvider.currentUserData?['uid'] ?? '';
      
      if (userId.isEmpty) {
        throw Exception("Impossible de trouver l'ID utilisateur");
      }

      String? imageUrl;
      if (_imageFile != null) {
        final xFile = XFile(_imageFile!.path);
        imageUrl = await CloudinaryService.uploadImage(xFile);
      }

      final request = ServiceRequest(
        userId: userId,
        category: _selectedCategory!,
        description: _descriptionController.text.trim(),
        status: 'pending',
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
      );

      final residenceId = authProvider.currentResidenceId;
      await firestoreService.submitServiceRequest(request, residenceId: residenceId);

      if (mounted) {
        navigator.pop();
        messenger.showSnackBar(
          const SnackBar(content: Text('Demande soumise avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LanguageProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = [
      {'id': 'repair', 'title': lp.getText('repair'), 'icon': Icons.build_rounded},
      {'id': 'cleaning', 'title': lp.getText('cleaning'), 'icon': Icons.cleaning_services_rounded},
      {'id': 'housing', 'title': lp.getText('housing'), 'icon': Icons.home_repair_service_rounded},
    ];

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: context.appBackground,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CustomMenuButton(
            backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.primary.withValues(alpha: 0.05),
            iconColor: isDark ? Colors.white : AppColors.primary,
          ),
        ),
        title: Text(
          lp.getText('new_request'), 
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20, color: context.appTextPrimary)
        ),
        centerTitle: true,
      ),
      body: _isSubmitting
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('Envoi en cours...', style: GoogleFonts.outfit(color: context.appTextSecondary)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(lp.getText('category')),
                    const SizedBox(height: 12),
                    _buildCategorySelector(categories, isDark),
                    const SizedBox(height: 24),
                    _buildSectionTitle(lp.getText('description')),
                    const SizedBox(height: 12),
                    _buildDescriptionField(lp, isDark),
                    const SizedBox(height: 24),
                    _buildSectionTitle(lp.getText('photo')),
                    const SizedBox(height: 12),
                    _buildImageUploader(lp, isDark),
                    const SizedBox(height: 48),
                    _buildSubmitButton(lp),
                    const SizedBox(height: 20),
                  ].animate(interval: 50.ms).fade(duration: 300.ms).slideY(begin: 0.1, end: 0),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: context.appTextPrimary,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildCategorySelector(List<Map<String, dynamic>> categories, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          value: _selectedCategory,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
          decoration: const InputDecoration(border: InputBorder.none),
          hint: Text('Choisir une catégorie', style: GoogleFonts.outfit(color: context.appTextSecondary, fontSize: 14)),
          items: categories.map((cat) {
            return DropdownMenuItem<String>(
              value: cat['id'],
              child: Row(
                children: [
                  Icon(cat['icon'] as IconData, size: 20, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Text(cat['title'] as String, style: GoogleFonts.outfit(fontSize: 14)),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedCategory = value),
        ),
      ),
    );
  }

  Widget _buildDescriptionField(LanguageProvider lp, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: TextFormField(
        controller: _descriptionController,
        maxLines: 5,
        style: GoogleFonts.inter(fontSize: 14, color: context.appTextPrimary),
        decoration: InputDecoration(
          hintText: lp.getText('describe_problem'),
          hintStyle: GoogleFonts.inter(color: context.appTextSecondary.withValues(alpha: 0.5), fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Veuillez entrer une description';
          return null;
        },
      ),
    );
  }

  Widget _buildImageUploader(LanguageProvider lp, bool isDark) {
    if (_imageFile != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: kIsWeb 
              ? Image.network(_imageFile!.path, height: 220, width: double.infinity, fit: BoxFit.cover)
              : Image.file(_imageFile!, height: 220, width: double.infinity, fit: BoxFit.cover),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: () => setState(() => _imageFile = null),
                child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack);
    }

    return Row(
      children: [
        Expanded(
          child: _buildImageSourceButton(
            icon: Icons.camera_enhance_rounded,
            label: lp.getText('camera'),
            onTap: () => _pickImage(ImageSource.camera),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildImageSourceButton(
            icon: Icons.photo_library_rounded,
            label: lp.getText('gallery'),
            onTap: () => _pickImage(ImageSource.gallery),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSourceButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: context.appCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.appBorder.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(height: 12),
              Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: context.appTextSecondary, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(LanguageProvider lp) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)]),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: ElevatedButton(
        onPressed: _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          lp.getText('submit'),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }
}
