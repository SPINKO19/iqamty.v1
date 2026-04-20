import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diacritic/diacritic.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firestore_service.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../core/theme/colors.dart';

class AdminWorkersView extends StatefulWidget {
  const AdminWorkersView({super.key});

  @override
  State<AdminWorkersView> createState() => _AdminWorkersViewState();
}

class _AdminWorkersViewState extends State<AdminWorkersView> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all'; // 'all', 'active', 'blocked'
  Stream<List<Map<String, dynamic>>>? _workersStream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initStream();
    });
  }

  void _initStream() {
    final auth = context.read<AuthProvider>();
    final firestore = context.read<FirestoreService>();
    setState(() {
      _workersStream = firestore.getWorkers(residenceId: auth.currentResidenceId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final firestore = context.watch<FirestoreService>();
    final auth = context.watch<AuthProvider>();
    final lp = context.watch<LanguageProvider>();
    final resId = auth.currentResidenceId;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _workersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _workersStream != null) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF1D5C35)));
          }
          final workers = snapshot.data ?? [];
          final active = workers.where((w) => w['isBanned'] != true).length;
          final blocked = workers.length - active;

          final filtered = workers.where((w) {
            // Status Filter
            final isWorkerBanned = w['isBanned'] == true;
            if (_statusFilter == 'blocked' && !isWorkerBanned) return false;
            if (_statusFilter == 'active' && isWorkerBanned) return false;

            // Search Filter
            if (_searchQuery.isEmpty) return true;

            final terms = removeDiacritics(_searchQuery.toLowerCase()).split(' ').where((t) => t.isNotEmpty);
            
            final name = removeDiacritics((w['displayName'] ?? '').toString().toLowerCase());
            final id = removeDiacritics((w['customId'] ?? '').toString().toLowerCase());
            final dept = removeDiacritics((w['department'] ?? '').toString().toLowerCase());

            final combined = "$name $id $dept";

            return terms.every((term) => combined.contains(term));
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Row
              Row(
                children: [
                  _buildSmallStat(
                    'Total', 
                    workers.length.toString(), 
                    const Color(0xFF1D5C35),
                    isActive: _statusFilter == 'all',
                    onTap: () => setState(() => _statusFilter = 'all'),
                  ),
                  const SizedBox(width: 12),
                  _buildSmallStat(
                    'Actifs', 
                    active.toString(), 
                    const Color(0xFF10B981),
                    isActive: _statusFilter == 'active',
                    onTap: () => setState(() => _statusFilter = 'active'),
                  ),
                  const SizedBox(width: 12),
                  _buildSmallStat(
                    'Bloqués', 
                    blocked.toString(), 
                    const Color(0xFFEF4444),
                    isActive: _statusFilter == 'blocked',
                    onTap: () => setState(() => _statusFilter = 'blocked'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Search & Results Row
              Row(
                children: [
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _searchQuery.isNotEmpty ? const Color(0xFF1D5C35).withOpacity(0.5) : const Color(0xFFE5E7EB),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                              style: GoogleFonts.inter(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Rechercher un ouvrier...',
                                hintStyle: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              child: const Icon(Icons.close_rounded, color: Colors.grey, size: 18),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildHeaderAction(
                    icon: Icons.person_add_rounded,
                    onTap: () => _showAddWorkerDialog(context, firestore, resId),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Results Count
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  "${filtered.length} travailleurs trouvés",
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 24),
              
              if (filtered.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(60),
                    child: Text('Aucun travailleur trouvé', style: GoogleFonts.inter(color: Colors.grey)),
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cardsPerRow = constraints.maxWidth > 800 ? 2 : 1;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cardsPerRow,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent: 80,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final worker = filtered[index];
                        final isBanned = worker['isBanned'] == true;
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isBanned ? Colors.grey.withOpacity(0.1) : const Color(0xFF1D5C35).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.engineering_rounded, color: isBanned ? Colors.grey : const Color(0xFF1D5C35), size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(worker['displayName'] ?? 'Inconnu', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black)),
                                    const SizedBox(height: 2),
                                    Text(
                                      'ID: ${worker['customId'] ?? '--'} • ${worker['department'] ?? 'Pas de dép.'}',
                                      style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                onPressed: () => _confirmDelete(context, firestore, worker['id']),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF0E2318)),
      ),
    );
  }

  Widget _buildSmallStat(String label, String value, Color color, {required bool isActive, required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? color : const Color(0xFFE5E7EB),
              width: isActive ? 2 : 1,
            ),
            boxShadow: isActive ? [BoxShadow(color: color.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))] : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey)),
              const SizedBox(height: 8),
              Text(value, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, FirestoreService firestore, String? docId) {
    if (docId == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Supprimer', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text('Voulez-vous vraiment supprimer ce travailleur ?', style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: Text('Annuler', style: GoogleFonts.inter(color: Colors.grey, fontWeight: FontWeight.bold))
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await firestore.deleteUser(docId);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Travailleur supprimé'), backgroundColor: Colors.redAccent),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ), 
            child: Text('Supprimer', style: GoogleFonts.inter(fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }

  void _showAddWorkerDialog(BuildContext context, FirestoreService firestore, String? resId) {
    final nameController = TextEditingController();
    final idController = TextEditingController();
    final passController = TextEditingController();
    String? selectedDept;
    
    final List<String> departments = [
      'Plomberie',
      'Électricité',
      'Menuiserie',
      'Maçonnerie',
      'Peinture',
      'Nettoyage',
      'Espaces Verts',
      'Administration',
      'Autre'
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: context.appCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          titlePadding: const EdgeInsets.fromLTRB(28, 28, 28, 10),
          title: Text(
            'Ajouter un ouvrier', 
            style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: context.appTextPrimary, fontSize: 22, letterSpacing: -0.5)
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Créez un compte d'accès pour un nouveau membre du personnel.", style: GoogleFonts.inter(color: context.appTextSecondary, fontSize: 13)),
                const SizedBox(height: 24),
                _buildModernInput(
                  controller: nameController,
                  label: 'Nom complet',
                  icon: Icons.person_outline_rounded,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _buildModernInput(
                  controller: idController,
                  label: 'Identifiant unique',
                  hint: 'ex: worker123',
                  icon: Icons.fingerprint_rounded,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _buildModernInput(
                  controller: passController,
                  label: 'Mot de passe',
                  icon: Icons.lock_outline_rounded,
                  isDark: isDark,
                  isPassword: true,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: _inputDecoration('Département', Icons.business_center_outlined, isDark),
                  dropdownColor: context.appCard,
                  items: departments.map((dept) => DropdownMenuItem(
                    value: dept,
                    child: Text(dept, style: GoogleFonts.inter(color: context.appTextPrimary, fontSize: 14)),
                  )).toList(),
                  onChanged: (val) => selectedDept = val,
                  style: GoogleFonts.inter(color: context.appTextPrimary),
                ),
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
                if (nameController.text.isEmpty || idController.text.isEmpty || selectedDept == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez remplir tous les champs')));
                  return;
                }
                
                await firestore.registerStaff(
                  name: nameController.text.trim(),
                  customId: idController.text.trim(),
                  password: passController.text.trim(),
                  role: 'worker',
                  department: selectedDept!,
                  residenceId: resId,
                );
                
                if (context.mounted) Navigator.pop(ctx);
              },
              child: Text('Ajouter', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
            ),
          ],
        );
      },
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
