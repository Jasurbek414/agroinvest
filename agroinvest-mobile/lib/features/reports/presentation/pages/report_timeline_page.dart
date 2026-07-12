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

  void _showReportDetails(BuildContext context, Map<String, dynamic> r) {
    final meta = kReportTypeMeta[r['reportType']] ?? kReportTypeMeta['ROUTINE']!;
    final metrics = r['metrics'] != null ? Map<String, dynamic>.from(r['metrics']) : null;
    final media = List<String>.from(r['mediaUrls'] as List? ?? []);
    final verified = r['verified'] == true || r['isVerified'] == true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: meta.$2.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(meta.$3, color: meta.$2, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${meta.$1} hisobot', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textDark)),
                          Text(formatDateTime(r['createdAt']), style: AppTypography.caption),
                        ],
                      ),
                    ),
                    if (verified)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_rounded, color: AppColors.primary, size: 12),
                            SizedBox(width: 4),
                            Text('Tasdiqlangan', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 10)),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.hourglass_empty_rounded, color: Colors.orange, size: 12),
                            SizedBox(width: 4),
                            Text('Kutilmoqda', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 10)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (metrics != null) ...[
                      const Text('Ko\'rsatkichlar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                      const SizedBox(height: 10),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 2.8,
                        children: [
                          if (metrics['headcount'] != null)
                            _MetricDetailCard(
                              icon: Icons.numbers_rounded,
                              label: 'Mavjud chorva',
                              value: '${metrics['headcount']} bosh',
                            ),
                          if (metrics['deaths'] != null)
                            _MetricDetailCard(
                              icon: Icons.trending_down_rounded,
                              label: 'Yo\'qotishlar (o\'lim)',
                              value: '${metrics['deaths']} bosh',
                              valueColor: (metrics['deaths'] as num) > 0 ? AppColors.danger : null,
                            ),
                          if (metrics['feedKg'] != null)
                            _MetricDetailCard(
                              icon: Icons.grass_rounded,
                              label: 'Kunlik ozuqa (yem)',
                              value: '${metrics['feedKg']} kg',
                            ),
                          if (metrics['avgWeightKg'] != null)
                            _MetricDetailCard(
                              icon: Icons.monitor_weight_rounded,
                              label: 'O\'rtacha vazn',
                              value: '${metrics['avgWeightKg']} kg',
                            ),
                          if (metrics['waterLiters'] != null)
                            _MetricDetailCard(
                              icon: Icons.water_drop_rounded,
                              label: 'Suv iste\'moli',
                              value: '${metrics['waterLiters']} litr',
                            ),
                          if (metrics['temperature'] != null)
                            _MetricDetailCard(
                              icon: Icons.thermostat_rounded,
                              label: 'Ob-havo harorati',
                              value: '${metrics['temperature']} °C',
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    const Text('Fermer izohi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[100]!),
                      ),
                      child: Text(
                        (r['notes'] ?? 'Izoh kiritilmagan.').toString(),
                        style: const TextStyle(fontSize: 13, color: AppColors.textDark, height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (media.isNotEmpty) ...[
                      const Text('Biriktirilgan rasmlar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                      const SizedBox(height: 10),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: media.length,
                        itemBuilder: (context, i) => InkWell(
                          onTap: () => showDialog(
                            context: context,
                            builder: (_) => Dialog(
                              child: InteractiveViewer(child: CachedNetworkImage(imageUrl: media[i])),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: media[i],
                              fit: BoxFit.cover,
                              placeholder: (_, __) => const ShimmerBox(height: 80, width: 80),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    if (r['geoLat'] != null) ...[
                      const Text('Geolokatsiya va xavfsizlik', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50]?.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[100]!.withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.gps_fixed_rounded, color: Colors.blue, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('GPS koordinatalar tasdiqlangan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textDark)),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Kenglik: ${r['geoLat']} · Uzunlik: ${r['geoLng']} (±${r['geoAccuracy'] ?? 0}m)',
                                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showReportDetails(context, report),
                  borderRadius: BorderRadius.circular(AppSpacing.radius),
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

class _MetricDetailCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _MetricDetailCard({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: const TextStyle(fontSize: 8, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: valueColor ?? AppColors.textDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
