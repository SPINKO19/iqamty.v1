import 'package:flutter/material.dart';
import '../components/custom_menu_button.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../services/firestore_service.dart';
import '../core/theme/colors.dart';
import '../providers/auth_provider.dart';
import 'package:google_fonts/google_fonts.dart';

const _kGreen = Color(0xFF2D6A4F);

class AdminUsersView extends StatefulWidget {
  const AdminUsersView({super.key});

  @override
  State<AdminUsersView> createState() => _AdminUsersViewState();
}

class _AdminUsersViewState extends State<AdminUsersView> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lp = context.watch<LanguageProvider>();
    final auth = context.watch<AuthProvider>();
    final firestore = context.read<FirestoreService>();
    final residenceId = auth.currentResidenceId;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: firestore.getStudents(residenceId: residenceId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _kGreen));
          }

          final allStudents = snapshot.data ?? [];
          final filteredStudents = allStudents.where((s) {
            final name = (s['displayName'] ?? '').toString().toLowerCase();
            final matricule = (s['matricule'] ?? s['uid'] ?? '').toString().toLowerCase();
            final query = _searchQuery.toLowerCase();
            return name.contains(query) || matricule.contains(query);
          }).toList();

          final total = allStudents.length;
          final blocked = allStudents.where((s) => s['isBanned'] == true).length;
          final active = total - blocked;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Row
              Row(
                children: [
                  _buildSmallStat(context, lp.getText('total'), total.toString(), _kGreen),
                  const SizedBox(width: 12),
                  _buildSmallStat(context, lp.getText('active'), active.toString(), const Color(0xFF10B981)),
                  const SizedBox(width: 12),
                  _buildSmallStat(context, lp.getText('blocked'), blocked.toString(), const Color(0xFFEF4444)),
                ],
              ),
              const SizedBox(height: 24),

              // Search & Actions Row
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 600;
                  return Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: context.appCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: context.appBorder),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) => setState(() => _searchQuery = val),
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.search_rounded, color: context.appTextSecondary, size: 18),
                              hintText: lp.getText('search_student'),
                              hintStyle: GoogleFonts.inter(color: context.appTextSecondary, fontSize: 13),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Students Grid/List
              LayoutBuilder(
                builder: (context, constraints) {
                  if (filteredStudents.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Text(
                          _searchQuery.isEmpty ? "Aucun étudiant enregistré" : "Aucun résultat trouvé",
                          style: GoogleFonts.inter(color: context.appTextSecondary),
                        ),
                      ),
                    );
                  }

                  final cardsPerRow = constraints.maxWidth > 800 ? 2 : 1;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cardsPerRow,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      mainAxisExtent: 110,
                    ),
                    itemCount: filteredStudents.length,
                    itemBuilder: (context, index) => _buildModernUserCard(
                      context, 
                      lp, 
                      filteredStudents[index],
                      firestore,
                      residenceId,
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderAction({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: context.appCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.appBorder),
        ),
        child: Icon(icon, size: 20, color: context.appTextPrimary),
      ),
    );
  }

  Future<void> _handleSeedAccounts(BuildContext context, FirestoreService firestore, String? residenceId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Initialiser les comptes ?'),
        content: const Text('Cela créera 2 administrateurs et 10 ouvriers avec des identifiants par défaut.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmer')),
        ],
      ),
    );
    if (confirm == true) {
      await firestore.seedInitialAccounts(residenceId: residenceId);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comptes créés avec succès !')));
    }
  }

  Widget _buildSmallStat(BuildContext context, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.appCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.appBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: context.appTextSecondary)),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildModernUserCard(BuildContext context, LanguageProvider lp, Map<String, dynamic> student, FirestoreService firestore, String? residenceId) {
    final name = student['displayName'] ?? 'Étudiant';
    final matricule = student['matricule'] ?? student['uid'] ?? '---';
    final residence = student['residence'] ?? '---';
    final bloc = student['bloc'] ?? '---';
    final room = student['room'] ?? student['chambre'] ?? '---';
    final isBanned = student['isBanned'] == true;
    final userId = student['id'] ?? student['uid'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isBanned ? Colors.grey.withOpacity(0.1) : const Color(0xFF1D5C35).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                name[0].toUpperCase(),
                style: GoogleFonts.inter(color: isBanned ? context.appTextSecondary : const Color(0xFF1D5C35), fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: context.appTextPrimary)),
                const SizedBox(height: 4),
                Text('$residence • Bloc $bloc • Ch $room', style: GoogleFonts.inter(color: context.appTextSecondary, fontSize: 11)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: context.appTextSecondary, size: 20),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (val) async {
              if (val == 'ban') {
                await firestore.toggleUserBan(userId, !isBanned);
              } else if (val == 'chat') {
                final chatId = await firestore.startOrGetChat(userId, name, residenceId: residenceId);
                if (context.mounted) {
                  context.go('/admin/chat/$chatId', extra: {'name': name, 'isAdmin': true});
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'chat',
                child: Row(
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, size: 18, color: context.appTextSecondary),
                    const SizedBox(width: 10),
                    Text(lp.getText('messaging'), style: TextStyle(fontSize: 13, color: context.appTextPrimary)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18, color: context.appTextSecondary),
                    const SizedBox(width: 10),
                    Text(lp.getText('edit'), style: TextStyle(fontSize: 13, color: context.appTextPrimary)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'ban',
                child: Row(
                  children: [
                    Icon(
                      isBanned ? Icons.check_circle_outline_rounded : Icons.block_flipped,
                      color: isBanned ? Colors.green : Colors.red,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(isBanned ? lp.getText('unblock') : lp.getText('block'), style: TextStyle(fontSize: 13, color: isBanned ? Colors.green : Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddStaffDialog(BuildContext context, LanguageProvider lp, FirestoreService firestore, String? residenceId) {
    final nameController = TextEditingController();
    final idController = TextEditingController();
    final passController = TextEditingController();
    final deptController = TextEditingController();
    String role = 'worker';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: context.appCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            title: Text(
              lp.getText('add_staff') == 'add_staff' ? 'Ajouter un employé' : lp.getText('add_staff'),
              style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: context.appTextPrimary, fontSize: 22),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Créez un compte pour un nouvel administrateur ou ouvrier.", style: GoogleFonts.inter(color: context.appTextSecondary, fontSize: 13)),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    value: role,
                    dropdownColor: context.appCard,
                    decoration: _inputDecoration('Rôle', Icons.admin_panel_settings_rounded, isDark),
                    style: GoogleFonts.inter(color: context.appTextPrimary),
                    items: const [
                      DropdownMenuItem(value: 'worker', child: Text('Ouvrier')),
                      DropdownMenuItem(value: 'administrator', child: Text('Administrateur')),
                    ],
                    onChanged: (val) => setDialogState(() => role = val!),
                  ),
                  const SizedBox(height: 16),
                  _buildModernInput(controller: nameController, label: 'Nom complet', icon: Icons.person_outline_rounded, isDark: isDark),
                  const SizedBox(height: 16),
                  _buildModernInput(controller: idController, label: 'Identifiant (Login)', icon: Icons.fingerprint_rounded, isDark: isDark, hint: 'ex: user123'),
                  const SizedBox(height: 16),
                  _buildModernInput(controller: passController, label: 'Mot de passe', icon: Icons.lock_outline_rounded, isDark: isDark, isPassword: true),
                  if (role == 'worker') ...[
                    const SizedBox(height: 16),
                    _buildModernInput(controller: deptController, label: 'Département', icon: Icons.business_center_outlined, isDark: isDark, hint: 'ex: Plomberie'),
                  ],
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx), 
                child: Text('Annuler', style: GoogleFonts.inter(color: context.appTextSecondary, fontWeight: FontWeight.bold))
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  await firestore.registerStaff(
                    name: nameController.text.trim(),
                    customId: idController.text.trim(),
                    password: passController.text.trim(),
                    role: role,
                    department: role == 'worker' ? deptController.text.trim() : null,
                    residenceId: residenceId,
                  );
                  if (context.mounted) Navigator.pop(ctx);
                },
                child: Text('Créer', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModernInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    String? hint,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: GoogleFonts.inter(color: context.appTextPrimary, fontSize: 15),
      decoration: _inputDecoration(label, icon, isDark, hint: hint),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, bool isDark, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: GoogleFonts.inter(color: context.appTextSecondary, fontSize: 14),
      prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
      filled: true,
      fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
