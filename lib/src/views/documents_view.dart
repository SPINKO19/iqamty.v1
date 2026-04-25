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

class DocumentsView extends StatelessWidget {
  const DocumentsView({super.key});

  Future<void> _openDocument(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      debugPrint('Error opening document: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LanguageProvider>();

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
          lp.getText('documents'),
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<List<DocumentModel>>(
        stream: context.read<FirestoreService>().getDocuments(
          residenceId: context.watch<AuthProvider>().currentResidenceId,
          target: context.watch<AuthProvider>().currentUserData?['role'] == 'worker' ? 'workers' : 'students',
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF2D6A4F)));
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                '${lp.getText('error_loading')}: ${snapshot.error}',
                style: GoogleFonts.inter(color: Colors.red, fontSize: 13),
              ),
            );
          }

          final docs = snapshot.data ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open_outlined, size: 60, color: context.appTextSecondary.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text(
                    lp.getText('no_documents_msg') == 'no_documents_msg' ? 'Aucun document disponible' : lp.getText('no_documents_msg'),
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: context.appTextSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              return _buildDocCard(context, doc, lp);
            },
          );
        },
      ),
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
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
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
                Text(
                  doc.title,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${type.toUpperCase()} • ${doc.fileSize}',
                  style: GoogleFonts.inter(
                    color: context.appTextSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _openDocument(doc.fileUrl),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D6A4F).withValues(alpha: 0.1),
              foregroundColor: const Color(0xFF2D6A4F),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.open_in_new_rounded, size: 14),
                const SizedBox(width: 6),
                Text(lp.getText('open') == 'open' ? 'Ouvrir' : lp.getText('open'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
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
}
