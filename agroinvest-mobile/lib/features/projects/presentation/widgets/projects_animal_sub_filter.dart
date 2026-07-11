import 'package:flutter/material.dart';
import '../../../../core/constants/animal_type_meta.dart';
import '../../../../core/constants/app_colors.dart';

/// Secondary emoji chip row for animal types - only rendered when the
/// LIVESTOCK or POULTRY asset filter is active (the page animates it in/out
/// with AnimatedSize).
class ProjectsAnimalSubFilter extends StatelessWidget {
  final String? selectedAnimalType;
  final ValueChanged<String?> onChanged;

  const ProjectsAnimalSubFilter({
    super.key,
    required this.selectedAnimalType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SizedBox(
        height: 34,
        child: ListView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _AnimalTypeChip(
              label: 'Barcha turlar',
              isSelected: selectedAnimalType == null,
              onTap: () => onChanged(null),
            ),
            ...kAnimalTypeMeta.entries.map(
              (e) => _AnimalTypeChip(
                label: '${e.value.emoji} ${e.value.label}',
                isSelected: selectedAnimalType == e.key,
                onTap: () => onChanged(e.key),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimalTypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _AnimalTypeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryLight : Colors.white,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primaryDark : AppColors.textMuted,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
