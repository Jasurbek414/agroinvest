import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/shimmer_loader.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/vet_repository.dart';

const Map<String, (String, Color, IconData)> kVetHealthMeta = {
  'HEALTHY': ("Sog'lom", AppColors.primary, Icons.check_circle_rounded),
  'TREATED': ('Davolangan', AppColors.info, Icons.healing_rounded),
  'QUARANTINE': ('Karantinda', AppColors.accent, Icons.warning_amber_rounded),
  'SICK': ('Kasal', AppColors.danger, Icons.sick_rounded),
};

/// Veterinary inspection history of a project. Public sees VERIFIED documents
/// (trust signal); the owning farmer also sees pending/rejected ones and can
/// upload a new conclusion.
class ProjectVetPage extends StatefulWidget {
  final String projectId;
  final String? projectTitle;
  final String? farmerId;

  const ProjectVetPage({super.key, required this.projectId, this.projectTitle, this.farmerId});

  @override
  State<ProjectVetPage> createState() => _ProjectVetPageState();
}

class _ProjectVetPageState extends State<ProjectVetPage> {
  final _repository = VetRepository();
  List<dynamic>? _inspections;
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
      final data = await _repository.fetchProjectInspections(widget.projectId);
      if (mounted) setState(() => _inspections = data);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _isOwner {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    return user != null && widget.farmerId != null && user['id']?.toString() == widget.farmerId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Veterinar nazorati')),
      floatingActionButton: _isOwner
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              onPressed: () async {
                final added = await context.push<bool>('/projects/${widget.projectId}/vet/add');
                if (added == true) _load();
              },
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('Hujjat yuklash', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
      body: SafeArea(
        child: _loading
            ? const Padding(padding: AppSpacing.page, child: ShimmerList(count: 4))
            : _error != null
                ? ErrorStateWidget(message: _error!, onRetry: _load)
                : RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: _load,
                    child: (_inspections == null || _inspections!.isEmpty)
                        ? ListView(
                            children: const [
                              SizedBox(height: 120),
                              EmptyState(
                                icon: Icons.health_and_safety_rounded,
                                title: 'Veterinar hujjatlari yo\'q',
                                subtitle: 'Bu loyihada hali tasdiqlangan veterinar ko\'rigi yo\'q',
                              ),
                            ],
                          )
                        : ListView(
                            padding: AppSpacing.page,
                            children: [
                              if (widget.projectTitle != null) ...[
                                Text(widget.projectTitle!, style: AppTypography.h2),
                                const SizedBox(height: AppSpacing.lg),
                              ],
                              ..._inspections!.map((i) => _InspectionTile(inspection: Map<String, dynamic>.from(i))),
                              const SizedBox(height: 80),
                            ],
                          ),
                  ),
      ),
    );
  }
}

class _InspectionTile extends StatelessWidget {
  final Map<String, dynamic> inspection;
  const _InspectionTile({required this.inspection});

  @override
  Widget build(BuildContext context) {
    final health = kVetHealthMeta[inspection['healthStatus']] ?? kVetHealthMeta['HEALTHY']!;
    final docs = List<String>.from(inspection['documentUrls'] as List? ?? []);

    return Container(
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: health.$2.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(health.$3, color: health.$2, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(health.$1, style: AppTypography.body.copyWith(fontWeight: FontWeight.bold, color: health.$2)),
                    Text('Ko\'rik sanasi: ${formatDate(inspection['inspectionDate'])}', style: AppTypography.caption),
                  ],
                ),
              ),
              StatusBadge(status: inspection['status']?.toString() ?? 'PENDING'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(Icons.medical_services_rounded, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Veterinar: ${inspection['vetName'] ?? '-'}'
                  '${(inspection['vetLicenseNo'] ?? '').toString().isNotEmpty ? ' · Litsenziya: ${inspection['vetLicenseNo']}' : ''}',
                  style: AppTypography.caption,
                ),
              ),
            ],
          ),
          if ((inspection['conclusion'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(inspection['conclusion'].toString(), style: AppTypography.bodyMuted),
          ],
          if (docs.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: docs.asMap().entries.map((entry) {
                final isPdf = entry.value.toLowerCase().endsWith('.pdf');
                return _DocumentChip(index: entry.key, url: entry.value, isPdf: isPdf);
              }).toList(),
            ),
          ],
          if ((inspection['adminComment'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Admin izohi: ${inspection['adminComment']}', style: AppTypography.caption),
            ),
          ],
        ],
      ),
    );
  }
}

class _DocumentChip extends StatelessWidget {
  final int index;
  final String url;
  final bool isPdf;

  const _DocumentChip({required this.index, required this.url, required this.isPdf});

  @override
  Widget build(BuildContext context) {
    if (isPdf) {
      // PDFs render poorly inline on mobile; show a labeled chip that opens
      // the URL in the device browser (backend serves public URLs).
      return ActionChip(
        avatar: const Icon(Icons.picture_as_pdf_rounded, size: 16, color: AppColors.danger),
        label: Text('Hujjat ${index + 1} (PDF)'),
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radius)),
              title: const Text('PDF hujjat', style: AppTypography.sectionTitle),
              content: SelectableText(url, style: AppTypography.bodyMuted),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Yopish')),
              ],
            ),
          );
        },
      );
    }
    return InkWell(
      onTap: () => showDialog(
        context: context,
        builder: (_) => Dialog(
          insetPadding: const EdgeInsets.all(AppSpacing.lg),
          child: InteractiveViewer(child: Image.network(url)),
        ),
      ),
      borderRadius: BorderRadius.circular(10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(url, width: 72, height: 72, fit: BoxFit.cover),
      ),
    );
  }
}
