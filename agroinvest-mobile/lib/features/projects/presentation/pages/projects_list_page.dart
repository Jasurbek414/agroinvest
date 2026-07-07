import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/asset_type_meta.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/shimmer_loader.dart';
import '../../../../core/widgets/project_image_gallery.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/projects_provider.dart';

class ProjectsListPage extends StatefulWidget {
  const ProjectsListPage({super.key});

  @override
  State<ProjectsListPage> createState() => _ProjectsListPageState();
}

class _ProjectsListPageState extends State<ProjectsListPage> {
  String _selectedStatus = 'FUNDING';
  String? _selectedAssetType; // null = all types

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  void _fetch() {
    Provider.of<ProjectsProvider>(context, listen: false)
        .fetchProjects(status: _selectedStatus, assetType: _selectedAssetType);
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
            _buildWelcomeHeader(user),
            _buildStatusFilterRow(),
            _buildAssetTypeFilterRow(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => _fetch(),
                color: AppColors.primary,
                child: provider.loading
                    ? const ShimmerList()
                    : provider.error != null
                        ? ErrorStateWidget(message: provider.error!, onRetry: _fetch)
                        : provider.projects.isEmpty
                            ? const EmptyState(
                                icon: Icons.inventory_2_outlined,
                                title: 'Loyihalar topilmadi',
                                subtitle: 'Boshqa filtr yoki toifani tanlab ko\'ring',
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
                context.push('/projects/create').then((_) => _fetch());
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

  Widget _buildStatusFilterRow() {
    final filters = [
      {'label': 'Mablag\' yig\'ish', 'value': 'FUNDING'},
      {'label': 'Faol parvarish', 'value': 'ACTIVE'},
      {'label': 'Yakunlangan', 'value': 'COMPLETED'},
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedStatus == f['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: () {
                setState(() => _selectedStatus = f['value']!);
                _fetch();
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

  // AssetType category chips - previously there was no way to filter by
  // chorva/dehqonchilik/issiqxona/parrandachilik/asalarichilik at all.
  Widget _buildAssetTypeFilterRow() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SizedBox(
        height: 34,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _buildAssetTypeChip(null, 'Barchasi', Icons.apps_rounded, AppColors.textDark),
            ...kAssetTypeMeta.entries.map(
              (e) => _buildAssetTypeChip(e.key, e.value.label, e.value.icon, e.value.color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetTypeChip(String? value, String label, IconData icon, Color color) {
    final isSelected = _selectedAssetType == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: () {
          setState(() => _selectedAssetType = value);
          _fetch();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.12) : AppColors.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? color : AppColors.border, width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: isSelected ? color : AppColors.textMuted),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : AppColors.textMuted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project) {
    final raised = double.tryParse(project['raisedAmount'].toString()) ?? 0.0;
    final target = double.tryParse(project['targetAmount'].toString()) ?? 1.0;
    final returnPct = project['expectedReturnPct']?.toString() ?? '0';
    final duration = project['durationDays']?.toString() ?? '0';
    final assetType = project['assetType']?.toString() ?? 'OTHER';
    final meta = getAssetTypeMeta(assetType);
    final mediaUrls = (project['mediaUrls'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];

    final percent = (raised / target).clamp(0.0, 1.0);
    final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String formatAmount(double val) {
      return val.toStringAsFixed(0).replaceAllMapped(formatter, (Match m) => '${m[1]} ') + ' UZS';
    }

    return Card(
      color: AppColors.cardBg,
      margin: const EdgeInsets.only(top: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 1.5),
      ),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/projects/${project['id']}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProjectImageCarousel(
              imageUrls: mediaUrls,
              assetType: assetType,
              height: 150,
              borderRadius: BorderRadius.zero,
            ),
            Padding(
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
                          color: meta.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(meta.icon, size: 13, color: meta.color),
                            const SizedBox(width: 5),
                            Text(
                              meta.label,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: meta.color),
                            ),
                          ],
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
          ],
        ),
      ),
    );
  }
}
