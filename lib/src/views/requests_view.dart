import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/language_provider.dart';
import '../core/theme/colors.dart';

class RequestsView extends StatelessWidget {
  const RequestsView({super.key});

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LanguageProvider>();
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: Text(lp.getText('my_requests'), style: TextStyle(color: context.appTextPrimary)),
        backgroundColor: context.appCard,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.appTextPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildRequestType(context, lp.getText('repair'), Icons.build_outlined, lp.getText('repair_subtitle'), 'repair'),
          const SizedBox(height: 16),
          _buildRequestType(context, lp.getText('cleaning'), Icons.cleaning_services_outlined, lp.getText('cleaning_subtitle'), 'cleaning'),
          const SizedBox(height: 16),
          _buildRequestType(context, lp.getText('housing'), Icons.hotel_outlined, lp.getText('housing_subtitle'), 'housing'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create-request'),
        label: Text(lp.getText('new_request')),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildRequestType(BuildContext context, String title, IconData icon, String subtitle, String category) {
    return InkWell(
      onTap: () => context.push('/request-list/$category'),
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
