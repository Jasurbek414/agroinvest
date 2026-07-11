import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/asset_type_meta.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/shimmer_loader.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/project_repository.dart';

class MyProjectsPage extends StatefulWidget {
  const MyProjectsPage({super.key});

  @override
  State<MyProjectsPage> createState() => _MyProjectsPageState();
}

class _MyProjectsPageState extends State<MyProjectsPage> {
  final _projectRepository = ProjectRepository();
  List<dynamic> _myProjects = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchMyProjects();
  }

  Future<void> _fetchMyProjects() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final projects = await _projectRepository.getMyProjects();
      setState(() {
        _myProjects = projects;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String formatAmount(double val) {
      return val.toStringAsFixed(0).replaceAllMapped(formatter, (Match m) => '${m[1]} ') + ' UZS';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mening loyihalarim', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textDark,
        centerTitle: true,
      ),
      body: _loading
          ? const ShimmerList()
          : _error != null
              ? ErrorStateWidget(message: _error!, onRetry: _fetchMyProjects)
              : _myProjects.isEmpty
                  ? const EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'Loyihalar topilmadi',
                      subtitle: 'Siz tomondan arizalar kiritilmagan. Loyiha yaratish uchun bosh sahifadagi "+" tugmasini bosing.',
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchMyProjects,
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _myProjects.length,
                        itemBuilder: (context, index) {
                          final p = _myProjects[index];
                          final raised = double.tryParse(p['raisedAmount'].toString()) ?? 0.0;
                          final target = double.tryParse(p['targetAmount'].toString()) ?? 1.0;
                          final percent = (raised / target).clamp(0.0, 1.0);
                          final status = p['status']?.toString() ?? 'PENDING';
                          final meta = getAssetTypeMeta(p['assetType']?.toString());

                          return Card(
                            color: Colors.white,
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: AppColors.border, width: 1.5),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => context.push('/projects/${p['id']}'),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Icon(meta.icon, size: 15, color: meta.color),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  p['title'] ?? 'Loyiha nomi',
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        StatusBadge(status: status),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Kerakli mablag\'', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                            const SizedBox(height: 2),
                                            Text(formatAmount(target), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            const Text('Kutilayotgan daromad', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                            const SizedBox(height: 2),
                                            Text('+${p['expectedReturnPct']}%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: percent,
                                        backgroundColor: AppColors.background,
                                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                                        minHeight: 5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('${(percent * 100).toStringAsFixed(0)}% yig\'ildi', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                        Text('Yig\'ildi: ${formatAmount(raised)}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                      ],
                                    ),
                                    if (status == 'ACTIVE') ...[
                                      const Divider(height: 24, color: AppColors.border),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () => context.push('/projects/${p['id']}/daily-log'),
                                              icon: const Icon(Icons.today_rounded, size: 16),
                                              label: const Text('Kunlik hisobot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppColors.primary,
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                padding: const EdgeInsets.symmetric(vertical: 10),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () => context.push('/projects/${p['id']}/report'),
                                              icon: const Icon(Icons.upload_file_rounded, size: 16),
                                              label: const Text('Hisobot yuborish', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: AppColors.primary,
                                                side: const BorderSide(color: AppColors.primary, width: 1.2),
                                                padding: const EdgeInsets.symmetric(vertical: 10),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

}
