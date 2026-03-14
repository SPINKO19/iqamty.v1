import 'package:flutter/material.dart';
import '../core/theme/colors.dart';

class DocumentsView extends StatelessWidget {
  const DocumentsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: Text('Documents', style: TextStyle(color: context.appTextPrimary)),
        backgroundColor: context.appCard,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildDocItem(context, 'Certificat d\'hébergement', 'PDF • 1.2 MB', Icons.picture_as_pdf, Colors.red),
          const SizedBox(height: 16),
          _buildDocItem(context, 'Règlement intérieur', 'PDF • 3.5 MB', Icons.picture_as_pdf, Colors.red),
          const SizedBox(height: 16),
          _buildDocItem(context, 'Formulaire de départ', 'DOCX • 500 KB', Icons.description, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildDocItem(BuildContext context, String title, String info, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: context.appTextPrimary)),
                Text(info, style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.download_outlined, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
