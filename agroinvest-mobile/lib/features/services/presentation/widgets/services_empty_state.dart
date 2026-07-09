import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ServicesEmptyState extends StatelessWidget {
  const ServicesEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.campaign_outlined, size: 56, color: AppColors.textMuted.withOpacity(0.5)),
            const SizedBox(height: 14),
            const Text(
              "Hozircha e'lon yo'q",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
            ),
            const SizedBox(height: 4),
            const Text(
              "Administratsiya yangi e'lon joylashi bilan shu yerda ko'rinadi.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
