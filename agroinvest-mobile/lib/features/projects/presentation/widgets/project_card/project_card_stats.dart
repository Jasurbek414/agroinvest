import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/format.dart';

/// Single-row stat strip (expected return / duration / minimum investment)
/// on a quiet background - replaces the old card's two bulky boxed tiles
/// while actually showing one more number.
class ProjectCardStats extends StatelessWidget {
  final Map<String, dynamic> project;

  const ProjectCardStats({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final returnPct = project['expectedReturnPct']?.toString() ?? '0';
    final duration = project['durationDays']?.toString() ?? '0';
    final minInvestment = project['minInvestment'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          _StatItem(label: 'Kutilgan foyda', value: '+$returnPct%', valueColor: AppColors.primary),
          const _StatDivider(),
          _StatItem(label: 'Muddati', value: '$duration kun'),
          const _StatDivider(),
          _StatItem(
            label: 'Min. summa',
            value: minInvestment == null ? '—' : formatMoneyCompact(minInvestment),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _StatItem({
    required this.label,
    required this.value,
    this.valueColor = AppColors.textDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: valueColor),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 26, color: AppColors.border);
  }
}
