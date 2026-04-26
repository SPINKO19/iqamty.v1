import 'package:flutter/material.dart';
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
  final ValueNotifier<String> _searchQueryNotifier = ValueNotifier<String>('');
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchQueryNotifier.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LanguageProvider>();
    final auth = context.watch<AuthProvider>();
    final firestore = context.read<FirestoreService>();
    final residenceId = auth.currentResidenceId;

    return DefaultTabController(
      length: 2,
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: firestore.getStudents(residenceId: residenceId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _kGreen));
          }
    
          final allStudents = snapshot.data ?? [];
          final total = allStudents.length;
          final blocked = allStudents.where((s) => s['isBanned'] == true).length;
          final active = total - blocked;
    
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Row(
                  children: [
                    _buildSmallStat(context, lp.getText('total'), total.toString(), _kGreen),
                    const SizedBox(width: 12),
                    _buildSmallStat(context, lp.getText('active'), active.toString(), const Color(0xFF10B981)),
                    const SizedBox(width: 12),
                    _buildSmallStat(context, lp.getText('blocked'), blocked.toString(), const Color(0xFFEF4444)),
                  ],
                ),
              ),
              
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white.withValues(alpha: 0.05) 
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: context.appTextSecondary,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: [
                    Tab(text: lp.getText('all')),
                    Tab(text: lp.getText('blocked')),
                  ],
                ),
              ),
    
              Expanded(
                child: TabBarView(
                  children: [
                    _buildStudentList(allStudents, lp, firestore, residenceId),
                    _buildStudentList(allStudents.where((s) => s['isBanned'] == true).toList(), lp, firestore, residenceId),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStudentList(List<Map<String, dynamic>> students, LanguageProvider lp, FirestoreService firestore, String? residenceId) {
    return ValueListenableBuilder<String>(
      valueListenable: _searchQueryNotifier,
      builder: (context, query, child) {
        final filteredStudents = _filterStudents(students, query);

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _buildSearchBar(context, lp),
              const SizedBox(height: 24),
              if (filteredStudents.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.person_search_rounded, size: 48, color: context.appTextSecondary.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        Text(
                          query.isEmpty ? "Aucun étudiant trouvé" : "Aucun résultat trouvé",
                          style: GoogleFonts.inter(color: context.appTextSecondary),
                        ),
                      ],
                    ),
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
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _filterStudents(List<Map<String, dynamic>> students, String query) {
    if (query.isEmpty) return students;
    final q = query.toLowerCase().trim();
    
    return students.where((s) {
      final name = (s['displayName'] ?? '').toString().toLowerCase();
      final matricule = (s['matricule'] ?? s['uid'] ?? '').toString().toLowerCase();
      final room = (s['room'] ?? s['chambre'] ?? '').toString().toLowerCase();
      
      final nameParts = name.split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
      bool nameMatch = nameParts.any((part) => part.startsWith(q));
      bool matriculeMatch = matricule.startsWith(q);
      bool roomMatch = room.startsWith(q);
      
      return nameMatch || matriculeMatch || roomMatch;
    }).toList();
  }

  Widget _buildSearchBar(BuildContext context, LanguageProvider lp) {
    return Container(
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => _searchQueryNotifier.value = val,
        style: GoogleFonts.inter(fontSize: 14, color: context.appTextPrimary),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search_rounded, color: context.appTextSecondary, size: 20),
          suffixIcon: ValueListenableBuilder<String>(
            valueListenable: _searchQueryNotifier,
            builder: (context, val, child) {
              if (val.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: Icon(Icons.close_rounded, color: context.appTextSecondary, size: 18),
                onPressed: () {
                  _searchController.clear();
                  _searchQueryNotifier.value = '';
                },
              );
            },
          ),
          hintText: 'Rechercher par nom, matricule ou chambre...',
          hintStyle: GoogleFonts.inter(color: context.appTextSecondary, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
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
    final residence = student['residence'] ?? '---';
    final bloc = student['bloc'] ?? '---';
    final room = student['room'] ?? student['chambre'] ?? '---';
    final isBanned = student['isBanned'] == true;
    final userId = student['id'] ?? student['uid'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isBanned 
            ? Colors.red.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.1 : 0.05) 
            : context.appCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isBanned ? Colors.red.withValues(alpha: 0.5) : context.appBorder,
          width: isBanned ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                name[0].toUpperCase(),
                style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
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
                final router = GoRouter.of(context);
                final chatId = await firestore.startOrGetChat(userId, name, residenceId: residenceId);
                if (!mounted) return;
                router.go('/admin/chat/$chatId', extra: {'name': name, 'isAdmin': true});
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
}
