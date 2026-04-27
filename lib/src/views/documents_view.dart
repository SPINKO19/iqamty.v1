import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../components/custom_menu_button.dart';
import '../providers/language_provider.dart';
import '../core/theme/colors.dart';
import '../services/firestore_service.dart';
import '../providers/auth_provider.dart';
import '../models/types.dart';

class DocumentsView extends StatefulWidget {
  const DocumentsView({super.key});

  @override
  State<DocumentsView> createState() => _DocumentsViewState();
}

class _DocumentsViewState extends State<DocumentsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF2D6A4F)));
        }

        final items = snapshot.data ?? [];

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  contentType == 'document' ? Icons.folder_open_outlined : Icons.event_busy_outlined,
                  size: 60,
                  color: context.appTextSecondary.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  contentType == 'document' ? lp.getText('no_documents_msg') : 'Aucun programme disponible',
                  style: GoogleFonts.inter(fontSize: 15, color: context.appTextSecondary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return contentType == 'document' 
              ? _buildDocCard(context, item, lp)
              : _buildProgramCard(context, item, lp);
          },
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

  Widget _buildProgramCard(BuildContext context, DocumentModel program, LanguageProvider lp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.appBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.event_note_rounded, color: Colors.orange, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(program.title, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: context.appTextPrimary)),
                    if (program.schedule != null && program.schedule!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(program.schedule!, style: GoogleFonts.inter(color: context.appTextSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (program.description != null && program.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(program.description!, style: GoogleFonts.inter(color: context.appTextPrimary.withValues(alpha: 0.8), fontSize: 13, height: 1.5)),
          ],
          if (program.fileUrl.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: context.appBackground, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.appBorder)),
                    child: Row(
                      children: [
                        Icon(_getSmallIconForType(program.fileType), size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(program.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 8),
                        Text(program.fileSize, style: TextStyle(fontSize: 10, color: context.appTextSecondary)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _buildOpenButton(program.fileUrl, lp),
              ],
            ),
          ],
        ],
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

