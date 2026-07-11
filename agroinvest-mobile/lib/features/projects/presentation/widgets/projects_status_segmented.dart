import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Equal-width segmented control for the project lifecycle status
/// (FUNDING / ACTIVE / COMPLETED). Pinned below the header so the primary
/// filter never scrolls out of reach. Replaces the old loose chip row
/// (ProjectsStatusFilter), which visually competed with the asset-type chips
/// right under it.
class ProjectsStatusSegmented extends StatelessWidget {
  final String selectedStatus;
  final ValueChanged<String> onChanged;

  const ProjectsStatusSegmented({
    super.key,
    required this.selectedStatus,
    required this.onChanged,
  });

  static const _options = [
    (value: 'FUNDING', label: 'Mablag\' yig\'ish'),
    (value: 'ACTIVE', label: 'Parvarishda'),
    (value: 'COMPLETED', label: 'Yakunlangan'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        children: _options.map((option) {
          final isSelected = selectedStatus == option.value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(option.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                alignment: Alignment.center,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      option.label,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? Colors.white : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
