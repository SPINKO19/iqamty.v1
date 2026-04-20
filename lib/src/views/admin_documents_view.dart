import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../components/custom_menu_button.dart';
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

class _AdminDocumentsViewState extends State<AdminDocumentsView> {
  bool _isUploading = false;
  double _uploadProgress = 0;
  String? _selectedFileName;
  PlatformFile? _pickedFile;
  String _selectedTarget = 'students'; // 'students' or 'workers'

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'doc', 'png', 'jpg', 'jpeg'],
      );

      if (result != null) {
        setState(() {
          _pickedFile = result.files.first;
          _selectedFileName = _pickedFile!.name;
        });
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
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

      // Save metadata to Firestore using service
      final auth = context.read<AuthProvider>();
      final firestore = context.read<FirestoreService>();
      await firestore.addDocument(
        title: _pickedFile!.name,
        type: _pickedFile!.extension?.toLowerCase() ?? 'unknown',
        size: _formatBytes(_pickedFile!.size),
        url: downloadUrl,
        target: _selectedTarget,
        residenceId: auth.currentResidenceId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document uploaded successfully')),
        );
        setState(() {
          _pickedFile = null;
          _selectedFileName = null;
          _isUploading = false;
        });
      }
    } catch (e) {
      debugPrint('Error uploading: $e');
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Upload Section
                  Expanded(
                    flex: isWide ? 1 : 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader('Nouveau Document', 'Partagez des ressources, formulaires ou guides.'),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Column(
                            children: [
                              if (_selectedFileName == null)
                                _buildPickArea(context)
                              else
                                _buildSelectedFileArea(context),
                              
                              const SizedBox(height: 20),
                              
                              // Target Selection
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Destinataires',
                                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF374151)),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildTargetOption(
                                          title: 'Étudiants',
                                          value: 'students',
                                          icon: Icons.school_rounded,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildTargetOption(
                                          title: 'Travailleurs',
                                          value: 'workers',
                                          icon: Icons.engineering_rounded,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              
                              if (_isUploading) ...[
                                const SizedBox(height: 24),
                                LinearProgressIndicator(
                                  value: _uploadProgress,
                                  backgroundColor: const Color(0xFFE5E7EB),
                                  color: const Color(0xFF1D5C35),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                const SizedBox(height: 8),
                                Text('${(_uploadProgress * 100).toInt()}% uploaded', style: GoogleFonts.inter(fontSize: 12)),
                              ],
                              
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: (_pickedFile == null || _isUploading) ? null : _uploadDocument,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0E2318),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    elevation: 0,
                                  ),
                                  child: _isUploading 
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Text('Confirmer l\'envoi', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  if (isWide) const SizedBox(width: 24),

                  // History Section
                  if (isWide)
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('Uploads Récents', 'Historique des documents partagés.'),
                          const SizedBox(height: 16),
                          _buildRecentUploadsList(context),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
          
          // Show history below on mobile
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth <= 900) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),
                    _buildSectionHeader('Uploads Récents', 'Historique des documents partagés.'),
                    const SizedBox(height: 16),
                    _buildRecentUploadsList(context),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF111827)),
        ),
        Text(
          subtitle,
          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280)),
        ),
      ],
    );
  }

  Widget _buildPickArea(BuildContext context) {
    return InkWell(
      onTap: _pickFile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), style: BorderStyle.none), // simplified
          borderRadius: BorderRadius.circular(16),
          color: AppColors.primary.withValues(alpha: 0.05),
        ),
        child: Column(
          children: [
            const Icon(Icons.cloud_upload_outlined, size: 48, color: Color(0xFF2D6A4F)),
            const SizedBox(height: 12),
            Text('Tap to select a file', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.primary)),
            Text('PDF, DOCX, Images...', style: GoogleFonts.inter(fontSize: 12, color: context.appTextSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedFileArea(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.description_rounded, color: Color(0xFF2D6A4F), size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_selectedFileName!, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('${(_pickedFile!.size / 1024).toStringAsFixed(1)} KB', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() { _pickedFile = null; _selectedFileName = null; }),
            icon: const Icon(Icons.close_rounded, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentUploadsList(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final firestore = context.read<FirestoreService>();
    final residenceId = auth.currentResidenceId;

    return StreamBuilder<List<DocumentModel>>(
      stream: firestore.getDocuments(residenceId: residenceId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final docs = snapshot.data ?? [];
        if (docs.isEmpty) return const Text('No recent uploads found.');

        return Column(
          children: docs.take(5).map((doc) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.appCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.appBorder),
              ),
              child: Row(
                children: [
                  _getIconForType(doc.fileType),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(doc.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1),
                        Text(doc.fileSize, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: doc.id != null ? () => _deleteDocument(context, doc.id!, doc.fileUrl) : null,
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

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
    try {
      final firestore = context.read<FirestoreService>();
      await firestore.deleteDocument(docId);
      await FirebaseStorage.instance.refFromURL(url).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document deleted')));
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
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0E2318) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0E2318) : const Color(0xFFE5E7EB),
            width: 2,
          ),
          boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF0E2318).withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))] : [],
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : const Color(0xFF6B7280), size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
