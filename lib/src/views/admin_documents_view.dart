import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../services/firestore_service.dart';
import '../providers/auth_provider.dart';
import '../models/types.dart';
import '../core/theme/colors.dart';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;

class AdminDocumentsView extends StatefulWidget {
  const AdminDocumentsView({super.key});

  @override
  State<AdminDocumentsView> createState() => _AdminDocumentsViewState();
}

class _AdminDocumentsViewState extends State<AdminDocumentsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Existing Document state
  bool _isUploading = false;
  double _uploadProgress = 0;
  String? _selectedFileName;
  PlatformFile? _pickedFile;
  String _selectedTarget = 'students';

  // Program state
  final _programTitleController = TextEditingController();
  final _programDescController = TextEditingController();
  final _programScheduleController = TextEditingController();
  String? _editingProgramId;
  bool _isProgramEditMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _programTitleController.dispose();
    _programDescController.dispose();
    _programScheduleController.dispose();
    super.dispose();
  }

  // --- Document Methods ---
  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'doc', 'png', 'jpg', 'jpeg'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _pickedFile = file;
          _selectedFileName = _pickedFile!.name;
        });
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  Future<void> _uploadDocument() async {
    if (_pickedFile == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_pickedFile!.name}';
      final storageRef = FirebaseStorage.instance.ref().child('documents/$fileName');
      
      UploadTask uploadTask;
      if (kIsWeb) {
        uploadTask = storageRef.putData(_pickedFile!.bytes!);
      } else {
        uploadTask = storageRef.putFile(File(_pickedFile!.path!));
      }

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (mounted) {
          setState(() {
            _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
          });
        }
      });

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      final firestore = context.read<FirestoreService>();
      
      await firestore.addDocument(
        title: _pickedFile!.name,
        type: _pickedFile!.extension?.toLowerCase() ?? 'unknown',
        size: _formatBytes(_pickedFile!.size),
        url: downloadUrl,
        target: _selectedTarget,
        residenceId: auth.currentResidenceId,
        contentType: 'document',
      );

      if (mounted) {
        _resetDocumentForm();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document mis en ligne avec succès'), backgroundColor: _kGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  void _resetDocumentForm() {
    setState(() {
      _pickedFile = null;
      _selectedFileName = null;
      _isUploading = false;
    });
  }

  // --- Program Methods ---
  Future<void> _saveProgram() async {
    if (_programTitleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un titre pour le programme')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final auth = context.read<AuthProvider>();
      final firestore = context.read<FirestoreService>();
      
      String? downloadUrl;
      String? fileType;
      String? fileSize;

      if (_pickedFile != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_pickedFile!.name}';
        final storageRef = FirebaseStorage.instance.ref().child('programs/$fileName');
        final uploadTask = kIsWeb ? storageRef.putData(_pickedFile!.bytes!) : storageRef.putFile(File(_pickedFile!.path!));
        
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          if (mounted) {
            setState(() {
              _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
            });
          }
        });

        final snapshot = await uploadTask;
        downloadUrl = await snapshot.ref.getDownloadURL();
        fileType = _pickedFile!.extension?.toLowerCase();
        fileSize = _formatBytes(_pickedFile!.size);
      }

      if (_isProgramEditMode && _editingProgramId != null) {
        await firestore.updateDocument(
          docId: _editingProgramId!,
          title: _programTitleController.text,
          target: _selectedTarget,
          description: _programDescController.text,
          schedule: _programScheduleController.text,
          fileUrl: downloadUrl,
          fileType: fileType,
          fileSize: fileSize,
        );
      } else {
        await firestore.addDocument(
          title: _programTitleController.text,
          type: fileType ?? '',
          size: fileSize ?? '',
          url: downloadUrl ?? '',
          target: _selectedTarget,
          residenceId: auth.currentResidenceId,
          contentType: 'program',
          description: _programDescController.text,
          schedule: _programScheduleController.text,
        );
      }

      if (mounted) {
        _resetProgramForm();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isProgramEditMode ? 'Programme mis à jour' : 'Programme créé avec succès'), backgroundColor: _kGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Action failed: $e')));
      }
    }
  }

  void _resetProgramForm() {
    setState(() {
      _programTitleController.clear();
      _programDescController.clear();
      _programScheduleController.clear();
      _pickedFile = null;
      _selectedFileName = null;
      _isProgramEditMode = false;
      _editingProgramId = null;
      _isUploading = false;
    });
  }

  void _startEditProgram(DocumentModel program) {
    setState(() {
      _isProgramEditMode = true;
      _editingProgramId = program.id;
      _programTitleController.text = program.title;
      _programDescController.text = program.description ?? '';
      _programScheduleController.text = program.schedule ?? '';
      _selectedTarget = program.target;
      _selectedFileName = program.fileUrl.isNotEmpty ? 'Fichier actuel conservé' : null;
      _tabController.animateTo(1); // Go to Programs tab
    });
  }

  String _formatBytes(int bytes, {int decimals = 1}) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (math.log(bytes) / math.log(1024)).floor();
    return '${(bytes / math.pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LanguageProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Modern Tab Bar
        Container(
          margin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          decoration: BoxDecoration(
            color: context.appCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.appBorder),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: isDark ? AppColors.primary : const Color(0xFF0E2318),
              borderRadius: BorderRadius.circular(8),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            padding: const EdgeInsets.all(4),
            labelColor: Colors.white,
            unselectedLabelColor: context.appTextSecondary,
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
            unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
            tabs: [
              Tab(text: lp.getText('documents')),
              Tab(text: lp.getText('programs')),
            ],
          ),
        ),
        
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildDocumentsTab(context, lp, isDark),
              _buildProgramsTab(context, lp, isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentsTab(BuildContext context, LanguageProvider lp, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: _buildDocumentUploadForm(lp, isDark),
              ),
              if (isWide) ...[
                const SizedBox(width: 24),
                Expanded(
                  flex: 1,
                  child: _buildHistoryList(lp, 'document'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildProgramsTab(BuildContext context, LanguageProvider lp, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: _buildProgramForm(lp, isDark),
              ),
              if (isWide) ...[
                const SizedBox(width: 24),
                Expanded(
                  flex: 1,
                  child: _buildHistoryList(lp, 'program'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildDocumentUploadForm(LanguageProvider lp, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(lp.getText('new_document'), 'Partagez des ressources ou formulaires.'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: context.appCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.appBorder),
          ),
          child: Column(
            children: [
              if (_selectedFileName == null) _buildPickArea(context, lp) else _buildSelectedFileArea(context),
              const SizedBox(height: 20),
              _buildTargetSelection(lp),
              if (_isUploading) _buildUploadProgress(),
              const SizedBox(height: 24),
              _buildSubmitButton(
                onPressed: (_pickedFile == null || _isUploading) ? null : _uploadDocument,
                text: lp.getText('confirm_send'),
                isDark: isDark,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (MediaQuery.of(context).size.width <= 900) _buildHistoryList(lp, 'document'),
      ],
    );
  }

  Widget _buildProgramForm(LanguageProvider lp, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          _isProgramEditMode ? lp.getText('edit_program') : lp.getText('new_program'),
          'Créez un programme structuré avec description et emploi du temps.'
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: context.appCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.appBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(_programTitleController, lp.getText('program_title'), Icons.title),
              const SizedBox(height: 16),
              _buildTextField(_programDescController, lp.getText('program_description'), Icons.description, maxLines: 3),
              const SizedBox(height: 16),
              _buildTextField(_programScheduleController, lp.getText('program_schedule'), Icons.calendar_today),
              const SizedBox(height: 20),
              Text(lp.getText('program_file_optional'), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              if (_selectedFileName == null) _buildPickArea(context, lp) else _buildSelectedFileArea(context),
              const SizedBox(height: 20),
              _buildTargetSelection(lp),
              if (_isUploading) ...[
                const SizedBox(height: 16),
                _buildUploadProgress(),
              ],
              const SizedBox(height: 24),
              _buildSubmitButton(
                onPressed: (_programTitleController.text.isEmpty || _isUploading) ? null : _saveProgram,
                text: _isProgramEditMode ? lp.getText('edit_program') : lp.getText('send_program'),
                isDark: isDark,
              ),
              if (_isProgramEditMode) ...[
                const SizedBox(height: 8),
                TextButton(onPressed: _resetProgramForm, child: const Center(child: Text('Annuler l\'édition', style: TextStyle(color: Colors.red)))),
              ]
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (MediaQuery.of(context).size.width <= 900) _buildHistoryList(lp, 'program'),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildTargetSelection(LanguageProvider lp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Destinataires', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildTargetOption(title: 'Étudiants', value: 'students', icon: Icons.school_rounded)),
            const SizedBox(width: 12),
            Expanded(child: _buildTargetOption(title: 'Travailleurs', value: 'workers', icon: Icons.engineering_rounded)),
          ],
        ),
      ],
    );
  }

  Widget _buildUploadProgress() {
    return Column(
      children: [
        const SizedBox(height: 24),
        LinearProgressIndicator(value: _uploadProgress, backgroundColor: context.appBorder, color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
        Text('${(_uploadProgress * 100).toInt()}% uploaded', style: GoogleFonts.inter(fontSize: 12, color: context.appTextSecondary)),
      ],
    );
  }

  Widget _buildSubmitButton({required VoidCallback? onPressed, required String text, required bool isDark}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? AppColors.primary : const Color(0xFF0E2318),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: _isUploading 
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Text(text, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildHistoryList(LanguageProvider lp, String contentType) {
    final firestore = context.read<FirestoreService>();
    final residenceId = context.read<AuthProvider>().currentResidenceId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          contentType == 'document' ? lp.getText('recent_uploads') : lp.getText('programs'),
          'Historique des éléments partagés.'
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<DocumentModel>>(
          stream: firestore.getDocuments(residenceId: residenceId, contentType: contentType),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final items = snapshot.data ?? [];
            if (items.isEmpty) return Text('Aucun élément trouvé.', style: GoogleFonts.inter(color: context.appTextSecondary, fontSize: 13));

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.appCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.appBorder),
                  ),
                  child: Row(
                    children: [
                      contentType == 'document' ? _getIconForType(item.fileType) : const Icon(Icons.event_note_rounded, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1),
                            if (contentType == 'program' && item.schedule != null)
                              Text(item.schedule!, style: TextStyle(fontSize: 11, color: context.appTextSecondary)),
                            if (contentType == 'document')
                              Text(item.fileSize, style: TextStyle(fontSize: 11, color: context.appTextSecondary)),
                          ],
                        ),
                      ),
                      if (contentType == 'program')
                        IconButton(
                          onPressed: () => _startEditProgram(item),
                          icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                        ),
                      IconButton(
                        onPressed: item.id != null ? () => _deleteDocument(context, item.id!, item.fileUrl) : null,
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: context.appTextPrimary)),
        Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: context.appTextSecondary)),
      ],
    );
  }

  Widget _buildPickArea(BuildContext context, LanguageProvider lp) {
    return InkWell(
      onTap: _pickFile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 30),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.primary.withValues(alpha: 0.05),
        ),
        child: Column(
          children: [
            Icon(Icons.cloud_upload_outlined, size: 40, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(lp.getText('tap_select_file'), style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.primary)),
            Text('PDF, DOCX, Images...', style: GoogleFonts.inter(fontSize: 11, color: context.appTextSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedFileArea(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(Icons.description_rounded, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(child: Text(_selectedFileName!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
          IconButton(onPressed: () => setState(() { _pickedFile = null; _selectedFileName = null; }), icon: const Icon(Icons.close_rounded, color: Colors.red, size: 20)),
        ],
      ),
    );
  }

  static const _kGreen = Color(0xFF1D5C35);

  Widget _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'pdf': return const Icon(Icons.picture_as_pdf_rounded, color: Colors.red);
      case 'docx':
      case 'doc': return const Icon(Icons.description_rounded, color: Colors.blue);
      case 'jpg':
      case 'jpeg':
      case 'png': return const Icon(Icons.image_rounded, color: Colors.green);
      default: return const Icon(Icons.insert_drive_file_rounded, color: Colors.grey);
    }
  }

  Future<void> _deleteDocument(BuildContext context, String docId, String url) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final firestore = context.read<FirestoreService>();
      await firestore.deleteDocument(docId);
      if (url.isNotEmpty) {
        await FirebaseStorage.instance.refFromURL(url).delete();
      }
      if (mounted) {
        messenger.showSnackBar(const SnackBar(content: Text('Supprimé avec succès')));
      }
    } catch (e) {
      debugPrint('Delete error: $e');
    }
  }

  Widget _buildTargetOption({required String title, required String value, required IconData icon}) {
    bool isSelected = _selectedTarget == value;
    return InkWell(
      onTap: () => setState(() => _selectedTarget = value),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0E2318) : context.appCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFF0E2318) : context.appBorder, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : const Color(0xFF6B7280), size: 20),
            const SizedBox(height: 4),
            Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? Colors.white : const Color(0xFF374151))),
          ],
        ),
      ),
    );
  }
}

