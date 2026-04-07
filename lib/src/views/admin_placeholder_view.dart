import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/language_provider.dart';
import 'package:provider/provider.dart';

class AdminPlaceholderView extends StatelessWidget {
  final String title;
  const AdminPlaceholderView({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    const kGreen = Color(0xFF2D6A4F);
    final lp = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF0F172A) 
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: kGreen,
        foregroundColor: Colors.white,
        title: Text(
          title,
          style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: kGreen.withValues(alpha: 0.1),
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
      ),
    );
  }
}
