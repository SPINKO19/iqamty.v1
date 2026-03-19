import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
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
      backgroundColor: isDark ? Colors.black : const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          lp.getText('my_profile'),
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: context.appTextPrimary),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
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
                // User Header Premium
                _buildProfileHeader(context, student, displayName, isDark),
                const SizedBox(height: 12),

                // Action Items
                _buildActionItem(context, Icons.person_outline_rounded, lp.getText('personal_info'), lp.getText('personal_info_subtitle'), () {}),
                const SizedBox(height: 12),
                _buildActionItem(context, Icons.notifications_none_rounded, lp.getText('notifications'), lp.getText('alert_preferences'), () {}),
                const SizedBox(height: 12),
                _buildActionItem(context, Icons.security_rounded, lp.getText('security'), lp.getText('password_auth'), () {}),
                const SizedBox(height: 12),
                _buildActionItem(
                  context, 
                  Icons.logout_rounded, 
                  lp.getText('logout'), 
                  lp.getText('logout_subtitle'),
                  () => _showLogoutConfirmation(context),
                  isDestructive: true,
                ),
                
                const SizedBox(height: 40),

                // Card Section with Flip Animation (Now Below)
                Container(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _isShowingResidence ? lp.getText('residence_card_ar') : lp.getText('student_card_ar'),
                              style: GoogleFonts.notoKufiArabic(
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              lp.getText('press_to_flip'),
                              style: GoogleFonts.notoKufiArabic(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _toggleCard,
                        onHorizontalDragEnd: (details) {
                          if (details.primaryVelocity != null && details.primaryVelocity!.abs() > 300) {
                            _toggleCard();
                          }
                        },
                        child: AnimatedBuilder(
                          animation: _flipAnimation,
                          builder: (context, child) {
                            final angle = _flipAnimation.value * math.pi;
                            return Transform(
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.001)
                                ..rotateY(angle),
                              alignment: Alignment.center,
                              child: angle < math.pi / 2
                                  ? _buildOfficialCard(context, student, displayName, dobFormatted, true) // Front: Residence
                                  : Transform(
                                      transform: Matrix4.identity()..rotateY(math.pi),
                                      alignment: Alignment.center,
                                      child: _buildOfficialCard(context, student, displayName, dobFormatted, false), // Back: Student
                                    ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                Text(
                  'Version 1.0.42 (Stable)',
                  style: GoogleFonts.robotoMono(fontSize: 10, color: Colors.grey.withValues(alpha: 0.5)),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
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
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.primary, Color(0xFF065F46)],
                ),
              ),
              child: CircleAvatar(
                radius: 54,
                backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[200],
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
    const textDark = Color(0xFF1F2937); // Dark blue-grey for professional text
    
    return Container(
      width: double.infinity,
      height: 285,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cardBg,
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
          
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Centered Header (Official Text)
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isResidence) 
                          Image.asset('assets/images/dou_logo.png', height: 32, errorBuilder: (c, e, s) => Image.asset('assets/images/logo.png', height: 32, fit: BoxFit.contain))
                        else
                          Image.asset('assets/images/logo.png', height: 32, fit: BoxFit.contain),
                        const SizedBox(width: 8),
                        Text(
                          'الجمهورية الجزائرية الديمقراطية الشعبية',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.notoKufiArabic(fontSize: 8.5, fontWeight: FontWeight.bold, color: textDark),
                        ),
                        const SizedBox(width: 8),
                        if (isResidence) 
                          Image.asset('assets/images/dou_logo.png', height: 32, errorBuilder: (c, e, s) => Image.asset('assets/images/logo.png', height: 32, fit: BoxFit.contain))
                        else
                          Image.asset('assets/images/logo.png', height: 32, fit: BoxFit.contain),
                      ],
                    ),
                    Text(
                      'وزارة التعليم العالي والبحث العلمي',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoKufiArabic(fontSize: 7.5, color: textDark.withValues(alpha: 0.7)),
                    ),
                    Text(
                      isResidence ? 'مديرية الخدمات الجامعية بجاية القصر' : 'المدرسة العليا لعلوم وتكنولوجيا الإعلام الآلي',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoKufiArabic(fontSize: 6.5, fontWeight: FontWeight.bold, color: mainGreen),
                    ),
                  ],
                ),
                
                const SizedBox(height: 4),
                Text(
                  isResidence ? 'بطاقة الإقامة' : 'بطاقة الطالب',
                  style: GoogleFonts.notoKufiArabic(fontSize: 18, fontWeight: FontWeight.w900, color: mainGreen, letterSpacing: 0.8),
                ),
                
                const SizedBox(height: 4),
                
                // Content Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photo
                    Container(
                      width: 80,
                      height: 105,
                      decoration: BoxDecoration(
                        color: mainGreen.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: mainGreen.withValues(alpha: 0.1), width: 1),
                        image: student?.photoBase64 != null 
                            ? DecorationImage(image: MemoryImage(base64Decode(student!.photoBase64!)), fit: BoxFit.cover)
                            : (student?.photo != null ? DecorationImage(image: NetworkImage(student!.photo!), fit: BoxFit.cover) : null),
                      ),
                      child: student?.photoBase64 == null && student?.photo == null 
                          ? Icon(Icons.person, color: mainGreen.withValues(alpha: 0.2), size: 45)
                          : null,
                    ),
                    const SizedBox(width: 14),
                    // Details
                    Expanded(
                      child: Directionality(
                        textDirection: ui.TextDirection.rtl,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoLine('اللقب:', student?.nomAr ?? student?.nomFr ?? 'REKAIK', textDark),
                            _buildInfoLine('الإسم:', student?.prenomAr ?? student?.prenomFr ?? 'HOCINE', textDark),
                            _buildInfoLine('تاريخ الميلاد:', dob, textDark),
                            if (isResidence) ...[
                              _buildInfoLine('الإقامة:', student?.residence ?? 'Résidence A', textDark),
                              _buildInfoLine('الغرفة / الجناح:', '${student?.chambre ?? '214'} / ${student?.bloc ?? 'B4'}', textDark),
                            ] else ...[
                              _buildInfoLine('الميدان:', 'إعلام آلي', textDark),
                              _buildInfoLine('الفرع:', 'نظم المعلومات', textDark),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 4),
                
                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Icons.qr_code_2_rounded, size: 45, color: mainGreen.withValues(alpha: 0.8)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'السنة الجامعية: 2024/2025',
                          style: GoogleFonts.notoKufiArabic(color: textDark.withValues(alpha: 0.6), fontSize: 8.5, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'ID: ${student?.matricule ?? '202031045214'}',
                          style: GoogleFonts.robotoMono(color: mainGreen, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                      ],
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

  Widget _buildActionItem(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap, {bool isDestructive = false}) {
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
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDestructive ? const Color(0xFFEF4444).withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: isDestructive ? const Color(0xFFEF4444) : AppColors.primary, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          color: context.appTextSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: context.appTextSecondary.withValues(alpha: 0.4), size: 14),
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
