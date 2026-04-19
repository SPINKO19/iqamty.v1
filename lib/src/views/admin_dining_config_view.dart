import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme/colors.dart';
import '../components/custom_menu_button.dart';
import '../providers/language_provider.dart';

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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Menu du Jour', 'Configurez le menu de la cafétéria'),
          const SizedBox(height: 24),
          
          // Date Picker Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D5C35).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calendar_month_rounded, color: Color(0xFF1D5C35)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sélectionnez la date', style: GoogleFonts.inter(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(DateFormat('EEEE d MMMM yyyy', 'fr').format(_selectedDate), style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
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
                    backgroundColor: const Color(0xFF0E2318),
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
          
          _buildMealSection('Petit-déjeuner', Icons.free_breakfast_rounded, const Color(0xFFF4A261), '07:00', '09:00'),
          const SizedBox(height: 16),
          _buildMealSection('Déjeuner', Icons.wb_sunny_rounded, const Color(0xFF42A5F5), '12:00', '14:00'),
          const SizedBox(height: 16),
          _buildMealSection('Dîner', Icons.nightlight_round, const Color(0xFF7E57C2), '18:00', '20:00'),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF111827)),
        ),
        Text(
          subtitle,
          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280)),
        ),
      ],
    );
  }

  Widget _buildMealSection(String title, IconData icon, Color color, String defaultStart, String defaultEnd) {
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
                      Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18)),
                      Text('$defaultStart - $defaultEnd', style: GoogleFonts.inter(color: context.appTextSecondary, fontSize: 13)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.grey),
                  onPressed: () {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Menu édité avec succès!')));
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Aucun plat configuré pour ce repas. Cliquez sur le bouton "+" pour ajouter des éléments au menu.',
              style: GoogleFonts.inter(color: context.appTextSecondary, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }
}
