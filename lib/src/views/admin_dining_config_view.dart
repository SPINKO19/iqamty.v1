import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme/colors.dart';

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
    final firestore = context.watch<FirestoreService>();
    final auth = context.watch<AuthProvider>();
    final residenceId = auth.currentResidenceId
        ?? auth.currentUserData?['residenceId'] as String?;

    // Guard: if residenceId is null we cannot read/write meals
    if (residenceId == null || residenceId.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                'Aucune résidence associée à ce compte.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.appTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Veuillez contacter le support ou configurer une résidence dans Firestore (champ residenceId).',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: context.appTextSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<List<Meal>>(
        stream:
            firestore.getMealsForDate(_selectedDate, residenceId: residenceId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erreur repas: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }
          final meals = snapshot.data ?? [];

          return StreamBuilder<bool>(
              stream: firestore.streamRestaurantStatus(residenceId),
              builder: (context, statusSnapshot) {
                if (statusSnapshot.hasError) {
                  return Center(child: Text('Erreur status: ${statusSnapshot.error}', style: const TextStyle(color: Colors.red)));
                }
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
                          _buildSectionHeader('Menu du Jour',
                              'Configurez le menu de la cafétéria'),
                          _buildRestaurantStatusToggle(
                              isRestaurantOpen, residenceId, firestore),
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
                                color: const Color(0xFF1D5C35).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.calendar_month_rounded,
                                  color: context.isDark
                                      ? AppColors.primary
                                      : const Color(0xFF1D5C35)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Sélectionnez la date',
                                      style: GoogleFonts.inter(
                                          color: context.appTextSecondary,
                                          fontSize: 13)),
                                  const SizedBox(height: 4),
                                  Text(
                                      DateFormat.yMMMMEEEEd('fr')
                                          .format(_selectedDate),
                                      style: GoogleFonts.inter(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: context.appTextPrimary)),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                final date = await showDatePicker(
                                    context: context,
                                    initialDate: _selectedDate,
                                    firstDate: DateTime.now()
                                        .subtract(const Duration(days: 30)),
                                    lastDate: DateTime.now()
                                        .add(const Duration(days: 365)));
                                if (date != null) {
                                  setState(() => _selectedDate = date);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.isDark
                                    ? AppColors.primary
                                    : const Color(0xFF0E2318),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                              child: const Text('Changer',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      _buildMealSection(
                          'Petit-déjeuner',
                          Icons.free_breakfast_rounded,
                          const Color(0xFFF4A261),
                          '07:00',
                          '09:00',
                          'breakfast',
                          meals,
                          residenceId,
                          firestore),
                      const SizedBox(height: 16),
                      _buildMealSection(
                          'Déjeuner',
                          Icons.wb_sunny_rounded,
                          const Color(0xFF42A5F5),
                          '12:00',
                          '14:00',
                          'lunch',
                          meals,
                          residenceId,
                          firestore),
                      const SizedBox(height: 16),
                      _buildMealSection(
                          'Dîner',
                          Icons.nightlight_round,
                          const Color(0xFF7E57C2),
                          '18:00',
                          '20:00',
                          'dinner',
                          meals,
                          residenceId,
                          firestore),
                      const SizedBox(height: 40),
                    ],
                  ),
                );
              });
        });
  }

  Widget _buildRestaurantStatusToggle(
      bool isOpen, String? residenceId, FirestoreService firestore) {
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
          color: isOpen
              ? Colors.green.withValues(alpha: 0.1)
              : Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: isOpen ? Colors.green : Colors.red),
        ),
        child: Row(
          children: [
            Icon(
                isOpen
                    ? Icons.check_circle_outline_rounded
                    : Icons.do_not_disturb_on_rounded,
                color: isOpen ? Colors.green : Colors.red,
                size: 18),
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
          style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: context.appTextPrimary),
        ),
        Text(
          subtitle,
          style:
              GoogleFonts.inter(fontSize: 12, color: context.appTextSecondary),
        ),
      ],
    );
  }

  Widget _buildMealSection(
      String title,
      IconData icon,
      Color color,
      String defaultStart,
      String defaultEnd,
      String type,
      List<Meal> meals,
      String? residenceId,
      FirestoreService firestore) {
    final meal = meals.firstWhere((m) => m.mealType == type,
        orElse: () => Meal(
            menu: title,
            type: type,
            date: _selectedDate,
            startTime: defaultStart,
            endTime: defaultEnd,
            menuItems: []));

    return Container(
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.appBorder),
        boxShadow: Theme.of(context).brightness == Brightness.light
            ? [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ]
            : null,
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
                      Text(title,
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: context.appTextPrimary)),
                      Text('${meal.startTime} - ${meal.endTime}',
                          style: GoogleFonts.inter(
                              color: context.appTextSecondary, fontSize: 13)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add_circle_outline_rounded,
                      color: context.appTextSecondary),
                  onPressed: () =>
                      _showAddMenuItemDialog(meal, residenceId, firestore),
                ),
                if (meal.id != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Colors.redAccent),
                    tooltip: 'Supprimer ce repas',
                    onPressed: () => _confirmDeleteMeal(meal, firestore),
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
                    style: GoogleFonts.inter(
                        color: context.appTextSecondary,
                        fontStyle: FontStyle.italic),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: meal.menuItems
                        .map((item) =>
                            _buildMenuChip(item, meal, residenceId, firestore))
                        .toList(),
                  ),
          ),
          if (meal.id != null && meal.ratingCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: context.appBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.appBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Colors.amber, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      meal.averageRating.toStringAsFixed(1),
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: context.appTextPrimary),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${meal.ratingCount} avis étudiants)',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: context.appTextSecondary),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuChip(String label, Meal meal, String? residenceId,
      FirestoreService firestore) {
    return Chip(
      label: Text(label,
          style:
              GoogleFonts.inter(fontSize: 12, color: context.appTextPrimary)),
      backgroundColor: context.appBackground,
      deleteIcon: const Icon(Icons.cancel, size: 16),
      onDeleted: () {
        final newItems = List<String>.from(meal.menuItems)..remove(label);
        if (meal.id != null) {
          firestore.updateMealItems(meal.id!, newItems);
        } else {
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
            ratedBy: meal.ratedBy,
          );
          _saveMealWithFeedback(updatedMeal, residenceId, firestore);
        }
      },
    );
  }

  /// Saves a meal and shows a SnackBar with the result.
  Future<void> _saveMealWithFeedback(
      Meal meal, String? residenceId, FirestoreService firestore) async {
    if (residenceId == null || residenceId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur : aucune résidence configurée.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    try {
      await firestore.saveMeal(meal, residenceId: residenceId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Menu enregistré avec succès ✓'),
            backgroundColor: Color(0xFF2D6A4F),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddMenuItemDialog(
      Meal meal, String? residenceId, FirestoreService firestore) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajouter un plat'),
        content: TextField(
          controller: controller,
          decoration:
              const InputDecoration(hintText: 'Nom du plat (ex: Couscous)'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(ctx);
                final newItems = List<String>.from(meal.menuItems)..add(text);
                if (meal.id != null) {
                  // Meal already exists in Firestore — just update the items array
                  try {
                    await firestore.updateMealItems(meal.id!, newItems);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Plat ajouté avec succès ✓'),
                          backgroundColor: Color(0xFF2D6A4F),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur : $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                } else {
                  // New meal — create it in Firestore
                  final newMeal = Meal(
                    menu: meal.menu,
                    type: meal.type,
                    date: meal.date,
                    startTime: meal.startTime,
                    endTime: meal.endTime,
                    menuItems: newItems,
                  );
                  await _saveMealWithFeedback(newMeal, residenceId, firestore);
                }
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteMeal(Meal meal, FirestoreService firestore) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce repas ?'),
        content: Text(
            'Voulez-vous vraiment supprimer le repas "${meal.menu}" du ${DateFormat('d MMMM yyyy', 'fr').format(meal.date)} ? Cette action est irréversible.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              firestore.deleteMeal(meal.id!);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Repas supprimé')),
              );
            },
            child: const Text('Supprimer',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
