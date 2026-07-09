import 'package:flutter/material.dart';
import '../../../../core/constants/animal_type_meta.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/asset_type_meta.dart';
import '../../../../core/theme/app_theme.dart';

/// Top banner card on the project detail page: asset/animal type tags, title,
/// farmer name + verified badge + region, and (if rated) a tappable rating row
/// that opens the farmer's full reviews page.
class ProjectHeaderCard extends StatelessWidget {
  final Map<String, dynamic> project;
  final VoidCallback? onViewFarmerReviews;

  const ProjectHeaderCard({super.key, required this.project, this.onViewFarmerReviews});

  @override
  Widget build(BuildContext context) {
    final p = project;
    final assetType = p['assetType']?.toString() ?? 'OTHER';
    final meta = getAssetTypeMeta(assetType);
    final animalType = p['animalType']?.toString();
    final farmerRating = double.tryParse(p['farmerRating']?.toString() ?? '0') ?? 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Tag(icon: meta.icon, label: meta.label, color: meta.color),
              if (animalType != null) ...[
                const SizedBox(width: 8),
                _Tag(
                  emoji: getAnimalTypeMeta(animalType).emoji,
                  label: getAnimalTypeMeta(animalType).label,
                  color: getAnimalTypeMeta(animalType).color,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(p['title'] ?? '', style: AppTypography.h2),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(p['farmerName'] ?? 'Noma\'lum fermer', style: AppTypography.label),
              if (p['farmerVerified'] == true) ...[
                const SizedBox(width: 4),
                const Icon(Icons.verified_rounded, size: 15, color: AppColors.primary),
              ],
              const SizedBox(width: 14),
              const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(p['region'] ?? 'O\'zbekiston', style: AppTypography.label),
            ],
          ),
          if (farmerRating > 0) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onViewFarmerReviews,
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, size: 15, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(farmerRating.toStringAsFixed(1), style: AppTypography.label),
                  const SizedBox(width: 8),
                  Text('· ${p['farmerTotalProjects'] ?? 0} ta yakunlangan loyiha', style: AppTypography.caption),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textMuted),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final IconData? icon;
  final String? emoji;
  final String label;
  final Color color;

  const _Tag({this.icon, this.emoji, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, size: 13, color: color),
          if (emoji != null) Text(emoji!, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
