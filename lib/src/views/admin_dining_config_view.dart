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
  int _selectedDayIndex = 0;
  bool _isInitialized = false;
  
  final List<TextEditingController> _breakfastControllers = List.generate(3, (_) => TextEditingController());
  final List<TextEditingController> _lunchControllers = List.generate(3, (_) => TextEditingController());
  final List<TextEditingController> _dinnerControllers = List.generate(3, (_) => TextEditingController());
  
  final List<String?> _breakfastImages = List.generate(3, (_) => null);
  final List<String?> _lunchImages = List.generate(3, (_) => null);
  final List<String?> _dinnerImages = List.generate(3, (_) => null);
  
  final List<bool> _uploadingStates = List.generate(3, (_) => false);
  bool _isSaving = false;

  @override
  void dispose() {
    for (var c in _breakfastControllers) {
      c.dispose();
    }
    for (var c in _lunchControllers) {
      c.dispose();
    }
    for (var c in _dinnerControllers) {
      c.dispose();
    }
    super.dispose();
  }

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
        if (info != null && !_isInitialized && !_isSaving) {
          for (int i = 0; i < 3; i++) {
            if (i < info.days.length) {
              final day = info.days[i];
              _breakfastControllers[i].text = day.breakfast.menu;
              _lunchControllers[i].text = day.lunch.menu;
              _dinnerControllers[i].text = day.dinner.menu;
              _breakfastImages[i] = day.breakfast.imageUrl;
              _lunchImages[i] = day.lunch.imageUrl;
              _dinnerImages[i] = day.dinner.imageUrl;
            }
          }
          _isInitialized = true;
        }

        // Current editing meals
        final currentMeals = (info != null && _selectedDayIndex < info.days.length) 
            ? info.days[_selectedDayIndex] 
            : null;

        return Scaffold(
          backgroundColor: context.appBackground,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 24),
                _buildDaySelector(),
                const SizedBox(height: 32),
                
                _buildMealEditor(
                  'Petit-déjeuner',
                  _breakfastControllers[_selectedDayIndex],
                  _breakfastImages[_selectedDayIndex],
                  _uploadingStates[_selectedDayIndex],
                  (url) => setState(() => _breakfastImages[_selectedDayIndex] = url),
                  (val) => setState(() => _uploadingStates[_selectedDayIndex] = val),
                  isDark,
                  const Color(0xFFF4A261),
                  Icons.coffee_rounded,
                  currentMeals?.breakfast ?? RestaurantMeal(menu: '', startTime: '07:00', endTime: '09:00'),
                ).animate(key: ValueKey('breakfast_$_selectedDayIndex')).fade().slideX(begin: -0.1),
                
                const SizedBox(height: 24),
                
                _buildMealEditor(
                  'Déjeuner',
                  _lunchControllers[_selectedDayIndex],
                  _lunchImages[_selectedDayIndex],
                  _uploadingStates[_selectedDayIndex],
                  (url) => setState(() => _lunchImages[_selectedDayIndex] = url),
                  (val) => setState(() => _uploadingStates[_selectedDayIndex] = val),
                  isDark,
                  const Color(0xFF2A9D8F),
                  Icons.wb_sunny_rounded,
                  currentMeals?.lunch ?? RestaurantMeal(menu: '', startTime: '12:00', endTime: '14:00'),
                ).animate(key: ValueKey('lunch_$_selectedDayIndex')).fade().slideX(begin: 0.1, delay: 100.ms),
                
                const SizedBox(height: 24),
                
                _buildMealEditor(
                  'Dîner',
                  _dinnerControllers[_selectedDayIndex],
                  _dinnerImages[_selectedDayIndex],
                  _uploadingStates[_selectedDayIndex],
                  (url) => setState(() => _dinnerImages[_selectedDayIndex] = url),
                  (val) => setState(() => _uploadingStates[_selectedDayIndex] = val),
                  isDark,
                  const Color(0xFF264653),
                  Icons.nightlight_round,
                  currentMeals?.dinner ?? RestaurantMeal(menu: '', startTime: '18:30', endTime: '20:30'),
                ).animate(key: ValueKey('dinner_$_selectedDayIndex')).fade().slideX(begin: -0.1, delay: 200.ms),
                
                const SizedBox(height: 40),
                
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : () => _save(residenceId, firestore, info),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      shadowColor: AppColors.primary.withValues(alpha: 0.3),
                    ),
                    child: _isSaving 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('Enregistrer le Planning Complet', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
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

  Widget _buildDaySelector() {
    final now = DateTime.now();
    return Container(
      height: 60,
      child: Row(
        children: List.generate(3, (index) {
          final isSelected = _selectedDayIndex == index;
          final date = now.add(Duration(days: index));
          String label = '';
          if (index == 0) label = 'Aujourd\'hui';
          else if (index == 1) label = 'Demain';
          else label = '${date.day}/${date.month}';

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedDayIndex = index),
              child: AnimatedContainer(
                duration: 300.ms,
                margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : context.appCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isSelected ? AppColors.primary : context.appBorder),
                  boxShadow: isSelected ? [
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))
                  ] : null,
                ),
                child: Center(
                  child: Text(
                    label,
                    style: GoogleFonts.outfit(
                      color: isSelected ? Colors.white : context.appTextPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Restaurant Configuration',
          style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: context.appTextPrimary),
        ),
        Text(
          'Gérez le menu pour les 3 prochains jours',
          style: GoogleFonts.outfit(fontSize: 14, color: context.appTextSecondary),
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
    RestaurantMeal meal,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
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
                // Stats Badge
                Row(
                  children: [
                    _buildStatIcon(Icons.bookmark_added_rounded, meal.reservedBy.length.toString(), Colors.blue),
                    const SizedBox(width: 8),
                    _buildStatIcon(Icons.star_rounded, meal.averageRating.toStringAsFixed(1), const Color(0xFFFFB703)),
                  ],
                ),
              ],
            ),
          ),
          if (imageUrl != null && imageUrl.isNotEmpty)
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
                        label: Text(imageUrl != null && imageUrl.isNotEmpty ? 'Modifier l\'image' : 'Ajouter une image', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
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

  Widget _buildStatIcon(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
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

  Future<void> _save(String resId, FirestoreService firestore, RestaurantInfo? existingInfo) async {
    setState(() => _isSaving = true);
    try {
      final now = DateTime.now();
      List<RestaurantDay> days = [];
      
      for (int i = 0; i < 3; i++) {
        final existingDay = (existingInfo != null && i < existingInfo.days.length) ? existingInfo.days[i] : null;
        
        days.add(RestaurantDay(
          date: DateTime(now.year, now.month, now.day).add(Duration(days: i)),
          breakfast: RestaurantMeal(
            menu: _breakfastControllers[i].text, 
            imageUrl: _breakfastImages[i], 
            startTime: '07:00', 
            endTime: '09:00',
            reservedBy: existingDay?.breakfast.reservedBy ?? [],
            ratedBy: existingDay?.breakfast.ratedBy ?? [],
            averageRating: existingDay?.breakfast.averageRating ?? 0.0,
            ratingCount: existingDay?.breakfast.ratingCount ?? 0,
          ),
          lunch: RestaurantMeal(
            menu: _lunchControllers[i].text, 
            imageUrl: _lunchImages[i], 
            startTime: '12:00', 
            endTime: '14:00',
            reservedBy: existingDay?.lunch.reservedBy ?? [],
            ratedBy: existingDay?.lunch.ratedBy ?? [],
            averageRating: existingDay?.lunch.averageRating ?? 0.0,
            ratingCount: existingDay?.lunch.ratingCount ?? 0,
          ),
          dinner: RestaurantMeal(
            menu: _dinnerControllers[i].text, 
            imageUrl: _dinnerImages[i], 
            startTime: '18:30', 
            endTime: '20:30',
            reservedBy: existingDay?.dinner.reservedBy ?? [],
            ratedBy: existingDay?.dinner.ratedBy ?? [],
            averageRating: existingDay?.dinner.averageRating ?? 0.0,
            ratingCount: existingDay?.dinner.ratingCount ?? 0,
          ),
        ));
      }

      final info = RestaurantInfo(
        residenceId: resId,
        days: days,
        lastUpdated: DateTime.now(),
      );
      
      await firestore.updateRestaurantInfo(info);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Planning complet mis à jour !', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
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
