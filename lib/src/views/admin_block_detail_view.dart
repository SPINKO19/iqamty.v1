import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../providers/language_provider.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../core/theme/colors.dart';

class AdminBlockDetailView extends StatefulWidget {
  final String blockId;
  const AdminBlockDetailView({super.key, required this.blockId});

  @override
  State<AdminBlockDetailView> createState() => _AdminBlockDetailViewState();
}

class _AdminBlockDetailViewState extends State<AdminBlockDetailView> {
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: _buildHeader(context, lp),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildSearchBar(context, lp),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: firestore.getStudents(residenceId: residenceId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF1D5C35)));
                }

                final allStudents = snapshot.data ?? [];
                final blockStudents = allStudents.where((s) {
                  final studentBlock = s['bloc']?.toString().toUpperCase() ?? '';
                  final targetBlock = widget.blockId.toUpperCase();
                  return studentBlock == targetBlock || 
                         studentBlock == 'BLOC $targetBlock' || 
                         (studentBlock.length > 1 && studentBlock.contains(targetBlock));
                }).toList();

                return ValueListenableBuilder<String>(
                  valueListenable: _searchQueryNotifier,
                  builder: (context, query, child) {
                    final filteredStudents = _filterStudents(blockStudents, query);

                    if (filteredStudents.isEmpty) {
                      return _buildEmptyState(context, query);
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: MediaQuery.of(context).size.width > 800 ? 2 : 1,
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _filterStudents(List<Map<String, dynamic>> students, String query) {
    if (query.isEmpty) return students;
    
    // Normalize query: lowercase and trim
    final q = query.toLowerCase().trim();
    
    return students.where((s) {
      final name = (s['displayName'] ?? '').toString().toLowerCase();
      final matricule = (s['matricule'] ?? s['uid'] ?? '').toString().toLowerCase();
      final room = (s['room'] ?? s['chambre'] ?? '').toString().toLowerCase();
      
      // Split name into parts (e.g., "Hocine Rekaïk" -> ["hocine", "rekaïk"])
      final nameParts = name.split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
      
      // Strict prefix match: the query must match the START of one of the name parts
      bool nameMatch = nameParts.any((part) => part.startsWith(q));
      
      // Also check matricule and room strictly from the start
      bool matriculeMatch = matricule.startsWith(q);
      bool roomMatch = room.startsWith(q);
      
      return nameMatch || matriculeMatch || roomMatch;
    }).toList();
  }

  Widget _buildHeader(BuildContext context, LanguageProvider lp) {
    // We need to get the total count from a Stream, but for simplicity in header 
    // we just use a static-looking header and we can pass the count if we want.
    // However, since we moved StreamBuilder down, we'll just show the title.
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/admin/rooms'),
          color: context.appTextPrimary,
          iconSize: 20,
        ),
        const SizedBox(width: 8),
        Text(
          '${lp.getText('residence_block')} ${widget.blockId}',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: context.appTextPrimary,
          ),
        ),
      ],
    );
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

  Widget _buildEmptyState(BuildContext context, String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search_rounded, size: 48, color: context.appTextSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              query.isEmpty ? "Aucun étudiant dans ce bloc" : "Aucun résultat trouvé",
              style: GoogleFonts.inter(color: context.appTextSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernUserCard(BuildContext context, LanguageProvider lp, Map<String, dynamic> student, FirestoreService firestore, String? residenceId) {
    final name = student['displayName'] ?? 'Étudiant';
    final room = student['room'] ?? student['chambre'] ?? '---';
    final isBanned = student['isBanned'] == true;
    final userId = student['matricule']?.toString() ?? student['uid']?.toString() ?? student['id']?.toString() ?? '';

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
              color: const Color(0xFF1D5C35).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: GoogleFonts.inter(color: const Color(0xFF1D5C35), fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: context.appTextPrimary)),
                const SizedBox(height: 4),
                Text('Chambre $room', style: GoogleFonts.inter(color: context.appTextSecondary, fontSize: 11)),
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
                    Text(lp.getText('messaging'), style: const TextStyle(fontSize: 13)),
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
