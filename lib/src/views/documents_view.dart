import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../models/types.dart';
import '../core/theme/colors.dart';

class DocumentsView extends StatelessWidget {
  const DocumentsView({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = context.watch<FirestoreService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Documents'), centerTitle: true),
      body: StreamBuilder<List<DocumentModel>>(
        stream: firestore.getDocuments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Erreur lors du chargement des documents',
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          final documents = snapshot.data ?? [];

          if (documents.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No data available',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: documents.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final doc = documents[index];
              final isPdf = doc.fileType.toLowerCase().contains('pdf');
              final icon = isPdf ? Icons.picture_as_pdf : Icons.description;
              final iconColor = isPdf ? Colors.red : Colors.blue;
              final info = '${doc.fileType.toUpperCase()} • ${doc.fileSize}';

              return _buildDocItem(
                context,
                doc.title,
                info,
                icon,
                iconColor,
                doc.fileUrl,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDocItem(
    BuildContext context,
    String title,
    String info,
    IconData icon,
    Color iconColor,
    String url,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  info,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // TODO: Implement download / open URL
            },
            icon: const Icon(Icons.download_outlined, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
