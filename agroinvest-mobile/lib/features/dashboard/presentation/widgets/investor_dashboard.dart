import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/asset_type_meta.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/stat_tile.dart';

/// KPI tiles + portfolio breakdown + recent reports feed for the INVESTOR home tab.
class InvestorDashboard extends StatelessWidget {
  final Map<String, dynamic> data;
  const InvestorDashboard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final breakdown = Map<String, dynamic>.from(data['assetTypeBreakdown'] ?? {});
    final reports = List<Map<String, dynamic>>.from(
        (data['recentReports'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.45,
          children: [
            StatTile(
              icon: Icons.account_balance_wallet_rounded,
              color: AppColors.primary,
              label: 'Portfel qiymati',
              value: formatMoneySum(data['portfolioValue']),
              onTap: () => context.push('/investments'),
            ),
            StatTile(
              icon: Icons.trending_up_rounded,
              color: AppColors.info,
              label: 'Kutilayotgan qaytim',
              value: formatMoneySum(data['expectedPayout']),
              sub: 'kafolatlanmagan',
            ),
            StatTile(
              icon: Icons.savings_rounded,
              color: AppColors.accent,
              label: 'Jami daromad',
              value: formatMoneySum(data['totalEarned']),
            ),
            StatTile(
              icon: Icons.workspaces_rounded,
              color: const Color(0xFF8B5CF6),
              label: 'Faol investitsiyalar',
              value: '${data['activeInvestments'] ?? 0} ta',
              onTap: () => context.push('/investments'),
            ),
          ],
        ),
        if (breakdown.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          const Text('Portfel taqsimoti', style: AppTypography.sectionTitle),
          const SizedBox(height: AppSpacing.md),
          _AssetBreakdownCard(breakdown: breakdown),
        ],
        const SizedBox(height: AppSpacing.xl),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("So'nggi hisobotlar", style: AppTypography.sectionTitle),
            TextButton(
              onPressed: () => context.go('/projects'),
              child: const Text('Loyihalar', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
        if (reports.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radius),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: const Center(
              child: Text('Hozircha hisobotlar yo\'q', style: AppTypography.bodyMuted),
            ),
          )
        else
          ...reports.map((r) => _RecentReportTile(report: r)),
      ],
    );
  }
}

/// Labeled breakdown rows (colored dot + label + count) - identity is carried
/// by label text, the dot echoes the platform-wide asset-type entity colors.
class _AssetBreakdownCard extends StatelessWidget {
  final Map<String, dynamic> breakdown;
  const _AssetBreakdownCard({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final total = breakdown.values.fold<num>(0, (sum, v) => sum + (v as num));
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        children: breakdown.entries.map((entry) {
          final meta = getAssetTypeMeta(entry.key);
          final count = entry.value as num;
          final fraction = total > 0 ? count / total : 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(meta.icon, size: 16, color: meta.color),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(width: 110, child: Text(meta.label, style: AppTypography.bodyMuted)),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: fraction.toDouble(),
                      minHeight: 8,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation(meta.color),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text('$count ta', style: AppTypography.label),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RecentReportTile extends StatelessWidget {
  final Map<String, dynamic> report;
  const _RecentReportTile({required this.report});

  @override
  Widget build(BuildContext context) {
    final isEmergency = report['reportType'] == 'EMERGENCY';
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: ListTile(
        onTap: () => context.push('/projects/${report['projectId']}'),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (isEmergency ? AppColors.danger : AppColors.primary).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isEmergency ? Icons.warning_amber_rounded : Icons.description_rounded,
            color: isEmergency ? AppColors.danger : AppColors.primary,
            size: 20,
          ),
        ),
        title: Text(report['projectTitle']?.toString() ?? '', style: AppTypography.body, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${isEmergency ? 'Favqulodda' : 'Hisobot'} · ${formatDateTime(report['createdAt'])}',
          style: AppTypography.caption,
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
      ),
    );
  }
}
