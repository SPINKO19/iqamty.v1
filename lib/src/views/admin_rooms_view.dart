import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../core/theme/colors.dart';

class AdminRoomsView extends StatelessWidget {
  const AdminRoomsView({super.key});

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LanguageProvider>();
    final auth = context.watch<AuthProvider>();
    final firestore = context.read<FirestoreService>();
    final resId = auth.currentResidenceId;

    final girlsBlocks = ['B', 'C', 'D', 'E'];
    final boysBlocks = ['A', 'G', 'H', 'I', 'J'];
    final workersBlocks = ['F'];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: firestore.getStudents(residenceId: resId),
        builder: (context, snapshot) {
          final students = snapshot.data ?? [];
          
          // Count residents per block
          final Map<String, int> blockCounts = {};
          final allBlocks = [...girlsBlocks, ...boysBlocks, ...workersBlocks];
          for (var block in allBlocks) {
            blockCounts[block] = students.where((s) {
              final studentBlock = s['bloc']?.toString().toUpperCase() ?? '';
              // Match if the field contains the block letter (e.g., 'A' in 'Bloc A' or 'A')
              return studentBlock == block || 
                     studentBlock == 'BLOC $block' || 
                     (studentBlock.length > 1 && studentBlock.contains(block));
            }).length;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(
                  lp.getText('rooms_management'), 
                  '${students.length} étudiants trouvés dans cette résidence. Gérez l\'occupation par catégorie.'
                ),
                const SizedBox(height: 32),
                
                _buildSection(context, 'Résidence Garçons', Icons.male_rounded, boysBlocks, blockCounts, lp),
                const SizedBox(height: 48),
                _buildSection(context, 'Résidence Filles', Icons.female_rounded, girlsBlocks, blockCounts, lp),
                const SizedBox(height: 48),
                _buildSection(context, 'Résidence Travailleurs', Icons.engineering_rounded, workersBlocks, blockCounts, lp),
                
                const SizedBox(height: 48),
                _buildDataDiagnostics(context, students, allBlocks),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildDataDiagnostics(BuildContext context, List<Map<String, dynamic>> students, List<String> allBlocks) {
    final studentsWithNoBlock = students.where((s) {
      final b = s['bloc']?.toString() ?? '';
      return b.isEmpty;
    }).length;

    if (students.isEmpty && studentsWithNoBlock == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_rounded, color: Colors.amber, size: 20),
              const SizedBox(width: 10),
              Text(
                'Diagnostic des données',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.amber.shade900),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDiagItem('Total étudiants détectés', students.length.toString()),
          _buildDiagItem('Étudiants sans bloc assigné', studentsWithNoBlock.toString()),
          if (studentsWithNoBlock > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Note : Les étudiants sans bloc n\'apparaissent pas dans les catégories ci-dessus.',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.amber.shade800, fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDiagItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: Colors.black54)),
          Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildHeader(String title, String subtitle) {
    return Builder(
      builder: (context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: context.appTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: context.appTextSecondary,
              ),
            ),
          ],
        );
      }
    );
  }

  Widget _buildSection(BuildContext context, String title, IconData icon, List<String> blocks, Map<String, int> counts, LanguageProvider lp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF1D5C35)),
            const SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.appTextPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Divider(color: context.appBorder)),
          ],
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 1200 ? 5 : (constraints.maxWidth > 800 ? 3 : 2);
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 0.85,
              ),
              itemCount: blocks.length,
              itemBuilder: (context, index) {
                final blockName = blocks[index];
                return _buildBlockCard(context, blockName, counts[blockName] ?? 0, lp);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildBlockCard(BuildContext context, String blockName, int residentCount, LanguageProvider lp) {
    // Total rooms per block is 97
    const totalRooms = 97;
    final percent = (residentCount / totalRooms * 100).toInt();

    return Container(
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.go('/admin/rooms/$blockName');
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D5C35).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          blockName,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF1D5C35),
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    Icon(Icons.more_vert_rounded, color: context.appTextSecondary, size: 20),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  '${lp.getText('residence_block')} $blockName',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: context.appTextPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Occupation',
                      style: GoogleFonts.inter(fontSize: 11, color: context.appTextSecondary),
                    ),
                    Text(
                      '$percent%',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: percent > 90 ? Colors.red : const Color(0xFF1D5C35),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: residentCount / totalRooms,
                    backgroundColor: context.appBorder,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      percent > 90 ? Colors.red.withValues(alpha: 0.7) : const Color(0xFF1D5C35),
                    ),
                    minHeight: 6,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    _buildStatItem(Icons.door_front_door_outlined, totalRooms.toString()),
                    const SizedBox(width: 12),
                    _buildStatItem(Icons.person_outline_rounded, residentCount.toString()),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          value,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey),
        ),
      ],
    );
  }
}
