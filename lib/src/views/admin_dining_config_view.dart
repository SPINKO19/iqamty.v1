import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme/colors.dart';
import '../components/custom_menu_button.dart';
import '../providers/language_provider.dart';

import '../services/firestore_service.dart';
import '../providers/auth_provider.dart';
import '../models/types.dart';

class AdminDiningConfigView extends StatefulWidget {
  const AdminDiningConfigView({super.key});

  @override
  State<AdminDiningConfigView> createState() => _AdminDiningConfigViewState();
}

class _AdminDiningConfigViewState extends State<AdminDiningConfigView> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LanguageProvider>();
    final firestore = context.watch<FirestoreService>();
    final auth = context.read<AuthProvider>();
    final residenceId = auth.currentResidenceId;

    return StreamBuilder<List<Meal>>(
      stream: firestore.getMealsForDate(_selectedDate, residenceId: residenceId),
      builder: (context, snapshot) {
        final meals = snapshot.data ?? [];
        
        return StreamBuilder<bool>(
          stream: firestore.streamRestaurantStatus(residenceId),
          builder: (context, statusSnapshot) {
            final isRestaurantOpen = statusSnapshot.data ?? true;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionHeader('Menu du Jour', 'Configurez le menu de la cafétéria'),
                      _buildRestaurantStatusToggle(isRestaurantOpen, residenceId, firestore),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Date Picker Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: context.appCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.appBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1D5C35).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.calendar_month_rounded, color: context.isDark ? AppColors.primary : const Color(0xFF1D5C35)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Sélectionnez la date', style: GoogleFonts.inter(color: context.appTextSecondary, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(DateFormat('EEEE d MMMM yyyy', 'fr').format(_selectedDate), style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: context.appTextPrimary)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                             final date = await showDatePicker(
                                context: context, 
                                initialDate: _selectedDate, 
                                firstDate: DateTime.now().subtract(const Duration(days: 30)), 
                                lastDate: DateTime.now().add(const Duration(days: 365))
                             );
                             if(date != null) setState(() => _selectedDate = date);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.isDark ? AppColors.primary : const Color(0xFF0E2318),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          child: const Text('Changer', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  _buildMealSection(
                    'Petit-déjeuner', 
                    Icons.free_breakfast_rounded, 
                    const Color(0xFFF4A261), 
                    '07:00', '09:00', 
                    'breakfast', 
                    meals, residenceId, firestore
                  ),
                  const SizedBox(height: 16),
                  _buildMealSection(
                    'Déjeuner', 
                    Icons.wb_sunny_rounded, 
                    const Color(0xFF42A5F5), 
                    '12:00', '14:00', 
                    'lunch', 
                    meals, residenceId, firestore
                  ),
                  const SizedBox(height: 16),
                  _buildMealSection(
                    'Dîner', 
                    Icons.nightlight_round, 
                    const Color(0xFF7E57C2), 
                    '18:00', '20:00', 
                    'dinner', 
                    meals, residenceId, firestore
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            );
          }
        );
      }
    );
  }

  Widget _buildRestaurantStatusToggle(bool isOpen, String? residenceId, FirestoreService firestore) {
    return InkWell(
      onTap: () {
        if (residenceId != null) {
          firestore.toggleRestaurantStatus(residenceId, !isOpen);
        }
      },
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isOpen ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: isOpen ? Colors.green : Colors.red),
        ),
        child: Row(
          children: [
            Icon(isOpen ? Icons.check_circle_outline_rounded : Icons.do_not_disturb_on_rounded, 
                 color: isOpen ? Colors.green : Colors.red, size: 18),
            const SizedBox(width: 8),
            Text(
              isOpen ? 'OUVERT' : 'FERMÉ',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isOpen ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: context.appTextPrimary),
        ),
        Text(
          subtitle,
          style: GoogleFonts.inter(fontSize: 12, color: context.appTextSecondary),
        ),
      ],
    );
  }

  Widget _buildMealSection(String title, IconData icon, Color color, String defaultStart, String defaultEnd, String type, List<Meal> meals, String? residenceId, FirestoreService firestore) {
    final meal = meals.firstWhere((m) => m.mealType == type, 
      orElse: () => Meal(menu: title, type: type, date: _selectedDate, startTime: defaultStart, endTime: defaultEnd, menuItems: []));

    return Container(
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.appBorder),
        boxShadow: Theme.of(context).brightness == Brightness.light ? [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18, color: context.appTextPrimary)),
                      Text('${meal.startTime} - ${meal.endTime}', style: GoogleFonts.inter(color: context.appTextSecondary, fontSize: 13)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add_circle_outline_rounded, color: context.appTextSecondary),
                  onPressed: () => _showAddMenuItemDialog(meal, residenceId, firestore),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: context.appBorder),
          Padding(
            padding: const EdgeInsets.all(20),
            child: meal.menuItems.isEmpty 
              ? Text(
                  'Aucun plat configuré pour ce repas. Cliquez sur le bouton "+" pour ajouter des éléments au menu.',
                  style: GoogleFonts.inter(color: context.appTextSecondary, fontStyle: FontStyle.italic),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: meal.menuItems.map((item) => _buildMenuChip(item, meal, residenceId, firestore)).toList(),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuChip(String label, Meal meal, String? residenceId, FirestoreService firestore) {
    return Chip(
      label: Text(label, style: GoogleFonts.inter(fontSize: 12, color: context.appTextPrimary)),
      backgroundColor: context.appBackground,
      deleteIcon: const Icon(Icons.cancel, size: 16),
      onDeleted: () {
        final newItems = List<String>.from(meal.menuItems)..remove(label);
        final updatedMeal = Meal(
          id: meal.id,
          menu: meal.menu,
          type: meal.type,
          date: meal.date,
          startTime: meal.startTime,
          endTime: meal.endTime,
          menuItems: newItems,
          reservedBy: meal.reservedBy,
          averageRating: meal.averageRating,
          ratingCount: meal.ratingCount,
        );
        firestore.saveMeal(updatedMeal, residenceId: residenceId);
      },
    );
  }

  void _showAddMenuItemDialog(Meal meal, String? residenceId, FirestoreService firestore) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajouter un plat'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nom du plat (ex: Couscous)'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                final newItems = List<String>.from(meal.menuItems)..add(controller.text);
                final updatedMeal = Meal(
                  id: meal.id,
                  menu: meal.menu,
                  type: meal.type,
                  date: meal.date,
                  startTime: meal.startTime,
                  endTime: meal.endTime,
                  menuItems: newItems,
                  reservedBy: meal.reservedBy,
                  averageRating: meal.averageRating,
                  ratingCount: meal.ratingCount,
                );
                firestore.saveMeal(updatedMeal, residenceId: residenceId);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }
}
