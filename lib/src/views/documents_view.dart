import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../components/custom_menu_button.dart';
import '../providers/language_provider.dart';
import '../core/theme/colors.dart';
import '../services/firestore_service.dart';
import '../providers/auth_provider.dart';
import '../models/types.dart';

class DocumentsView extends StatefulWidget {
  final int initialTab;
  const DocumentsView({super.key, this.initialTab = 0});

  @override
  State<DocumentsView> createState() => _DocumentsViewState();
}

class _DocumentsViewState extends State<DocumentsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openDocument(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error opening document: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LanguageProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D6A4F),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CustomMenuButton(
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            iconColor: Colors.white,
          ),
        ),
        title: Text(
          lp.getText('documents_and_programs'),
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: lp.getText('documents')),
            Tab(text: lp.getText('programs')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildContentList(context, 'document', lp),
          _buildContentList(context, 'program', lp),
        ],
      ),
    );
  }

  Widget _buildContentList(BuildContext context, String contentType, LanguageProvider lp) {
    final auth = context.watch<AuthProvider>();
    final target = auth.currentUserData?['role'] == 'worker' ? 'workers' : 'students';
    final residenceId = auth.currentResidenceId;

    return StreamBuilder<List<DocumentModel>>(
      stream: context.read<FirestoreService>().getDocuments(
        residenceId: residenceId,
        target: target,
        contentType: contentType,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF2D6A4F)));
        }

        if (snapshot.hasError) {
          debugPrint('Documents stream error: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded, size: 48, color: context.appTextSecondary.withValues(alpha: 0.4)),
                const SizedBox(height: 12),
                Text(
                  lp.getText('no_documents_msg'),
                  style: GoogleFonts.inter(fontSize: 14, color: context.appTextSecondary),
                ),
              ],
            ),
          );
        }

        final items = snapshot.data ?? [];

        return ListView(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          children: [
            if (contentType == 'program') ...[
              _buildStaticMenuCard(
                context, 
                lp.getText('gym_schedule'), 
                lp.getText('gym'), 
                Icons.sports_basketball_rounded, 
                const Color(0xFF3B82F6),
                () => context.push('/gym'),
              ),
              const SizedBox(height: 16),
              _buildStaticMenuCard(
                context, 
                lp.getText('weightlifting_schedule'), 
                lp.getText('weightlifting_room'), 
                Icons.fitness_center_rounded, 
                const Color(0xFF10B981),
                () => context.push('/weightlifting'),
              ),
              const SizedBox(height: 16),
              _buildStaticMenuCard(
                context, 
                lp.getText('hamam_schedule'), 
                lp.getText('showers'), 
                Icons.shower_rounded, 
                const Color(0xFFF59E0B),
                () => context.push('/hamam'),
              ),
              if (items.isNotEmpty) const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Divider(),
              ),
            ],
            
            if (items.isEmpty && contentType == 'document')
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 100),
                    Icon(
                      Icons.folder_open_outlined,
                      size: 60,
                      color: context.appTextSecondary.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      lp.getText('no_documents_msg'),
                      style: GoogleFonts.inter(fontSize: 15, color: context.appTextSecondary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            
            if (contentType == 'document')
              ...items.map((item) => _buildDocCard(context, item, lp)).toList(),
          ],
        );
      },
    );
  }

  Widget _buildDocCard(BuildContext context, DocumentModel doc, LanguageProvider lp) {
    final String type = doc.fileType.toLowerCase();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          _getIconForType(type),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc.title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('${type.toUpperCase()} • ${doc.fileSize}', style: GoogleFonts.inter(color: context.appTextSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          _buildOpenButton(doc.fileUrl, lp),
        ],
      ),
    );
  }

  Widget _buildStaticMenuCard(BuildContext context, String title, String subtitle, IconData icon, Color iconBg, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.appBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconBg.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: iconBg, size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: context.appTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: context.appTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: context.appTextSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOpenButton(String url, LanguageProvider lp) {
    return ElevatedButton(
      onPressed: () => _openDocument(url),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2D6A4F).withValues(alpha: 0.1),
        foregroundColor: const Color(0xFF2D6A4F),
        elevation: 0,
        minimumSize: const Size(60, 36),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(lp.getText('open'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _getIconForType(String type) {
    switch (type) {
      case 'pdf': return const Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 36);
      case 'docx':
      case 'doc': return const Icon(Icons.description_rounded, color: Colors.blue, size: 36);
      case 'jpg':
      case 'jpeg':
      case 'png': return const Icon(Icons.image_rounded, color: Colors.green, size: 36);
      default: return const Icon(Icons.insert_drive_file_rounded, color: Colors.grey, size: 36);
    }
  }

  IconData _getSmallIconForType(String type) {
    switch (type) {
      case 'pdf': return Icons.picture_as_pdf_rounded;
      case 'docx':
      case 'doc': return Icons.description_rounded;
      case 'jpg':
      case 'jpeg':
      case 'png': return Icons.image_rounded;
      default: return Icons.insert_drive_file_rounded;
    }
  }
}

