import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/projects_provider.dart';
import 'project_detail_page.dart';
import 'create_project_page.dart';

class ProjectsListPage extends StatefulWidget {
  const ProjectsListPage({super.key});

  @override
  State<ProjectsListPage> createState() => _ProjectsListPageState();
}

class _ProjectsListPageState extends State<ProjectsListPage> {
  String _selectedStatus = 'FUNDING';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProjectsProvider>(context, listen: false)
          .fetchProjects(status: _selectedStatus);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectsProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final isFarmer = user != null && user['role'] == 'FARMER';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Welcome Header Banner
            _buildWelcomeHeader(user),

            // Animated Filter Pill Row
            _buildFilterRow(),

            // Project List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => provider.fetchProjects(status: _selectedStatus),
                color: AppColors.primary,
                child: provider.loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : provider.error != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Text(
                                provider.error!,
                                style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : provider.projects.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.inventory_2_outlined, size: 54, color: AppColors.textMuted.withOpacity(0.4)),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Loyihalar topilmadi',
                                      style: TextStyle(color: AppColors.textMuted, fontSize: 15, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                                itemCount: provider.projects.length,
                                itemBuilder: (context, index) {
                                  final project = provider.projects[index];
                                  return _buildProjectCard(project);
                                },
                              ),
              ),
            ),
          ],
        ),
      ),
      // FAB only for Farmers to create new project requests
      floatingActionButton: isFarmer
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateProjectPage()),
                ).then((_) {
                  // Refresh list after returning from creation
                  provider.fetchProjects(status: _selectedStatus);
                });
              },
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Loyiha qo\'shish', style: TextStyle(fontWeight: FontWeight.bold)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            )
          : null,
    );
  }

  Widget _buildWelcomeHeader(Map<String, dynamic>? user) {
    final hasUser = user != null;
    final name = hasUser ? user['fullName'].toString().split(' ')[0] : 'Mehmon';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasUser ? 'Assalomu alaykum,' : 'AgroInvest platformasi',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hasUser ? '$name! 👋' : 'Xush kelibsiz! 🌱',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          if (hasUser)
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primaryLight,
              child: Text(
                name[0].toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16),
              ),
            )
          else
            const Icon(Icons.spa_rounded, color: AppColors.primary, size: 36),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    final filters = [
      {'label': 'Mablag\' yig\'ish', 'value': 'FUNDING'},
      {'label': 'Faol parvarish', 'value': 'ACTIVE'},
      {'label': 'Yakunlangan', 'value': 'COMPLETED'},
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedStatus == f['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedStatus = f['value']!;
                });
                Provider.of<ProjectsProvider>(context, listen: false)
                    .fetchProjects(status: _selectedStatus);
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.background,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: 1,
                  ),
                ),
                child: Text(
                  f['label']!,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project) {
    final raised = double.tryParse(project['raisedAmount'].toString()) ?? 0.0;
    final target = double.tryParse(project['targetAmount'].toString()) ?? 1.0;
    final returnPct = project['expectedReturnPct']?.toString() ?? '0';
    final duration = project['durationDays']?.toString() ?? '0';
    
    final percent = (raised / target).clamp(0.0, 1.0);
    final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String formatAmount(double val) {
      return val.toStringAsFixed(0).replaceAllMapped(formatter, (Match m) => '${m[1]} ') + ' UZS';
    }

    String getAssetLabel(String raw) {
      switch (raw.toUpperCase()) {
        case 'LIVESTOCK': return 'Chorvachilik';
        case 'CROP': return 'Dehqonchilik';
        case 'GREENHOUSE': return 'Issiqxona';
        case 'POULTRY': return 'Parrandachilik';
        case 'BEEKEEPING': return 'Asalachilik';
        default: return 'Boshqa';
      }
    }

    return Card(
      color: AppColors.cardBg,
      margin: const EdgeInsets.only(top: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 1.5),
      ),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProjectDetailPage(projectId: project['id']),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top tags row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      getAssetLabel(project['assetType']?.toString() ?? 'OTHER'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${project['riskLevel']} RISK',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Title & Description
              Text(
                project['title'] ?? '',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                project['description'] ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4),
              ),
              const SizedBox(height: 16),

              // Profit metrics
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text('Kutilayotgan foyda', style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text('+$returnPct%', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text('Muddati', style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text('$duration kun', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textDark)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Progress bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(percent * 100).toStringAsFixed(0)}% yig\'ildi',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  Text(
                    formatAmount(raised),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: percent,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
