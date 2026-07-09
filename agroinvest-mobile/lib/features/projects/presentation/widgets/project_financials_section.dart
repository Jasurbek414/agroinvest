import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';

/// Description, farmer-contribution banner, financial metric cards, profit
/// split visualization and funding progress bar for the project detail page.
class ProjectFinancialsSection extends StatelessWidget {
  final Map<String, dynamic> project;
  final double raised;
  final double target;
  final double percent;

  const ProjectFinancialsSection({
    super.key,
    required this.project,
    required this.raised,
    required this.target,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    final p = project;
    final investorSharePct = (p['investorSharePct'] as num?)?.toInt() ?? 70;
    final farmerSharePct = (p['farmerSharePct'] as num?)?.toInt() ?? 30;
    final contributionValue = (p['farmerContributionValue'] as num?)?.toDouble() ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Loyiha tavsifi', style: AppTypography.sectionTitle),
        const SizedBox(height: AppSpacing.sm),
        Text(p['description'] ?? '', style: AppTypography.bodyMuted.copyWith(height: 1.5)),
        const SizedBox(height: AppSpacing.xl),

        if (contributionValue > 0) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppSpacing.radius),
            ),
            child: Row(
              children: [
                const Icon(Icons.agriculture_rounded, color: AppColors.primaryDark),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fermer o\'z hissasini qo\'shdi: ${formatMoneySum(contributionValue)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark),
                      ),
                      if (p['farmerContributionVerifiedAt'] != null)
                        const Text('Admin tomonidan tasdiqlangan ✓', style: AppTypography.caption),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        const Text('Moliyaviy ko\'rsatkichlar', style: AppTypography.sectionTitle),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(child: _MetricCard(label: 'Kutilayotgan foyda', value: '+${p['expectedReturnPct']}%', color: AppColors.primary)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _MetricCard(label: 'Muddati', value: '${p['durationDays']} kun', color: AppColors.textDark)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(child: _MetricCard(label: 'Risk darajasi', value: p['riskLevel'] ?? 'MEDIUM', color: Colors.amber.shade800)),
            Expanded(child: _MetricCard(label: 'Loyiha holati', value: p['status'] ?? 'PENDING', color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),

        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radius),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Sof foyda taqsimoti', style: AppTypography.sectionTitle),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        height: 10,
                        child: Row(
                          children: [
                            Expanded(flex: investorSharePct, child: Container(color: AppColors.primary)),
                            Expanded(flex: farmerSharePct, child: Container(color: AppColors.accent)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text('Investorlar $investorSharePct%', style: AppTypography.caption),
                  ]),
                  Row(children: [
                    Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text('Fermer $farmerSharePct%', style: AppTypography.caption),
                  ]),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radius),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Yig\'ilgan mablag\'', style: AppTypography.bodyMuted),
                  Text(formatMoneySum(raised), style: AppTypography.label),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: percent,
                  backgroundColor: AppColors.background,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${(percent * 100).toStringAsFixed(0)}% moliyalashtirildi', style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold)),
                  Text('Maqsad: ${formatMoneySum(target)}', style: AppTypography.caption),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.caption),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}
