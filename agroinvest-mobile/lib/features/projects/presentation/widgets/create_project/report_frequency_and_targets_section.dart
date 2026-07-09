import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';

/// Report frequency slider plus the funding target, expected return and
/// duration fields that close out the project application form.
class ReportFrequencyAndTargetsSection extends StatelessWidget {
  final int reportFrequencyDays;
  final ValueChanged<int> onReportFrequencyChanged;
  final TextEditingController targetAmountController;
  final TextEditingController returnPctController;
  final TextEditingController durationController;

  const ReportFrequencyAndTargetsSection({
    super.key,
    required this.reportFrequencyDays,
    required this.onReportFrequencyChanged,
    required this.targetAmountController,
    required this.returnPctController,
    required this.durationController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLabel('Hisobot chastotasi (har necha kunda)'),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: reportFrequencyDays.toDouble(),
                min: 1,
                max: 14,
                divisions: 13,
                activeColor: AppColors.primary,
                label: '$reportFrequencyDays kun',
                onChanged: (val) => onReportFrequencyChanged(val.round()),
              ),
            ),
            SizedBox(
              width: 64,
              child: Text(
                reportFrequencyDays == 1 ? 'Kunlik' : '$reportFrequencyDays kun',
                textAlign: TextAlign.center,
                style: AppTypography.label,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        _buildLabel('Kerakli mablag\' miqdori (UZS)'),
        TextFormField(
          controller: targetAmountController,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
          decoration: const InputDecoration(hintText: 'Minimal: 100 000 UZS'),
          validator: (val) {
            if (val == null || val.isEmpty) return 'Summani kiriting';
            final num = double.tryParse(val);
            if (num == null || num < 100000) return 'Kamida 100 000 UZS kiriting';
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.lg),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildLabel('Kutilayotgan daromad (%)'),
                  TextFormField(
                    controller: returnPctController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
                    decoration: const InputDecoration(hintText: 'Masalan: 35'),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Foizni kiriting';
                      final num = double.tryParse(val);
                      if (num == null || num < 0) return 'Musbat foiz kiriting';
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildLabel('Muddati (Kun)'),
                  TextFormField(
                    controller: durationController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
                    decoration: const InputDecoration(hintText: 'Masalan: 180'),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Kunni kiriting';
                      final num = int.tryParse(val);
                      if (num == null || num < 1) return 'Kamida 1 kun bo\'lishi shart';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(text, style: AppTypography.label),
    );
  }
}
