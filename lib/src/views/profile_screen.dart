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
import 'package:image_picker/image_picker.dart';
import '../services/firestore_service.dart';

import '../components/custom_menu_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _isShowingResidence = true;
  final _phoneController = TextEditingController();
  bool _isEditingPhone = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _phoneController.text = auth.currentUserData?['phoneNumber'] ?? '';
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
    _phoneController.dispose();
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
    final auth = context.watch<AuthProvider>();
    final student = auth.currentStudent;
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

    final safeNomFr = student?.nomFr ?? auth.currentUserData?['displayName']?.split(' ')?.first ?? '';
    final prenomData = auth.currentUserData?['displayName']?.split(' ');
    final safePrenomFr = student?.prenomFr ?? ((prenomData != null && prenomData.length > 1) ? prenomData.last : '');
    
    final role = auth.currentUserData?['role'] ?? 'student';
    final isWorkerOrAdmin = role == 'worker' || role == 'administrator';

    String displayName = '$safeNomFr $safePrenomFr'.trim();
    if (displayName.isEmpty) {
       displayName = auth.currentUserData?['displayName'] ?? lp.getText('no_name');
    }

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
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CustomMenuButton(
            backgroundColor: isDark 
                ? Colors.white.withValues(alpha: 0.1) 
                : AppColors.primary.withValues(alpha: 0.1),
            iconColor: isDark ? Colors.white : AppColors.primary,
          ),
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
                // Conditional Identity Section
                if (!isWorkerOrAdmin) ...[
                  // Vertical Flippable Card Section (Students only)
                  GestureDetector(
                    onTap: _toggleCard,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: AspectRatio(
                        aspectRatio: 0.63, 
                        child: RotatedBox(
                          quarterTurns: 3, 
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
                                    ? _buildOfficialCard(context, student, displayName, dobFormatted, true) 
                                    : Transform(
                                        transform: Matrix4.identity()..rotateY(math.pi),
                                        alignment: Alignment.center,
                                        child: _buildOfficialCard(context, student, displayName, dobFormatted, false), 
                                      ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    lp.getText('press_to_flip'),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary.withValues(alpha: 0.6),
                    ),
                  ),
                ] else ...[
                  // Professional Identity Pass (Workers/Admins)
                  _buildProfessionalIdentityCard(context, auth, lp, isDark),
                ],
                
                const SizedBox(height: 32),

                if (isWorkerOrAdmin) ...[
                   _buildPhoneSection(context, lp, isDark, auth),
                   const SizedBox(height: 12),
                ],

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

  Widget _buildPhoneSection(BuildContext context, LanguageProvider lp, bool isDark, AuthProvider auth) {
     return Container(
       padding: const EdgeInsets.all(20),
       decoration: BoxDecoration(
          color: context.appCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.appBorder),
       ),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Row(
             children: [
               Icon(Icons.phone_android_rounded, color: AppColors.primary, size: 20),
               const SizedBox(width: 12),
               Text('Numéro de téléphone', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
               const Spacer(),
               IconButton(
                 onPressed: () async {
                   final messenger = ScaffoldMessenger.of(context);
                   final firestoreService = context.read<FirestoreService>();
                   if (_isEditingPhone) {
                      // Save
                      await firestoreService.updateUserProfile(auth.currentUserData?['uid'] ?? '', {'phoneNumber': _phoneController.text.trim()});
                      if (!mounted) return;
                      messenger.showSnackBar(const SnackBar(content: Text('Profil mis à jour')));
                   }
                   setState(() => _isEditingPhone = !_isEditingPhone);
                 },
                 icon: Icon(_isEditingPhone ? Icons.check_circle : Icons.edit, color: AppColors.primary, size: 20),
               ),
             ],
           ),
           const SizedBox(height: 8),
           _isEditingPhone 
             ? TextField(
                 controller: _phoneController,
                 keyboardType: TextInputType.phone,
                 decoration: InputDecoration(
                   hintText: 'Entrez votre numéro',
                   filled: true,
                   fillColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                 ),
               )
             : Text(
                 _phoneController.text.isEmpty ? 'Non renseigné' : _phoneController.text,
                 style: GoogleFonts.inter(color: context.appTextSecondary, fontSize: 13),
               ),
         ],
       ),
     );
  }

  Widget _buildProfessionalIdentityCard(BuildContext context, AuthProvider auth, LanguageProvider lp, bool isDark) {
    final data = auth.currentUserData;
    final String role = (data?['role'] ?? 'worker').toString().toUpperCase();
    final String dept = data?['department'] ?? 'Général';
    final String residence = data?['residenceName'] ?? 'Non assigné';
    final String name = data?['displayName'] ?? 'Personnel';
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: context.appBorder),
        boxShadow: isDark ? null : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          // Curved Decorative Header
          Container(
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark 
                  ? [const Color(0xFF1B4332), const Color(0xFF081C15)]
                  : [AppColors.primary, const Color(0xFF064E3B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(27)),
            ),
            child: Stack(
              children: [
                const Positioned(
                  right: -20,
                  top: -20,
                  child: Opacity(
                    opacity: 0.1,
                    child: Icon(Icons.security, size: 120, color: Colors.white),
                  ),
                ),
                Center(
                  child: Text(
                    'CARTE PROFESSIONNELLE',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Identity Section
          Transform.translate(
            offset: const Offset(0, -40),
            child: Column(
              children: [
                // Premium Avatar
                _buildPremiumAvatar(context, auth, isDark),
                const SizedBox(height: 16),
                
                // Name & Badge
                Text(
                  name.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: context.appTextPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_user, size: 12, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        role,
                        style: GoogleFonts.inter(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                  child: Divider(height: 1),
                ),
                
                // Details Grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      _buildDetailRow(Icons.business_center_rounded, 'DÉPARTEMENT', dept, context),
                      const SizedBox(height: 20),
                      _buildDetailRow(Icons.domain_rounded, 'RÉSIDENCE', residence, context),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumAvatar(BuildContext context, AuthProvider auth, bool isDark) {
    final photoUrl = auth.currentUserData?['photoUrl'];
    
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.appCard,
          ),
          child: CircleAvatar(
            radius: 54,
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: isDark ? Colors.white12 : Colors.grey[100],
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null ? Icon(Icons.person, size: 40, color: Colors.grey[400]) : null,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => _updatePhoto(context, auth),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: context.appCard, width: 3),
            ),
            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
          ),
        ),
      ],
    );
  }

  Future<void> _updatePhoto(BuildContext context, AuthProvider auth) async {
    final ImagePicker picker = ImagePicker();
    final firestoreService = context.read<FirestoreService>();
    final messenger = ScaffoldMessenger.of(context);
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 400, maxHeight: 400);
    if (image != null) {
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      final base64String = base64Encode(bytes);
      await firestoreService.updateUserProfile(auth.currentUserData?['uid'] ?? '', {'photoUrl': 'data:image/png;base64,$base64String'});
      if (mounted) messenger.showSnackBar(const SnackBar(content: Text('Photo mise à jour')));
    }
  }

  Widget _buildDetailRow(IconData icon, String label, String value, BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: context.appBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: context.appTextSecondary, size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: context.appTextSecondary, letterSpacing: 1)),
              const SizedBox(height: 4),
              Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: context.appTextPrimary)),
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildOfficialCard(BuildContext context, dynamic student, String name, String dob, bool isResidence) {
    final mainGreen = AppColors.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: mainGreen.withValues(alpha: 0.4), width: 1.2),
      ),
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 500,
          height: 316, // Proportional to AspectRatio 1.58 (500 / 1.58 = 316)
          child: Stack(
            children: [
              // Header Bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 70,
                child: Container(
                  decoration: BoxDecoration(
                    color: mainGreen,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                       Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.account_balance_rounded, color: Colors.white, size: 12),
                            const SizedBox(width: 8),
                            Text(
                              'الجمهورية الجزائرية الديمقراطية الشعبية',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.notoKufiArabic(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.account_balance_rounded, color: Colors.white, size: 12),
                          ],
                        ),
                        Text(
                          'وزارة التعليم العالي والبحث العلمي',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.notoKufiArabic(fontSize: 7, color: Colors.white.withValues(alpha: 0.9)),
                        ),
                        Text(
                          isResidence ? 'مديرية الخدمات الجامعية بجاية القصر' : 'المدرسة العليا للإعلام الآلي',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.notoKufiArabic(fontSize: 7.5, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                    ],
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 78, 16, 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Text(
                          isResidence ? 'بطاقة الإقامة' : 'بطاقة الطالب',
                          style: GoogleFonts.notoKufiArabic(fontSize: 14, fontWeight: FontWeight.w900, color: mainGreen, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Photo
                            Container(
                              width: 100,
                              height: 120,
                              decoration: BoxDecoration(
                                color: mainGreen.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: mainGreen.withValues(alpha: 0.2)),
                                image: student?.photoBase64 != null 
                                    ? DecorationImage(image: MemoryImage(base64Decode(student!.photoBase64!)), fit: BoxFit.cover)
                                    : (student?.photo != null ? DecorationImage(image: NetworkImage(student!.photo!), fit: BoxFit.cover) : null),
                              ),
                              child: student?.photoBase64 == null && student?.photo == null 
                                  ? Icon(Icons.person, color: mainGreen.withValues(alpha: 0.2), size: 50)
                                  : null,
                            ),
                            const SizedBox(width: 20),
                            // Details
                            Expanded(
                              child: Directionality(
                                textDirection: ui.TextDirection.rtl,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildInfoLine('اللقب:', student?.nomAr ?? student?.nomFr ?? '', textColor),
                                    _buildInfoLine('الإسم:', student?.prenomAr ?? student?.prenomFr ?? '', textColor),
                                    _buildInfoLine('تاريخ الميلاد:', dob, textColor),
                                    if (isResidence) ...[
                                      _buildInfoLine('الإقامة:', student?.residence ?? 'Résidence universitaire', textColor),
                                      _buildInfoLine('الغرفة / الجناح:', '${student?.chambre ?? '--'} / ${student?.bloc ?? '--'}', textColor),
                                    ] else ...[
                                      _buildInfoLine('الميدان:', 'إعلام آلي', textColor),
                                      _buildInfoLine('الفرع:', 'نظم المعلومات', textColor),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(Icons.qr_code_2_rounded, size: 50, color: textColor.withValues(alpha: 0.7)),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'السنة الجامعية: 2024/2025',
                              style: GoogleFonts.notoKufiArabic(color: subTextColor, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'ID: ${student?.matricule ?? '201011123456'}',
                              style: GoogleFonts.robotoMono(color: textColor, fontSize: 13, fontWeight: FontWeight.bold),
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
        ),
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
              text: label,
              style: GoogleFonts.notoKufiArabic(fontSize: 12, color: textColor.withValues(alpha: 0.6), fontWeight: FontWeight.bold),
            ),
            const TextSpan(text: ' '),
            TextSpan(
              text: value,
              style: GoogleFonts.notoKufiArabic(fontSize: 12, color: textColor, fontWeight: FontWeight.w900),
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
