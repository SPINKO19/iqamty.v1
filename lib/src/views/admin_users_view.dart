import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../core/theme/colors.dart';
import 'package:google_fonts/google_fonts.dart';

const _kGreen = Color(0xFF2D6A4F);

class AdminUsersView extends StatelessWidget {
  const AdminUsersView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lp = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _kGreen,
        foregroundColor: Colors.white,
        title: Text(
          lp.getText('students_management'),
          style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.person_add_outlined, color: Colors.white)),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Row(
                  children: [
                    _buildSmallStat(context, lp.getText('total'), '1,240', _kGreen),
                    const SizedBox(width: 12),
                    _buildSmallStat(context, lp.getText('active'), '1,180', const Color(0xFF10B981)),
                    const SizedBox(width: 12),
                    _buildSmallStat(context, lp.getText('blocked'), '60', const Color(0xFFEF4444)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: context.appCard,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isDark ? null : [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 5)),
                    ],
                  ),
                  child: TextField(
                    style: GoogleFonts.inter(color: context.appTextPrimary, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded, color: context.appTextSecondary, size: 20),
                      hintText: lp.getText('search_student'),
                      hintStyle: GoogleFonts.inter(color: context.appTextSecondary, fontSize: 14, fontWeight: FontWeight.w500),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth > 800;
                    if (isDesktop) {
                      return GridView.count(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 3.5,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _buildModernUserCard(context, lp, 'KHOUDIR Lynda', '202433294616', 'Bloc J • Room 414', false),
                          _buildModernUserCard(context, lp, 'BOUZIDI Ahmed', '202433294001', 'Bloc A • Room 102', true),
                          _buildModernUserCard(context, lp, 'MEHDI Sofiane', '202433294123', 'Bloc B • Room 205', false),
                          _buildModernUserCard(context, lp, 'ZAHIRI Amine', '202433294888', 'Bloc C • Room 012', false),
                        ],
                      );
                    }
                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildModernUserCard(context, lp, 'KHOUDIR Lynda', '202433294616', 'Bloc J • Room 414', false),
                        const SizedBox(height: 16),
                        _buildModernUserCard(context, lp, 'BOUZIDI Ahmed', '202433294001', 'Bloc A • Room 102', true),
                        const SizedBox(height: 16),
                        _buildModernUserCard(context, lp, 'MEHDI Sofiane', '202433294123', 'Bloc B • Room 205', false),
                        const SizedBox(height: 16),
                        _buildModernUserCard(context, lp, 'ZAHIRI Amine', '202433294888', 'Bloc C • Room 012', false),
                        const SizedBox(height: 100),
                      ],
                    );
                  }
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallStat(BuildContext context, String label, String value, Color color) {
    final isDark = context.isDark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: context.appCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDark ? null : [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: color, letterSpacing: -0.5)),
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: context.appTextSecondary, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildModernUserCard(BuildContext context, LanguageProvider lp, String name, String matricule, String details, bool isBanned) {
    final isDark = context.isDark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark ? null : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isBanned ? Colors.grey.withValues(alpha: 0.1) : _kGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                name[0].toUpperCase(),
                style: GoogleFonts.inter(color: isBanned ? Colors.grey : _kGreen, fontWeight: FontWeight.w900, fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: context.appTextPrimary, fontSize: 16, letterSpacing: -0.3)),
                const SizedBox(height: 4),
                Text(details, style: GoogleFonts.inter(color: context.appTextSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('ID: $matricule', style: GoogleFonts.robotoMono(color: context.appTextSecondary.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: context.appTextSecondary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: ListTile(
                  leading: const Icon(Icons.edit_outlined, size: 20),
                  title: Text(lp.getText('edit'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                child: ListTile(
                  leading: Icon(
                    isBanned ? Icons.check_circle_outline_rounded : Icons.block_flipped,
                    color: isBanned ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  title: Text(isBanned ? lp.getText('unblock') : lp.getText('block'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
