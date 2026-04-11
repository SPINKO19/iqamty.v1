import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../components/custom_menu_button.dart';
import '../providers/language_provider.dart';
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

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
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

      // Save metadata to Firestore
      await FirebaseFirestore.instance.collection('documents').add({
        'title': _pickedFile!.name,
        'type': _pickedFile!.extension?.toLowerCase() ?? 'unknown',
        'size': _formatBytes(_pickedFile!.size),
        'url': downloadUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'target': 'students',
      });

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
    return ((bytes / math.pow(1024, i)).toStringAsFixed(decimals)) + ' ' + suffixes[i];
  }

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LanguageProvider>();
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: Text(lp.getText('documents'), style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CustomMenuButton(
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            iconColor: AppColors.primary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload New Document',
              style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: context.appTextPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Share resources, forms, or guides with students.',
              style: GoogleFonts.inter(color: context.appTextSecondary),
            ),
            const SizedBox(height: 32),
            
            // Upload Tool
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.appCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: context.appBorder),
              ),
              child: Column(
                children: [
                  if (_selectedFileName == null)
                    _buildPickArea(context)
                  else
                    _buildSelectedFileArea(context),
                  
                  if (_isUploading) ...[
                    const SizedBox(height: 24),
                    LinearProgressIndicator(
                      value: _uploadProgress,
                      backgroundColor: context.appBorder,
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    const SizedBox(height: 8),
                    Text('${(_uploadProgress * 100).toInt()}% uploaded', style: GoogleFonts.inter(fontSize: 12)),
                  ],
                  
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: (_pickedFile == null || _isUploading) ? null : _uploadDocument,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _isUploading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Confirm Upload', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 48),
            Text(
              'Recent Uploads',
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: context.appTextPrimary),
            ),
            const SizedBox(height: 16),
            _buildRecentUploadsList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPickArea(BuildContext context) {
    return InkWell(
      onTap: _pickFile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary.withOpacity(0.3), style: BorderStyle.none), // simplified
          borderRadius: BorderRadius.circular(16),
          color: AppColors.primary.withOpacity(0.05),
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
        color: AppColors.primary.withOpacity(0.05),
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
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('documents').orderBy('createdAt', descending: true).limit(5).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Text('No recent uploads found.');

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
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
                  _getIconForType(data['type']),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1),
                        Text(data['size'] ?? '', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _deleteDocument(doc.id, data['url']),
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

  Future<void> _deleteDocument(String docId, String url) async {
    try {
      await FirebaseFirestore.instance.collection('documents').doc(docId).delete();
      await FirebaseStorage.instance.refFromURL(url).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document deleted')));
      }
    } catch (e) {
      debugPrint('Delete error: $e');
    }
  }
}
