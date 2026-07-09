import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';

/// Who covers ongoing expenses (feed, medicine, transport) during the project.
class ExpensePolicySection extends StatelessWidget {
  final String expensePolicy;
  final ValueChanged<String> onChanged;

  const ExpensePolicySection({super.key, required this.expensePolicy, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Joriy harajatlar siyosati', style: AppTypography.sectionTitle),
          const SizedBox(height: 4),
          const Text('Yem, dori, transport kabi harajatlarni kim ko\'taradi?', style: AppTypography.caption),
          const SizedBox(height: AppSpacing.md),
          _ExpensePolicyOption(
            selected: expensePolicy == 'INVESTOR_BUDGET',
            title: 'Loyiha byudjetidan',
            subtitle: 'Yig\'ilgan mablag\' ichidan, shaffof hisobda',
            onTap: () => onChanged('INVESTOR_BUDGET'),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ExpensePolicyOption(
            selected: expensePolicy == 'FARMER_REIMBURSED',
            title: 'O\'zim to\'layman',
            subtitle: 'Sotuvdan keyin, foyda bo\'linishidan OLDIN qaytariladi',
            onTap: () => onChanged('FARMER_REIMBURSED'),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ExpensePolicyOption(
            selected: expensePolicy == 'MIXED',
            title: 'Aralash',
            subtitle: 'Har bir harajatda alohida belgilayman',
            onTap: () => onChanged('MIXED'),
          ),
        ],
      ),
    );
  }
}

class _ExpensePolicyOption extends StatelessWidget {
  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ExpensePolicyOption({required this.selected, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: selected ? AppColors.primaryDark : AppColors.textDark,
                  )),
                  Text(subtitle, style: AppTypography.caption),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
