import 'package:flutter/material.dart';
import '../core/theme/colors.dart';

class RequestsView extends StatelessWidget {
  const RequestsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: Text('Demandes', style: TextStyle(color: context.appTextPrimary)),
        backgroundColor: context.appCard,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildRequestType(context, 'Réparation', Icons.build_outlined, 'Plomberie, Électricité, Menuiserie'),
          const SizedBox(height: 16),
          _buildRequestType(context, 'Nettoyage', Icons.cleaning_services_outlined, 'Chambre, Couloir, Bloc'),
          const SizedBox(height: 16),
          _buildRequestType(context, 'Hébergement', Icons.hotel_outlined, 'Changement de chambre, Clés'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        label: const Text('Nouvelle Demande'),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildRequestType(BuildContext context, String title, IconData icon, String subtitle) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.appCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.appBorder),
        ),
        child: Row(
          children: [
            Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.appTextPrimary)),
                  Text(subtitle, style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: context.appTextSecondary),
          ],
        ),
      ),
    );
  }
}
