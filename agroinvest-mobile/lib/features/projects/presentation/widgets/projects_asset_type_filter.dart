import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/asset_type_meta.dart';

class ProjectsAssetTypeFilter extends StatelessWidget {
  final String? selectedAssetType;
  final ValueChanged<String?> onChanged;

  const ProjectsAssetTypeFilter({
    super.key,
    required this.selectedAssetType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _AssetTypeChip(
            label: 'Barchasi',
            icon: Icons.apps_rounded,
            color: Colors.green,
            isSelected: selectedAssetType == null,
            onTap: () => onChanged(null),
          ),
          ...kAssetTypeMeta.entries.map(
            (e) => _AssetTypeChip(
              label: e.value.label,
              icon: e.value.icon,
              color: e.value.color,
              isSelected: selectedAssetType == e.key,
              onTap: () => onChanged(e.key),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssetTypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _AssetTypeChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 72,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.5 : 1.2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: isSelected ? AppColors.primary : AppColors.textMuted),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? AppColors.primaryDark : AppColors.textMuted,
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(height: 4),
                Container(
                  width: 14,
                  height: 2.5,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
