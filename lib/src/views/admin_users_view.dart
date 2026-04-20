import 'package:flutter/material.dart';
import '../components/custom_menu_button.dart';
import 'package:provider/provider.dart';
import 'package:diacritic/diacritic.dart';
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
  String _statusFilter = 'all'; // 'all', 'active', 'blocked'
  final TextEditingController _searchController = TextEditingController();
  Stream<List<Map<String, dynamic>>>? _usersStream;

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
      _usersStream = firestore.getStudents(residenceId: auth.currentResidenceId);
    });
  }

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
        stream: _usersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _usersStream != null) {
            return const Center(child: CircularProgressIndicator(color: _kGreen));
          }

          final allStudents = snapshot.data ?? [];
          final filteredStudents = allStudents.where((s) {
            // Status Filter
            if (_statusFilter == 'blocked' && s['isBanned'] != true) return false;
            if (_statusFilter == 'active' && s['isBanned'] == true) return false;

            // Search Filter
            if (_searchQuery.isEmpty) return true;
            
            final terms = removeDiacritics(_searchQuery.toLowerCase()).split(' ').where((t) => t.isNotEmpty);
            
            final name = removeDiacritics((s['displayName'] ?? '').toString().toLowerCase());
            final nomFr = removeDiacritics((s['nomFr'] ?? '').toString().toLowerCase());
            final prenomFr = removeDiacritics((s['prenomFr'] ?? '').toString().toLowerCase());
            final matricule = removeDiacritics((s['matricule'] ?? s['uid'] ?? '').toString().toLowerCase());
            final bloc = removeDiacritics((s['bloc'] ?? '').toString().toLowerCase());
            final room = removeDiacritics((s['room'] ?? s['chambre'] ?? '').toString().toLowerCase());

            final combined = "$name $nomFr $prenomFr $matricule $bloc $room";
            
            return terms.every((term) => combined.contains(term));
          }).toList();

          final total = allStudents.length;
          final blocked = allStudents.where((s) => s['isBanned'] == true).length;
          final active = total - blocked;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lp.getText('students') ?? 'Étudiants',
                style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: context.appTextPrimary),
              ),
              const SizedBox(height: 20),
              // Stats Row (Interactive)
              Row(
                children: [
                  _buildSmallStat(
                    context, 
                    lp.getText('total'), 
                    total.toString(), 
                    _kGreen, 
                    isActive: _statusFilter == 'all',
                    onTap: () => setState(() => _statusFilter = 'all'),
                  ),
                  const SizedBox(width: 12),
                  _buildSmallStat(
                    context, 
                    lp.getText('active'), 
                    active.toString(), 
                    const Color(0xFF10B981),
                    isActive: _statusFilter == 'active',
                    onTap: () => setState(() => _statusFilter = 'active'),
                  ),
                  const SizedBox(width: 12),
                  _buildSmallStat(
                    context, 
                    lp.getText('blocked'), 
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
                          color: _searchQuery.isNotEmpty ? _kGreen.withOpacity(0.5) : const Color(0xFFE5E7EB),
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
                              onChanged: (val) => setState(() => _searchQuery = val),
                              style: GoogleFonts.inter(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: lp.getText('search_student'),
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
                ],
              ),
              const SizedBox(height: 12),
              // Results Count
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  "${filteredStudents.length} ${lp.getText('students') ?? 'étudiants'} trouvés",
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
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
                          style: GoogleFonts.inter(color: Colors.grey),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF0E2318)),
      ),
    );
  }


  Widget _buildSmallStat(BuildContext context, String label, String value, Color color, {required bool isActive, required VoidCallback onTap}) {
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

  Widget _buildModernUserCard(BuildContext context, LanguageProvider lp, Map<String, dynamic> student, FirestoreService firestore) {
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
                style: GoogleFonts.inter(color: isBanned ? Colors.grey : const Color(0xFF1D5C35), fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black)),
                const SizedBox(height: 4),
                Text('$residence • Bloc $bloc • Ch $room', style: GoogleFonts.inter(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.grey, size: 20),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (val) async {
              if (val == 'ban') {
                await firestore.toggleUserBan(userId, !isBanned);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
                    const SizedBox(width: 10),
                    Text(lp.getText('edit'), style: const TextStyle(fontSize: 13)),
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
                    Text(isBanned ? lp.getText('unblock') : lp.getText('block'), style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}
