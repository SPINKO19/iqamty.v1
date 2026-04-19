import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/language_provider.dart';
import 'package:provider/provider.dart';
import '../components/custom_menu_button.dart';

class AdminPlaceholderView extends StatelessWidget {
  final String title;
  const AdminPlaceholderView({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    const kGreen = Color(0xFF1D5C35);
    final lp = context.watch<LanguageProvider>();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: kGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.construction_rounded, size: 64, color: kGreen),
          ),
          const SizedBox(height: 24),
          Text(
            lp.getText('feature_coming_soon'),
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: kGreen,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Cette section est en cours de développement pour améliorer votre expérience administrative.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
