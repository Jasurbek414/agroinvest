import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// Co-investors / reports / expenses / vet-inspection link rows, plus the
/// farmer-only quick-action buttons (daily log, add expense).
class ProjectLinksSection extends StatelessWidget {
  final Map<String, dynamic> project;
  final bool isLoggedIn;
  final bool isOwnerFarmer;
  final bool isActiveOrFunding;
  final VoidCallback? onViewInvestors;
  final VoidCallback? onViewReports;
  final VoidCallback? onViewExpenses;
  final VoidCallback? onViewVetInspections;
  final VoidCallback? onViewCoopServices;
  final VoidCallback onDailyLog;
  final VoidCallback onAddExpense;

  const ProjectLinksSection({
    super.key,
    required this.project,
    required this.isLoggedIn,
    required this.isOwnerFarmer,
    required this.isActiveOrFunding,
    required this.onViewInvestors,
    required this.onViewReports,
    required this.onViewExpenses,
    required this.onViewVetInspections,
    required this.onViewCoopServices,
    required this.onDailyLog,
    required this.onAddExpense,
  });

  @override
  Widget build(BuildContext context) {
    final p = project;
    final totalInvestors = p['totalInvestors'] as num? ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LinkRow(
          icon: Icons.groups_rounded,
          label: 'Sherik investorlar',
          trailing: '$totalInvestors ta',
          onTap: isLoggedIn ? onViewInvestors : null,
        ),

        _LinkRow(
          icon: Icons.history_rounded,
          label: 'Hisobotlar tarixi',
          onTap: isLoggedIn ? onViewReports : null,
        ),

        _LinkRow(
          icon: Icons.receipt_long_rounded,
          label: 'Harajatlar',
          onTap: isLoggedIn ? onViewExpenses : null,
        ),

        _LinkRow(
          icon: Icons.health_and_safety_rounded,
          label: 'Veterinar nazorati',
          onTap: isLoggedIn ? onViewVetInspections : null,
        ),

        _LinkRow(
          icon: Icons.handyman_rounded,
          label: 'Qo\'shimcha xizmatlar',
          onTap: isLoggedIn ? onViewCoopServices : null,
        ),
        const SizedBox(height: AppSpacing.xl),

        if (isOwnerFarmer && isActiveOrFunding) ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDailyLog,
                  icon: const Icon(Icons.today_rounded, size: 18),
                  label: const Text('Kunlik hisobot', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAddExpense,
                  icon: const Icon(Icons.add_card_rounded, size: 18),
                  label: const Text('Harajat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ],
    );
  }
}

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback? onTap;

  const _LinkRow({required this.icon, required this.label, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radius),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(label, style: AppTypography.body)),
            if (trailing != null) ...[
              Text(trailing!, style: AppTypography.caption),
              const SizedBox(width: 4),
            ],
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}
