import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/asset_type_meta.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/shimmer_loader.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/project_repository.dart';
import '../../../reports/data/report_repository.dart';

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
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 24),
            onPressed: () => _openCalendarView(context),
            tooltip: 'Kalendar',
          ),
          const SizedBox(width: 8),
        ],
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

  void _openCalendarView(BuildContext context) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate == null) return;
    if (!mounted) return;

    _showReportsForDate(context, selectedDate);
  }

  void _showReportsForDate(BuildContext context, DateTime date) {
    final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return FutureBuilder<List<dynamic>>(
              future: _fetchAllReportsForDate(date),
              builder: (context, snapshot) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '$dateStr kungi hisobotlar',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: snapshot.connectionState == ConnectionState.waiting
                            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                            : snapshot.hasError
                                ? Center(child: Text('Xatolik yuz berdi: ${snapshot.error}', style: const TextStyle(color: AppColors.danger)))
                                : (snapshot.data == null || snapshot.data!.isEmpty)
                                    ? const Center(
                                        child: EmptyState(
                                          icon: Icons.assignment_late_outlined,
                                          title: 'Hisobotlar topilmadi',
                                          subtitle: 'Ushbu kunda hech qanday hisobot yuborilmagan.',
                                        ),
                                      )
                                    : ListView.builder(
                                        controller: scrollController,
                                        itemCount: snapshot.data!.length,
                                        itemBuilder: (context, idx) {
                                          final report = snapshot.data![idx];
                                          final type = report['reportType']?.toString() ?? 'ROUTINE';
                                          final notes = report['notes']?.toString() ?? '';
                                          final createdAt = report['createdAt']?.toString() ?? '';
                                          final mediaUrls = List<String>.from(report['mediaUrls'] ?? []);
                                          final projectTitle = report['projectTitle']?.toString() ?? 'Loyiha';
                                          
                                          return Card(
                                            margin: const EdgeInsets.only(bottom: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                              side: const BorderSide(color: AppColors.border),
                                            ),
                                            elevation: 0,
                                            color: Colors.white,
                                            child: Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          projectTitle,
                                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: type == 'DAILY' ? Colors.blue.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: Text(
                                                          type == 'DAILY' ? 'Kunlik' : (type == 'ROUTINE' ? 'Progress' : 'Tezkor'),
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.bold,
                                                            color: type == 'DAILY' ? Colors.blue : AppColors.primary,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    notes,
                                                    style: const TextStyle(fontSize: 13, color: AppColors.textDark),
                                                  ),
                                                  if (mediaUrls.isNotEmpty) ...[
                                                    const SizedBox(height: 12),
                                                    SizedBox(
                                                      height: 60,
                                                      child: ListView.builder(
                                                        scrollDirection: Axis.horizontal,
                                                        itemCount: mediaUrls.length,
                                                        itemBuilder: (context, mIdx) {
                                                          final url = mediaUrls[mIdx];
                                                          final isVideo = url.endsWith('.mp4') || url.endsWith('.mov') || url.endsWith('.3gp') || url.endsWith('.webm');
                                                          return Container(
                                                            margin: const EdgeInsets.only(right: 8),
                                                            width: 60,
                                                            height: 60,
                                                            decoration: BoxDecoration(
                                                              borderRadius: BorderRadius.circular(8),
                                                              border: Border.all(color: AppColors.border),
                                                            ),
                                                            child: ClipRRect(
                                                              borderRadius: BorderRadius.circular(8),
                                                              child: isVideo
                                                                  ? Container(
                                                                      color: Colors.black87,
                                                                      child: const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 24),
                                                                    )
                                                                  : Image.network(url, fit: BoxFit.cover),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                  const SizedBox(height: 8),
                                                  Align(
                                                    alignment: Alignment.bottomRight,
                                                    child: Text(
                                                      createdAt.replaceAll('T', ' ').split('.').first,
                                                      style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<List<dynamic>> _fetchAllReportsForDate(DateTime date) async {
    final reportRepository = ReportRepository();
    final List<dynamic> allReports = [];
    
    for (final p in _myProjects) {
      try {
        final reports = await reportRepository.fetchProjectReports(p['id']);
        for (final r in reports) {
          r['projectTitle'] = p['title'];
          allReports.add(r);
        }
      } catch (_) {
        // ignore
      }
    }
    
    return allReports.where((r) {
      if (r['createdAt'] == null) return false;
      try {
        final rDate = DateTime.parse(r['createdAt'].toString()).toLocal();
        return rDate.year == date.year && rDate.month == date.month && rDate.day == date.day;
      } catch (_) {
        return false;
      }
    }).toList();
  }
}
