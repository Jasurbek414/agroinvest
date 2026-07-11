import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/asset_type_meta.dart';

class ProjectCard extends StatelessWidget {
  final Map<String, dynamic> project;
  final VoidCallback onTap;
  final bool isGridView;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    this.isGridView = false,
  });

  String _getRiskLabel(String? level) {
    switch (level?.toUpperCase()) {
      case 'LOW': return 'Past';
      case 'MEDIUM': return 'O\'rta';
      case 'HIGH': return 'Yuqori';
      default: return 'O\'rta';
    }
  }

  Color _getRiskColor(String? level) {
    switch (level?.toUpperCase()) {
      case 'LOW': return Colors.green;
      case 'MEDIUM': return Colors.orange;
      case 'HIGH': return Colors.red;
      default: return Colors.green;
    }
  }

  String formatMoneyCompact(double val) {
    if (val >= 1000000000) {
      return '${(val / 1000000000).toStringAsFixed(1)} mlrd';
    } else if (val >= 1000000) {
      return '${(val / 1000000).toStringAsFixed(1)} mln';
    } else if (val >= 1000) {
      return '${(val / 1000).toStringAsFixed(0)} ming';
    }
    return val.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final raised = double.tryParse(project['raisedAmount'].toString()) ?? 0.0;
    final target = double.tryParse(project['targetAmount'].toString()) ?? 1.0;
    final percent = target <= 0 ? 0.0 : (raised / target).clamp(0.0, 1.0);
    final returnPct = project['expectedReturnPct']?.toString() ?? '0';
    final durationDays = double.tryParse(project['durationDays'].toString()) ?? 0.0;
    final durationMonths = (durationDays / 30).round();
    
    final riskRaw = project['riskLevel']?.toString();
    final riskLabel = _getRiskLabel(riskRaw);
    final riskColor = _getRiskColor(riskRaw);

    final assetType = project['assetType']?.toString() ?? 'OTHER';
    final meta = getAssetTypeMeta(assetType);
    final mediaUrls = (project['mediaUrls'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
    final imageUrl = mediaUrls.isNotEmpty ? mediaUrls.first : null;
    final isInvestorOffer = project['title']?.toString().startsWith('Sarmoya taklifi:') == true ||
        project['description']?.toString().contains('SARMOYA TAKLIFI') == true;

    final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String formatSum(double val) {
      return val.toStringAsFixed(0).replaceAllMapped(formatter, (Match m) => '${m[1]} ') + ' so\'m';
    }

    if (isGridView) {
      return _buildGridLayout(
        context,
        imageUrl,
        meta,
        isInvestorOffer,
        riskLabel,
        riskColor,
        raised,
        target,
        percent,
        returnPct,
        durationMonths,
        formatSum,
      );
    }

    return _buildListLayout(
      context,
      imageUrl,
      meta,
      isInvestorOffer,
      riskLabel,
      riskColor,
      raised,
      target,
      percent,
      returnPct,
      durationMonths,
      formatSum,
    );
  }

  // --- GRID VIEW COMPACT LAYOUT ---
  Widget _buildGridLayout(
    BuildContext context,
    String? imageUrl,
    AssetTypeMeta meta,
    bool isInvestorOffer,
    String riskLabel,
    Color riskColor,
    double raised,
    double target,
    double percent,
    String returnPct,
    int durationMonths,
    String Function(double) formatSum,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.white,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Image Section with overlay tags
                Expanded(
                  flex: 3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      imageUrl != null
                          ? Image.network(imageUrl, fit: BoxFit.cover)
                          : Container(
                              color: meta.color.withOpacity(0.08),
                              child: Icon(meta.icon, color: meta.color, size: 24),
                            ),
                      // Top Left: "Yangi" or "Sarmoya Taklifi" small badge
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isInvestorOffer ? Colors.blue.shade600 : const Color(0xFF16A34A),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isInvestorOffer ? 'TAKLIY' : 'Yangi',
                            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                      // Top Right: Risk badge
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: riskColor.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            riskLabel,
                            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Details Section
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Title
                        Text(
                          project['title']?.toString() ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textDark,
                            height: 1.2,
                          ),
                        ),
                        // Region & Farmer
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              project['region']?.toString() ?? 'O\'zbekiston',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 8.5, color: AppColors.textMuted, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              'Fermer: ${project['farmerName'] ?? 'Oybek Nurmatov'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppColors.textDark),
                            ),
                          ],
                        ),
                        // Simple Divider
                        const Divider(height: 4, color: AppColors.border),
                        // Stats Metrics (compactly arranged)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildGridMetric('Sarmoya', formatMoneyCompact(target)),
                            _buildGridMetric('ROI', '+$returnPct%'),
                            _buildGridMetric('Muddati', '$durationMonths oy'),
                          ],
                        ),
                        // Progress bar row
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Yig\'ilgan: ${formatMoneyCompact(raised)}',
                                  style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                ),
                                Text(
                                  '${(percent * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: AppColors.primary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: percent,
                                minHeight: 3.5,
                                backgroundColor: AppColors.border,
                                valueColor: AlwaysStoppedAnimation<Color>(percent >= 1.0 ? const Color(0xFF16A34A) : AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 7.5, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
        const SizedBox(height: 1),
        Text(value, style: const TextStyle(fontSize: 9.5, color: AppColors.textDark, fontWeight: FontWeight.w900)),
      ],
    );
  }

  // --- LIST VIEW COMPACT LAYOUT (Default horizontal) ---
  Widget _buildListLayout(
    BuildContext context,
    String? imageUrl,
    AssetTypeMeta meta,
    bool isInvestorOffer,
    String riskLabel,
    Color riskColor,
    double raised,
    double target,
    double percent,
    String returnPct,
    int durationMonths,
    String Function(double) formatSum,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.white,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top split section: Image on left, texts & risk on right
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image with overlay
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: imageUrl != null
                                ? Image.network(
                                    imageUrl,
                                    width: 90,
                                    height: 85,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 90,
                                      height: 85,
                                      color: meta.color.withOpacity(0.08),
                                      child: Icon(meta.icon, color: meta.color, size: 24),
                                    ),
                                  )
                                : Container(
                                    width: 90,
                                    height: 85,
                                    color: meta.color.withOpacity(0.08),
                                    child: Icon(meta.icon, color: meta.color, size: 24),
                                  ),
                          ),
                          // Heart button overlay
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.favorite_border_rounded, color: AppColors.textMuted, size: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      // Text Contents
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    project['title']?.toString() ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.textDark,
                                      height: 1.2,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Risk tag box
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: riskColor.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: riskColor.withOpacity(0.12), width: 1),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Xavf',
                                        style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        riskLabel,
                                        style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: riskColor),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Location row
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 11, color: AppColors.textMuted),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    project['region']?.toString() ?? 'O\'zbekiston',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            // Farmer row
                            Row(
                              children: [
                                const Text('Fermer: ', style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                                Text(
                                  project['farmerName']?.toString() ?? 'Oybek Nurmatov',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textDark),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.check_circle, size: 10, color: Color(0xFF16A34A)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Tags row
                            Row(
                              children: [
                                if (isInvestorOffer)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.blue.shade200, width: 1.1),
                                    ),
                                    child: Text(
                                      'SARMOYA TAKLIFI',
                                      style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Colors.blue.shade700),
                                    ),
                                  )
                                else ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Text(
                                      meta.label,
                                      style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: const Text(
                                      'Sut yo\'nalishi',
                                      style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 8),
                  // Metric details row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetricColumn('Kerakli investitsiya', formatSum(target)),
                      _buildMetricColumn('Minimal investitsiya', formatSum(double.tryParse(project['minInvestment'].toString()) ?? 1000000.0)),
                      _buildMetricColumn('Kutilayotgan foyda', '+$returnPct% yillik'),
                      _buildMetricColumn('Loyiha muddati', '$durationMonths oy'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Progress and Details Button Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Yig\'ilgan: ${formatMoneyCompact(raised)} so\'m',
                                  style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                ),
                                Text(
                                  'Qolgan: ${formatMoneyCompact(target - raised)} so\'m',
                                  style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: LinearProgressIndicator(
                                      value: percent,
                                      minHeight: 4,
                                      backgroundColor: AppColors.border,
                                      valueColor: AlwaysStoppedAnimation<Color>(percent >= 1.0 ? const Color(0xFF16A34A) : AppColors.primary),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${(percent * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Batafsil button
                      ElevatedButton(
                        onPressed: onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Batafsil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded, size: 10),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 7.5, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textDark)),
      ],
    );
  }
}
