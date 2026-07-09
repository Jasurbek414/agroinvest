import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/banner_item.dart';

class BannerCard extends StatelessWidget {
  final BannerItem item;
  final VoidCallback onTap;

  const BannerCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                item.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.background,
                  child: const Icon(Icons.image_not_supported_outlined, color: AppColors.textMuted, size: 32),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                    ),
                  ),
                  if (item.linkUrl != null) const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
