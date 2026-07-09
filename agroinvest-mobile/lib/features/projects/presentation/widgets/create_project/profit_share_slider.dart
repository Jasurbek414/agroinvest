import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';

/// Negotiated net-profit split slider between the investor pool and the farmer.
class ProfitShareSlider extends StatelessWidget {
  final double investorSharePct;
  final double minSharePct;
  final double maxSharePct;
  final ValueChanged<double> onChanged;

  const ProfitShareSlider({
    super.key,
    required this.investorSharePct,
    required this.minSharePct,
    required this.maxSharePct,
    required this.onChanged,
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
          const Text('Foyda taqsimoti (kelishuv)', style: AppTypography.sectionTitle),
          const SizedBox(height: 4),
          Text(
            'Sof foydadan investorlar jamoasiga qancha ulush taklif qilasiz? (${minSharePct.toInt()}%–${maxSharePct.toInt()}%)',
            style: AppTypography.caption,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SharePill(label: 'Investorlar', value: investorSharePct.toInt(), color: AppColors.primary),
              const Icon(Icons.swap_horiz_rounded, color: AppColors.textMuted, size: 18),
              _SharePill(label: 'Fermer', value: 100 - investorSharePct.toInt(), color: AppColors.accent),
            ],
          ),
          Slider(
            value: investorSharePct,
            min: minSharePct,
            max: maxSharePct,
            divisions: (maxSharePct - minSharePct).toInt().clamp(1, 100),
            activeColor: AppColors.primary,
            label: '${investorSharePct.toInt()}%',
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SharePill extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _SharePill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$value%', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
        Text(label, style: AppTypography.caption),
      ],
    );
  }
}
