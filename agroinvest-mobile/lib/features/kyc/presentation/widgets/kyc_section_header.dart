import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class KycSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const KycSectionHeader({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.primaryDark, letterSpacing: -0.2),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Divider(color: AppColors.border, thickness: 1.5),
        ),
      ],
    );
  }
}
