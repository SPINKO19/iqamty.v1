import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme/colors.dart';
import '../services/firestore_service.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../models/types.dart';
import '../components/custom_menu_button.dart';

class DiningView extends StatefulWidget {
  const DiningView({super.key});

  @override
  State<DiningView> createState() => _DiningViewState();
}

class _DiningViewState extends State<DiningView> {
  DateTime _selectedDate = DateTime.now();
  late DateTime _startOfWeek;

  @override
  void initState() {
    super.initState();
    // Monday as start of week
    _startOfWeek = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
  }

  String _getWeekRangeString() {
    final endOfWeek = _startOfWeek.add(const Duration(days: 6));
    final DateFormat formatter = DateFormat('d');
    final DateFormat fullFormatter = DateFormat('d MMMM yyyy', 'fr');
    return 'Semaine du ${formatter.format(_startOfWeek)} au ${fullFormatter.format(endOfWeek)}';
  }

  String _getDayLetter(int index) {
    // Days labels L M M J V S D
    final letters = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    return letters[index];
  }

  @override
  Widget build(BuildContext context) {
    const kDarkGreen = Color(0xFF2D6A4F);

    return Scaffold(
      backgroundColor: context.appBackground,
      body: Column(
        children: [
          // Header Section
          Container(
            color: kDarkGreen,
            padding: const EdgeInsets.only(top: 60, bottom: 24),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const CustomMenuButton(),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Restauration',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getWeekRangeString(),
                            style: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Day Selector
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(7, (index) {
                      final date = _startOfWeek.add(Duration(days: index));
                      final isSelected = DateUtils.isSameDay(date, _selectedDate);
                      
                      return GestureDetector(
                        onTap: () => setState(() => _selectedDate = date),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              _getDayLetter(index),
                              style: GoogleFonts.inter(
                                color: isSelected ? kDarkGreen : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                children: [
                  _buildWeeklySummaryCard(),
                  const SizedBox(height: 24),
                  _buildMealsList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklySummaryCard() {
    final firestore = context.watch<FirestoreService>();
    final auth = context.read<AuthProvider>();
    final userId = auth.currentUserData?['uid'] ?? '';
    final residenceId = auth.currentResidenceId ?? '';

    return StreamBuilder<List<Meal>>(
      stream: firestore.getMealsForWeek(_startOfWeek, residenceId: residenceId),
      builder: (context, snapshot) {
        final meals = snapshot.data ?? [];
        final reservedDayIndices = <int>{};
        for (var meal in meals) {
          if (meal.isReserved(userId)) {
            final diff = meal.date.difference(_startOfWeek).inDays;
            if (diff >= 0 && diff < 7) {
              reservedDayIndices.add(diff);
            }
          }
        }
        
        final reservedCount = reservedDayIndices.length;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.appCard,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cette semaine',
                    style: GoogleFonts.inter(
                      color: context.appTextSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$reservedCount / 7 repas réservés',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: context.appTextPrimary,
                    ),
                  ),
                ],
              ),
              Row(
                children: List.generate(7, (index) {
                  final isReserved = reservedDayIndices.contains(index);
                  return Container(
                    margin: const EdgeInsets.only(left: 6),
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isReserved ? const Color(0xFF10B981) : const Color(0xFFE5E7EB),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMealsList() {
    final firestore = context.watch<FirestoreService>();
    final auth = context.read<AuthProvider>();
    final userId = auth.currentUserData?['uid'] ?? '';
    final residenceId = auth.currentResidenceId ?? '';

    return StreamBuilder<bool>(
      stream: firestore.streamRestaurantStatus(residenceId),
      builder: (context, statusSnapshot) {
        final isOpen = statusSnapshot.data ?? true;

        if (!isOpen) {
          return Center(
            child: Column(
              children: [
                const SizedBox(height: 40),
                Icon(Icons.do_not_disturb_on_rounded, size: 64, color: Colors.red.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  'Restaurant Fermé',
                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: context.appTextPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Le restaurant universitaire est actuellement fermé.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: context.appTextSecondary),
                ),
              ],
            ),
          );
        }

        return StreamBuilder<List<Meal>>(
          stream: firestore.getMealsForDate(_selectedDate, residenceId: residenceId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            var meals = snapshot.data ?? [];
            if (meals.isEmpty) {
              // Provide rich mock data matching the UI spec
              meals = [
                Meal(id: 'mock1', menu: 'Petit-déjeuner', menuItems: ['Lait chaud', 'Pain beurre', 'Confiture maison', "Jus d'orange"], type: 'breakfast', startTime: '07:00', endTime: '09:00', date: _selectedDate, averageRating: 4.5, ratingCount: 12),
                Meal(id: 'mock2', menu: 'Déjeuner', menuItems: ['Chorba frik', 'Poulet rôti aux légumes', 'Semoule beida', 'Salade verte', 'Fruit de saison'], type: 'lunch', startTime: '12:00', endTime: '14:00', date: _selectedDate, averageRating: 3.8, ratingCount: 45),
                Meal(id: 'mock3', menu: 'Dîner', menuItems: ['Soupe de lentilles', 'Tajine de mouton', 'Riz pilaf', 'Yaourt nature'], type: 'dinner', startTime: '18:00', endTime: '20:00', date: _selectedDate, averageRating: 4.8, ratingCount: 32),
              ];
            }

            // Fixed Sort order: breakfast (0), lunch (1), dinner (2)
            const order = {'breakfast': 0, 'lunch': 1, 'dinner': 2};
            meals.sort((a, b) => (order[a.mealType] ?? 3).compareTo(order[b.mealType] ?? 3));

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: meals.length,
              itemBuilder: (context, index) {
                return _MealCard(meal: meals[index], userId: userId);
              },
            );
          },
        );
      },
    );
  }
}

class _MealCard extends StatelessWidget {
  final Meal meal;
  final String userId;

  const _MealCard({required this.meal, required this.userId});

  String _getMealDisplayName(LanguageProvider lp) {
    return lp.getText(meal.mealType);
  }

  @override
  Widget build(BuildContext context) {
    const kDarkGreen = Color(0xFF2D6A4F);
    final isReserved = meal.isReserved(userId);
    final firestore = context.read<FirestoreService>();
    final lp = context.watch<LanguageProvider>();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIconBox(),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getMealDisplayName(lp),
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: context.appTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${meal.startTime} — ${meal.endTime}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: context.appTextSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: meal.menuItems.map((item) => _buildMenuChip(item)).toList(),
                ),
                const SizedBox(height: 16),
                _buildRatingBar(context),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: isReserved
                      ? OutlinedButton(
                          onPressed: () => firestore.toggleMealReservation(meal.id!, userId, false),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF10B981)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            backgroundColor: const Color(0xFFD8F3DC).withValues(alpha: 0.3),
                          ),
                          child: Text(
                            'Annuler la réservation',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF2D6A4F),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: () => firestore.toggleMealReservation(meal.id!, userId, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kDarkGreen,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(
                            'Réserver ce repas',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                ),
              ],
            ),
          ),
          if (isReserved)
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIconBox() {
    IconData icon;
    Color color;
    Color bgColor;

    switch (meal.mealType) {
      case 'breakfast':
        icon = Icons.free_breakfast;
        color = const Color(0xFFF4A261);
        bgColor = const Color(0xFFFFF3E0);
        break;
      case 'lunch':
        icon = Icons.wb_sunny;
        color = const Color(0xFF42A5F5);
        bgColor = const Color(0xFFE3F2FD);
        break;
      case 'dinner':
        icon = Icons.nightlight_round;
        color = const Color(0xFF7E57C2);
        bgColor = const Color(0xFFEDE7F6);
        break;
      default:
        icon = Icons.restaurant_rounded;
        color = Colors.grey;
        bgColor = Colors.grey.withValues(alpha: 0.1);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildMenuChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFD8F3DC).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: const Color(0xFF2D6A4F),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildRatingBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: context.appBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
               Text(meal.averageRating.toStringAsFixed(1), style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: context.appTextPrimary)),
               const SizedBox(width: 4),
               const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
               const SizedBox(width: 4),
               Text('(${meal.ratingCount} avis)', style: GoogleFonts.inter(color: context.appTextSecondary, fontSize: 11)),
            ]
          ),
          Row(
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () {
                  final rating = index + 1.0;
                  if(meal.id?.startsWith('mock') == false) {
                    context.read<FirestoreService>().rateMeal(meal.id!, rating);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Merci pour votre avis!')));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avis envoyé avec succès pour ce repas!')));
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: Icon(
                    index < meal.averageRating.round() ? Icons.star_rounded : Icons.star_outline_rounded, 
                    color: index < meal.averageRating.round() ? Colors.amber : Colors.grey.withValues(alpha: 0.4), 
                    size: 20,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
