import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
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
          SnackBar(content: Text('Error picking image: $e')),
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

      // Use the UID for consistency across all login methods
      final userId = authProvider.currentStudent?.matricule ?? authProvider.currentUserData?['uid'] ?? '';
      
      if (userId.isEmpty) {
        throw Exception("Impossible de trouver l'ID utilisateur");
      }

      String? imageUrl;

      if (_imageFile != null) {
        // We use XFile for Cloudinary (cross-platform handle)
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
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LanguageProvider>();
    final categories = [
      {'id': 'repair', 'title': lp.getText('repair')},
      {'id': 'cleaning', 'title': lp.getText('cleaning')},
      {'id': 'housing', 'title': lp.getText('housing')},
    ];

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CustomMenuButton(
            backgroundColor: context.appTextPrimary.withValues(alpha: 0.1),
            iconColor: context.appTextPrimary,
          ),
        ),
        title: Text(lp.getText('new_request'), style: TextStyle(color: context.appTextPrimary)),
        backgroundColor: context.appCard,
        iconTheme: IconThemeData(color: context.appTextPrimary),
        elevation: 0,
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lp.getText('category'),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: context.appTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: context.appCard,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: context.appBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: context.appBorder),
                        ),
                      ),
                      items: categories.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat['id'],
                          child: Text(cat['title']!),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedCategory = value),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      lp.getText('description'),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: context.appTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: lp.getText('describe_problem'),
                        filled: true,
                        fillColor: context.appCard,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: context.appBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: context.appBorder),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer une description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      lp.getText('photo'),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: context.appTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_imageFile != null)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: kIsWeb 
                              ? Image.network(_imageFile!.path, height: 200, width: double.infinity, fit: BoxFit.cover)
                              : Image.file(_imageFile!, height: 200, width: double.infinity, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              backgroundColor: Colors.black54,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white),
                                onPressed: () => setState(() => _imageFile = null),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: _buildImageSourceButton(
                              icon: Icons.camera_alt_outlined,
                              label: lp.getText('camera'),
                              onTap: () => _pickImage(ImageSource.camera),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildImageSourceButton(
                              icon: Icons.photo_library_outlined,
                              label: lp.getText('gallery'),
                              onTap: () => _pickImage(ImageSource.gallery),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 48),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          lp.getText('submit'),
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImageSourceButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: context.appCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.appBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: context.appTextSecondary)),
          ],
        ),
      ),
    );
  }
}
