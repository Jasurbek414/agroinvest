import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class DashboardGreeting extends StatelessWidget {
  final String name;
  final String role;
  const DashboardGreeting({super.key, required this.name, required this.role});

  @override
  Widget build(BuildContext context) {
    final firstName = name.split(' ').first;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Salom, $firstName 👋', style: AppTypography.h1),
              const SizedBox(height: 4),
              Text(
                role == 'FARMER' ? 'Fermer paneli' : 'Investor paneli',
                style: AppTypography.bodyMuted,
              ),
            ],
          ),
        ),
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primaryLight,
          child: Text(
            firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 18),
          ),
        ),
      ],
    );
  }
}
