import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../core/theme/colors.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _isShowingResidence = true;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutBack),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _toggleCard() {
    if (_isShowingResidence) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
    setState(() {
      _isShowingResidence = !_isShowingResidence;
    });
  }

  @override
  Widget build(BuildContext context) {
    final student = context.watch<AuthProvider>().currentStudent;
    final lp = context.watch<LanguageProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Formatting date
    String dobFormatted = "01/01/2000";
    if (student?.dateNaissance != null) {
       try {
         DateTime parseDate = DateTime.parse(student!.dateNaissance!);
         dobFormatted = DateFormat('dd/MM/yyyy').format(parseDate);
       } catch (e) {
         dobFormatted = student!.dateNaissance!;
       }
    }

    final safeNomFr = student?.nomFr ?? '';
    final safePrenomFr = student?.prenomFr ?? '';
    final displayName = '$safeNomFr $safePrenomFr'.trim().isEmpty 
        ? lp.getText('no_name') 
        : '$safeNomFr $safePrenomFr'.trim();

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          lp.getText('my_profile'),
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: context.appTextPrimary),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
          color: context.appTextPrimary,
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              children: [
                // Header Section
                _buildProfileHeader(context, student, displayName, isDark),
                const SizedBox(height: 32),

                // Horizontal Official Card Sections (Restored from vertical)
                Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    children: [
                      _buildTitledCardSection(lp.getText('student_card_ar'), lp, student, displayName, dobFormatted, false),
                      const SizedBox(height: 12),
                      _buildTitledCardSection(lp.getText('residence_card_ar'), lp, student, displayName, dobFormatted, true),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),

                // Restored Logout Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildActionItem(
                    context, 
                    lp.getText('logout'), 
                    () => _showLogoutConfirmation(context),
                    isDestructive: true,
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitledCardSection(String title, LanguageProvider lp, dynamic student, String name, String dob, bool isResidence) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 8),
            child: Text(
              title,
              style: GoogleFonts.notoKufiArabic(
                fontWeight: FontWeight.w900,
                fontSize: 12,
                color: AppColors.primary.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
        _buildOfficialCard(context, student, name, dob, isResidence),
      ],
    );
  }

  Widget _buildProfileHeader(BuildContext context, dynamic student, String name, bool isDark) {
    final lp = context.read<LanguageProvider>();
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.primary, Color(0xFF065F46)],
                ),
              ),
              child: CircleAvatar(
                radius: 54,
                backgroundColor: context.appBackground,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: isDark ? AppColors.borderColorDark : Colors.grey[200],
                  backgroundImage: student?.photoBase64 != null 
                    ? MemoryImage(base64Decode(student!.photoBase64!))
                    : (student?.photo != null ? NetworkImage(student!.photo!) : null) as ImageProvider?,
                  child: student?.photoBase64 == null && student?.photo == null
                    ? Icon(Icons.person_rounded, size: 50, color: Colors.grey[400])
                    : null,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
            )
          ],
        ),
        const SizedBox(height: 20),
        Text(
          name,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: context.appTextPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            student?.residence?.toUpperCase() ?? lp.getText('not_assigned').toUpperCase(),
            style: GoogleFonts.inter(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOfficialCard(BuildContext context, dynamic student, String name, String dob, bool isResidence) {
    final mainGreen = AppColors.primary;
    final cardBg = Colors.white;
    const textDark = Colors.white;
    
    return Container(
      width: 340, 
      height: 600, // Optimized for mobile screen (vertical)
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.cardDark : cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: mainGreen.withValues(alpha: 0.15),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: mainGreen.withValues(alpha: 0.15), width: 1.5),
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 80,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [mainGreen.withValues(alpha: 0.1), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0.04,
              child: CustomPaint(
                painter: CardPatternPainter(mainGreen),
              ),
            ),
          ),
          
          // Decorative Security Wave (Vertical)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 40,
            child: Opacity(
              opacity: 0.1,
              child: RotatedBox(
                quarterTurns: 1,
                child: CustomPaint(painter: CardPatternPainter(mainGreen)),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                // Header: School Title
                Text(
                  'الثانوية التأهيلية الخاصة',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoKufiArabic(fontSize: 14, fontWeight: FontWeight.bold, color: textDark),
                ),
                Text(
                  'الموسم الدراسي: 2025/2026',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoKufiArabic(fontSize: 10, color: textDark.withValues(alpha: 0.7)),
                ),
                
                const SizedBox(height: 32),
                
                // Centered Photo Section
                Center(
                  child: Container(
                    width: 160,
                    height: 190,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
                      image: student?.photoBase64 != null 
                          ? DecorationImage(image: MemoryImage(base64Decode(student!.photoBase64!)), fit: BoxFit.cover)
                          : (student?.photo != null ? DecorationImage(image: NetworkImage(student!.photo!), fit: BoxFit.cover) : null),
                    ),
                    child: student?.photoBase64 == null && student?.photo == null 
                        ? Icon(Icons.person, color: Colors.white.withValues(alpha: 0.2), size: 100)
                        : null,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Centered Name (Bold)
                Text(
                  displayName,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoKufiArabic(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
                ),
                
                const SizedBox(height: 24),
                
                // Info Fields (List Layout)
                Expanded(
                  child: Directionality(
                    textDirection: ui.TextDirection.rtl,
                    child: Column(
                      children: [
                        _buildMobileInfoLine('اللقب:', safeNomFr.toUpperCase(), textDark),
                        _buildMobileInfoLine('الإسم:', safePrenomFr.toUpperCase(), textDark),
                        _buildMobileInfoLine('تاريخ الميلاد:', dob, textDark),
                        _buildMobileInfoLine('الجنس:', student?.genre == 'M' ? 'ذكر' : 'أنثى', textDark),
                        _buildMobileInfoLine('المستوى:', 'الرابعة إعدادي', textDark),
                        _buildMobileInfoLine('القسم:', 'الفوج A2', textDark),
                      ],
                    ),
                  ),
                ),
                
                // QR & ID Section
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.qr_code_2_rounded, size: 80, color: Colors.black),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'ID: ${student?.matricule ?? '2025-0001-ST'}',
                      style: GoogleFonts.robotoMono(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 2),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileInfoLine(String label, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.notoKufiArabic(color: textColor.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.bold),
          ),
          Text(
            value,
            style: GoogleFonts.notoKufiArabic(color: textColor, fontSize: 14, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
        ],
      ),
    );
  }

  Widget _buildInfoLine(String label, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: GoogleFonts.notoKufiArabic(color: textColor.withValues(alpha: 0.6), fontSize: 9.5, fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: value,
              style: GoogleFonts.notoKufiArabic(color: textColor, fontSize: 11.5, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(BuildContext context, String title, VoidCallback onTap, {bool isDestructive = false}) {
    final color = isDestructive ? const Color(0xFFEF4444) : context.appTextPrimary;
    
    return Container(
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    final lp = context.read<LanguageProvider>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(lp.getText('logout_confirm_title'), style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text(lp.getText('logout_confirm_msg'), style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lp.getText('cancel'), style: GoogleFonts.inter(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(lp.getText('logout_action'), style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class CardPatternPainter extends CustomPainter {
  final Color color;
  CardPatternPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (var i = 0; i < size.height; i += 10) {
      final path = Path();
      path.moveTo(0, i.toDouble());
      for (var x = 0; x < size.width; x += 20) {
        path.quadraticBezierTo(
          x + 10, i + (i % 20 == 0 ? 5 : -5),
          x + 20, i.toDouble(),
        );
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
