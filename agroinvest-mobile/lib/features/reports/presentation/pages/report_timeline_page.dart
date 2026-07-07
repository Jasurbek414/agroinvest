import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/shimmer_loader.dart';
import '../../data/report_repository.dart';

const Map<String, (String, Color, IconData)> kReportTypeMeta = {
  'DAILY': ('Kunlik', AppColors.primary, Icons.today_rounded),
  'ROUTINE': ('Muntazam', AppColors.info, Icons.description_rounded),
  'EMERGENCY': ('Favqulodda', AppColors.danger, Icons.warning_amber_rounded),
  'VERIFICATION': ('Tekshiruv', Color(0xFF8B5CF6), Icons.verified_rounded),
  'FINAL': ('Yakuniy', Color(0xFFB45309), Icons.flag_rounded),
  'COMPLETION': ('Tugatish', AppColors.textMuted, Icons.done_all_rounded),
};

/// The trust timeline: every report of a project (daily logs with metrics,
/// routine photo reports, emergencies) - visible to farmer AND investors.
class ReportTimelinePage extends StatefulWidget {
  final String projectId;
  final String? projectTitle;

  const ReportTimelinePage({super.key, required this.projectId, this.projectTitle});

  @override
  State<ReportTimelinePage> createState() => _ReportTimelinePageState();
}

class _ReportTimelinePageState extends State<ReportTimelinePage> {
  final _repository = ReportRepository();
  List<dynamic>? _reports;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _repository.fetchProjectReports(widget.projectId);
      if (mounted) setState(() => _reports = data);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Hisobotlar tarixi')),
      body: SafeArea(
        child: _loading
            ? const Padding(padding: AppSpacing.page, child: ShimmerList(count: 5))
            : _error != null
                ? ErrorStateWidget(message: _error!, onRetry: _load)
                : RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: _load,
                    child: (_reports == null || _reports!.isEmpty)
                        ? ListView(
                            children: const [
                              SizedBox(height: 120),
                              EmptyState(
                                icon: Icons.history_rounded,
                                title: 'Hisobotlar yo\'q',
                                subtitle: 'Fermer hali hisobot topshirmagan',
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: AppSpacing.page,
                            itemCount: _reports!.length + (widget.projectTitle != null ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (widget.projectTitle != null && index == 0) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                                  child: Text(widget.projectTitle!, style: AppTypography.h2),
                                );
                              }
                              final report = Map<String, dynamic>.from(
                                  _reports![index - (widget.projectTitle != null ? 1 : 0)]);
                              return _ReportTimelineTile(report: report);
                            },
                          ),
                  ),
      ),
    );
  }
}

class _ReportTimelineTile extends StatelessWidget {
  final Map<String, dynamic> report;
  const _ReportTimelineTile({required this.report});

  @override
  Widget build(BuildContext context) {
    final meta = kReportTypeMeta[report['reportType']] ?? kReportTypeMeta['ROUTINE']!;
    final metrics = report['metrics'] != null ? Map<String, dynamic>.from(report['metrics']) : null;
    final media = List<String>.from(report['mediaUrls'] as List? ?? []);
    final verified = report['verified'] == true || report['isVerified'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Timeline rail
            Column(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: meta.$2.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(meta.$3, color: meta.$2, size: 18),
                ),
                Expanded(
                  child: Container(width: 2, color: AppColors.border),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.md),
            // Card
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radius),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(meta.$1, style: AppTypography.label.copyWith(color: meta.$2)),
                        const Spacer(),
                        if (verified) ...[
                          const Icon(Icons.verified_rounded, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                        ],
                        Text(formatDateTime(report['createdAt']), style: AppTypography.caption),
                      ],
                    ),
                    if (metrics != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.lg,
                        runSpacing: 4,
                        children: [
                          if (metrics['headcount'] != null)
                            _MetricChip(icon: Icons.numbers_rounded, label: '${metrics['headcount']} bosh'),
                          if (metrics['deaths'] != null && (metrics['deaths'] as num) > 0)
                            _MetricChip(icon: Icons.trending_down_rounded, label: "${metrics['deaths']} o'lim", color: AppColors.danger),
                          if (metrics['feedKg'] != null)
                            _MetricChip(icon: Icons.grass_rounded, label: '${metrics['feedKg']} kg yem'),
                          if (metrics['avgWeightKg'] != null)
                            _MetricChip(icon: Icons.monitor_weight_rounded, label: '~${metrics['avgWeightKg']} kg'),
                        ],
                      ),
                      if ((metrics['healthNote'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(metrics['healthNote'].toString(), style: AppTypography.bodyMuted),
                      ],
                    ],
                    if ((report['notes'] ?? '').toString().isNotEmpty && metrics == null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(report['notes'].toString(), style: AppTypography.bodyMuted, maxLines: 3, overflow: TextOverflow.ellipsis),
                    ],
                    if (media.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        height: 64,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: media.length,
                          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                          itemBuilder: (context, i) => InkWell(
                            onTap: () => showDialog(
                              context: context,
                              builder: (_) => Dialog(
                                insetPadding: const EdgeInsets.all(AppSpacing.lg),
                                child: InteractiveViewer(child: CachedNetworkImage(imageUrl: media[i])),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: media[i],
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => const ShimmerBox(height: 64, width: 64),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (report['geoLat'] != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 12, color: AppColors.textMuted),
                          const SizedBox(width: 2),
                          Text('GPS tasdiqlangan', style: AppTypography.caption),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _MetricChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color ?? AppColors.textMuted),
        const SizedBox(width: 4),
        Text(label, style: AppTypography.caption.copyWith(
          color: color ?? AppColors.textMuted,
          fontWeight: FontWeight.bold,
        )),
      ],
    );
  }
}
