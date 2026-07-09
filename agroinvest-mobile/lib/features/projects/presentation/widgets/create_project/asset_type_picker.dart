import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/constants/animal_type_meta.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/asset_type_meta.dart';
import '../../../../../core/theme/app_theme.dart';

const List<Map<String, String>> kRiskLevels = [
  {'label': 'Past', 'value': 'LOW'},
  {'label': 'O\'rta', 'value': 'MEDIUM'},
  {'label': 'Yuqori', 'value': 'HIGH'},
];

/// Asset type + risk level chips, and (for LIVESTOCK/POULTRY projects) the
/// animal subtype chips plus headcount/price-per-head fields.
class AssetTypePicker extends StatelessWidget {
  final String selectedAssetType;
  final String selectedRiskLevel;
  final String? selectedAnimalType;
  final bool isAnimalProject;
  final TextEditingController headcountController;
  final TextEditingController pricePerHeadController;
  final ValueChanged<String> onAssetTypeChanged;
  final ValueChanged<String> onRiskLevelChanged;
  final ValueChanged<String> onAnimalTypeChanged;

  const AssetTypePicker({
    super.key,
    required this.selectedAssetType,
    required this.selectedRiskLevel,
    required this.selectedAnimalType,
    required this.isAnimalProject,
    required this.headcountController,
    required this.pricePerHeadController,
    required this.onAssetTypeChanged,
    required this.onRiskLevelChanged,
    required this.onAnimalTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLabel('Aktiv turi'),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: kAssetTypeMeta.entries.map((entry) {
            final selected = selectedAssetType == entry.key;
            return ChoiceChip(
              selected: selected,
              onSelected: (_) => onAssetTypeChanged(entry.key),
              avatar: Icon(entry.value.icon, size: 16, color: selected ? entry.value.color : AppColors.textMuted),
              label: Text(entry.value.label),
              showCheckmark: false,
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.lg),

        _buildLabel('Xavf darajasi'),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: kRiskLevels.map((r) {
            final selected = selectedRiskLevel == r['value'];
            return ChoiceChip(
              selected: selected,
              onSelected: (_) => onRiskLevelChanged(r['value']!),
              label: Text(r['label']!),
              showCheckmark: false,
            );
          }).toList(),
        ),

        if (isAnimalProject) ...[
          const SizedBox(height: AppSpacing.lg),
          _buildLabel('Hayvon turi'),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: kAnimalTypeMeta.entries.map((entry) {
              final selected = selectedAnimalType == entry.key;
              return ChoiceChip(
                selected: selected,
                onSelected: (_) => onAnimalTypeChanged(entry.key),
                avatar: Text(entry.value.emoji, style: const TextStyle(fontSize: 14)),
                label: Text(entry.value.label),
                showCheckmark: false,
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildLabel('Bosh soni'),
                    TextFormField(
                      controller: headcountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(hintText: '50'),
                      validator: (val) => isAnimalProject && (val == null || int.tryParse(val) == null || int.parse(val) < 1)
                          ? 'Kiriting'
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildLabel('Bir bosh narxi (so\'m)'),
                    TextFormField(
                      controller: pricePerHeadController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(hintText: '1 500 000'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
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
