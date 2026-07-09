import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Investor/Farmer role selector shown on the second step of registration.
class RolePickerCards extends StatelessWidget {
  final String selectedRole;
  final ValueChanged<String> onChanged;

  const RolePickerCards({super.key, required this.selectedRole, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _RoleCard(
            selected: selectedRole == 'INVESTOR',
            icon: Icons.trending_up_rounded,
            title: 'Investor',
            subtitle: 'Sarmoya kiritish',
            onTap: () => onChanged('INVESTOR'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _RoleCard(
            selected: selectedRole == 'FARMER',
            icon: Icons.agriculture_rounded,
            title: 'Fermer',
            subtitle: 'Loyiha yaratish',
            onTap: () => onChanged('FARMER'),
          ),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? AppColors.primary : AppColors.textMuted, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: selected ? AppColors.primaryDark : AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: selected ? AppColors.primary.withOpacity(0.8) : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
