import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/language_provider.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../models/types.dart';

class TypeProgramsList extends StatefulWidget {
  final String programType;

  const TypeProgramsList({super.key, required this.programType});

  @override
  State<TypeProgramsList> createState() => _TypeProgramsListState();
}

class _TypeProgramsListState extends State<TypeProgramsList> {
  Stream<List<DocumentModel>>? _stream;

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      final target = auth.currentUserData?['role'] == 'worker' ? 'workers' : 'students';
      final residenceId = auth.currentResidenceId;
      setState(() {
        _stream = context.read<FirestoreService>().getDocuments(
          residenceId: residenceId,
          target: target,
          contentType: 'program',
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LanguageProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_stream == null) return const SizedBox();

    return StreamBuilder<List<DocumentModel>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.hasError) return const SizedBox();

        final items = snapshot.data!.where((p) => p.title == widget.programType).toList();
        if (items.isEmpty) return const SizedBox();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.event_note_rounded, color: Theme.of(context).primaryColor, size: 24),
                const SizedBox(width: 16),
                Text(lp.getText('programs'), style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: Theme.of(context).textTheme.bodyLarge?.color)),
              ],
            ),
            const SizedBox(height: 16),
            ...items.map((item) => _buildProgramCard(context, item, lp, isDark)).toList(),
          ],
        );
      },
    );
  }

  Widget _buildProgramCard(BuildContext context, DocumentModel program, LanguageProvider lp, bool isDark) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryColor = Theme.of(context).textTheme.bodyMedium?.color;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? Colors.white12 : Colors.black12;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
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
                    Text(
                      lp.getText(program.title), 
                      style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: textColor)
                    ),
                    if (program.schedule != null && program.schedule!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(program.schedule!, style: GoogleFonts.inter(color: secondaryColor, fontSize: 12, fontWeight: FontWeight.w500)),
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
            Text(program.description!, style: GoogleFonts.inter(color: textColor?.withValues(alpha: 0.8), fontSize: 13, height: 1.5)),
          ],
          if (program.fileUrl.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
                    child: Row(
                      children: [
                        Icon(_getSmallIconForType(program.fileType), size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(lp.getText('program_file_optional'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 8),
                        Text(program.fileSize, style: TextStyle(fontSize: 10, color: secondaryColor)),
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
        minimumSize: const Size(60, 36),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(lp.getText('open'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
    );
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
