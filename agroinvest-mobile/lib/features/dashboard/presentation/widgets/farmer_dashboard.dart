import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/stat_tile.dart';

/// KPI tiles + own-projects feed for the FARMER home tab.
class FarmerDashboard extends StatelessWidget {
  final Map<String, dynamic> data;
  const FarmerDashboard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final projects = List<Map<String, dynamic>>.from(
        (data['projects'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)));
    final reportsDue = (data['reportsDue'] as num?)?.toInt() ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (reportsDue > 0) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radius),
              border: Border.all(color: AppColors.accent.withOpacity(0.3), width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.notification_important_rounded, color: AppColors.accent),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    '$reportsDue ta loyihada hisobot muddati keldi - bugun topshiring!',
                    style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.45,
          children: [
            StatTile(
              icon: Icons.agriculture_rounded,
              color: AppColors.primary,
              label: 'Faol loyihalar',
              value: '${data['activeProjects'] ?? 0} ta',
              sub: '${data['fundingProjects'] ?? 0} ta yig\'ilmoqda',
              onTap: () => context.push('/projects/my'),
            ),
            StatTile(
              icon: Icons.payments_rounded,
              color: AppColors.info,
              label: "Yig'ilgan mablag'",
              value: formatMoneySum(data['totalRaised']),
            ),
            StatTile(
              icon: Icons.receipt_long_rounded,
              color: AppColors.accent,
              label: 'Kutilayotgan harajatlar',
              value: '${data['pendingExpenses'] ?? 0} ta',
            ),
            StatTile(
              icon: Icons.health_and_safety_rounded,
              color: const Color(0xFF8B5CF6),
              label: 'Oxirgi vet ko\'rik',
              value: data['lastVetInspectionAt'] != null ? formatDate(data['lastVetInspectionAt']) : '—',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Loyihalarim', style: AppTypography.sectionTitle),
            TextButton(
              onPressed: () => context.push('/projects/my'),
              child: const Text('Hammasi', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
        if (projects.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radius),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Column(
              children: [
                const Text('Hozircha faol loyihangiz yo\'q', style: AppTypography.bodyMuted),
                const SizedBox(height: AppSpacing.md),
                ElevatedButton(
                  onPressed: () => context.push('/projects/create'),
                  child: const Text('Loyiha yaratish'),
                ),
              ],
            ),
          )
        else
          ...projects.map((p) => _FarmerProjectTile(project: p)),
      ],
    );
  }
}

class _FarmerProjectTile extends StatelessWidget {
  final Map<String, dynamic> project;
  const _FarmerProjectTile({required this.project});

  @override
  Widget build(BuildContext context) {
    final target = (project['targetAmount'] as num?)?.toDouble() ?? 0;
    final raised = (project['raisedAmount'] as num?)?.toDouble() ?? 0;
    final progress = target > 0 ? (raised / target).clamp(0.0, 1.0) : 0.0;
    final reportDue = project['reportDue'] == true;
    final id = project['id']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        border: Border.all(
          color: reportDue ? AppColors.accent.withOpacity(0.5) : AppColors.border,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => context.push('/projects/$id'),
            child: Row(
              children: [
                Expanded(
                  child: Text(project['title']?.toString() ?? '',
                      style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${formatMoney(raised)} / ${formatMoney(target)} so\'m',
            style: AppTypography.caption,
          ),
          if (reportDue) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push('/projects/$id/daily-log'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: BorderSide(color: AppColors.accent.withOpacity(0.5), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                label: const Text('Bugungi hisobotni topshirish', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
