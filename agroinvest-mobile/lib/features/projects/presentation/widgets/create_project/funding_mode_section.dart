import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';

/// "How will the animals/assets be financed" card: investor-funded /
/// farmer-assets / mixed options, plus the contribution value+notes fields
/// shown when the farmer contributes their own assets.
class FundingModeSection extends StatelessWidget {
  final String fundingMode;
  final bool hasContribution;
  final TextEditingController contributionValueController;
  final TextEditingController contributionNotesController;
  final ValueChanged<String> onFundingModeChanged;

  const FundingModeSection({
    super.key,
    required this.fundingMode,
    required this.hasContribution,
    required this.contributionValueController,
    required this.contributionNotesController,
    required this.onFundingModeChanged,
  });

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
          const Text('Moliyalashtirish usuli', style: AppTypography.sectionTitle),
          const SizedBox(height: 4),
          const Text(
            'Hayvonlarni investor puliga sotib olasizmi yoki o\'zingizniki bilan kirasizmi?',
            style: AppTypography.caption,
          ),
          const SizedBox(height: AppSpacing.md),
          _FundingModeOption(
            selected: fundingMode == 'INVESTOR_FUNDED',
            icon: Icons.account_balance_rounded,
            title: 'To\'liq investor puliga',
            subtitle: 'Barcha hayvonlar yig\'ilgan mablag\'ga sotib olinadi',
            onTap: () => onFundingModeChanged('INVESTOR_FUNDED'),
          ),
          const SizedBox(height: AppSpacing.sm),
          _FundingModeOption(
            selected: fundingMode == 'FARMER_ASSETS',
            icon: Icons.agriculture_rounded,
            title: 'O\'z hayvonlarim bilan',
            subtitle: 'Mavjud hayvonlarimni loyihaga qo\'shaman (admin tasdiqlaydi)',
            onTap: () => onFundingModeChanged('FARMER_ASSETS'),
          ),
          const SizedBox(height: AppSpacing.sm),
          _FundingModeOption(
            selected: fundingMode == 'MIXED',
            icon: Icons.call_split_rounded,
            title: 'Aralash',
            subtitle: 'Qisman o\'zim, qisman investor mablag\'i',
            onTap: () => onFundingModeChanged('MIXED'),
          ),
          if (hasContribution) ...[
            const SizedBox(height: AppSpacing.lg),
            _buildLabel('Mening hissam qiymati (so\'m)'),
            TextFormField(
              controller: contributionValueController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(hintText: '5 000 000'),
              validator: (val) => hasContribution && (val == null || double.tryParse(val) == null || double.parse(val) <= 0)
                  ? 'Hissa qiymatini kiriting'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildLabel('Izoh (necha bosh, qanday holatda)'),
            TextFormField(
              controller: contributionNotesController,
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'Masalan: 10 ta sog\'lom qo\'y, 8 oylik'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(text, style: AppTypography.label),
    );
  }
}

class _FundingModeOption extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FundingModeOption({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

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
            Icon(icon, color: selected ? AppColors.primary : AppColors.textMuted, size: 20),
            const SizedBox(width: AppSpacing.md),
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
