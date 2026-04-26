import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/colors.dart';
import '../services/firestore_service.dart';
import '../services/cloudinary_service.dart';
import '../providers/auth_provider.dart';
import '../models/types.dart';

class AdminDiningConfigView extends StatefulWidget {
  const AdminDiningConfigView({super.key});

  @override
  State<AdminDiningConfigView> createState() => _AdminDiningConfigViewState();
}

class _AdminDiningConfigViewState extends State<AdminDiningConfigView> {
  final _breakfastController = TextEditingController();
  final _lunchController = TextEditingController();
  final _dinnerController = TextEditingController();
  
  String? _breakfastImage;
  String? _lunchImage;
  String? _dinnerImage;
  
  bool _isBreakfastUploading = false;
  bool _isLunchUploading = false;
  bool _isDinnerUploading = false;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final firestore = context.watch<FirestoreService>();
    final auth = context.watch<AuthProvider>();
    final residenceId = auth.currentResidenceId ?? auth.currentUserData?['residenceId'] as String?;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (residenceId == null || residenceId.isEmpty) {
      return _buildNoResidence(context);
    }

    return StreamBuilder<RestaurantInfo?>(
      stream: firestore.streamRestaurantInfo(residenceId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final info = snapshot.data;
        if (info != null && _breakfastController.text.isEmpty && !_isSaving) {
           _breakfastController.text = info.breakfast.menu;
           _lunchController.text = info.lunch.menu;
           _dinnerController.text = info.dinner.menu;
           _breakfastImage = info.breakfast.imageUrl;
           _lunchImage = info.lunch.imageUrl;
           _dinnerImage = info.dinner.imageUrl;
        }

        return Scaffold(
          backgroundColor: context.appBackground,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, info?.isOpen ?? true, residenceId, firestore),
                const SizedBox(height: 32),
                
                _buildMealEditor(
                  'Petit-déjeuner',
                  _breakfastController,
                  _breakfastImage,
                  _isBreakfastUploading,
                  (url) => setState(() => _breakfastImage = url),
                  (val) => setState(() => _isBreakfastUploading = val),
                  isDark,
                  const Color(0xFFF4A261),
                  Icons.coffee_rounded,
                ).animate().fade().slideX(begin: -0.1),
                
                const SizedBox(height: 24),
                
                _buildMealEditor(
                  'Déjeuner',
                  _lunchController,
                  _lunchImage,
                  _isLunchUploading,
                  (url) => setState(() => _lunchImage = url),
                  (val) => setState(() => _isLunchUploading = val),
                  isDark,
                  const Color(0xFF2A9D8F),
                  Icons.wb_sunny_rounded,
                ).animate().fade().slideX(begin: 0.1, delay: 100.ms),
                
                const SizedBox(height: 24),
                
                _buildMealEditor(
                  'Dîner',
                  _dinnerController,
                  _dinnerImage,
                  _isDinnerUploading,
                  (url) => setState(() => _dinnerImage = url),
                  (val) => setState(() => _isDinnerUploading = val),
                  isDark,
                  const Color(0xFF264653),
                  Icons.nightlight_round,
                ).animate().fade().slideX(begin: -0.1, delay: 200.ms),
                
                const SizedBox(height: 40),
                
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : () => _save(residenceId, firestore, info?.isOpen ?? true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      shadowColor: AppColors.primary.withValues(alpha: 0.3),
                    ),
                    child: _isSaving 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('Enregistrer le Menu', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ).animate().scale(delay: 400.ms),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isOpen, String resId, FirestoreService firestore) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Restaurant',
              style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: context.appTextPrimary),
            ),
            Text(
              'Gérez les repas et l\'état du restaurant',
              style: GoogleFonts.outfit(fontSize: 14, color: context.appTextSecondary),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => firestore.toggleRestaurantStatus(resId, !isOpen),
          child: AnimatedContainer(
            duration: 300.ms,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isOpen ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isOpen ? Colors.green : Colors.red, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(isOpen ? Icons.lock_open_rounded : Icons.lock_rounded, color: isOpen ? Colors.green : Colors.red, size: 18),
                const SizedBox(width: 8),
                Text(
                  isOpen ? 'OUVERT' : 'FERMÉ',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: isOpen ? Colors.green : Colors.red),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMealEditor(
    String title,
    TextEditingController controller,
    String? imageUrl,
    bool isUploading,
    Function(String) onImageUploaded,
    Function(bool) onUploadStateChanged,
    bool isDark,
    Color accentColor,
    IconData icon,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.appBorder.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: accentColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: context.appTextPrimary)),
              ],
            ),
          ),
          if (imageUrl != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(imageUrl, height: 160, width: double.infinity, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => onImageUploaded(''),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                TextField(
                  controller: controller,
                  maxLines: 2,
                  style: GoogleFonts.outfit(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Que mange-t-on pour le $title ?',
                    hintStyle: TextStyle(color: context.appTextSecondary.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isUploading ? null : () => _pickImage(onImageUploaded, onUploadStateChanged),
                        icon: isUploading 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.add_a_photo_rounded, size: 18),
                        label: Text(imageUrl != null ? 'Modifier l\'image' : 'Ajouter une image', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(Function(String) onDone, Function(bool) onState) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image == null) return;
    
    onState(true);
    try {
      final url = await CloudinaryService.uploadImage(image);
      if (url != null) onDone(url);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur upload: $e')));
    } finally {
      onState(false);
    }
  }

  Future<void> _save(String resId, FirestoreService firestore, bool isOpen) async {
    setState(() => _isSaving = true);
    try {
      final info = RestaurantInfo(
        residenceId: resId,
        isOpen: isOpen,
        breakfast: RestaurantMeal(menu: _breakfastController.text, imageUrl: _breakfastImage, startTime: '07:00', endTime: '09:00'),
        lunch: RestaurantMeal(menu: _lunchController.text, imageUrl: _lunchImage, startTime: '12:00', endTime: '14:00'),
        dinner: RestaurantMeal(menu: _dinnerController.text, imageUrl: _dinnerImage, startTime: '18:30', endTime: '20:30'),
        lastUpdated: DateTime.now(),
      );
      await firestore.updateRestaurantInfo(info);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Menu mis à jour avec succès !', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Widget _buildNoResidence(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_off_rounded, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('Aucune résidence configurée', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
