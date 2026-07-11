import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class DashboardGreeting extends StatelessWidget {
  final String name;
  final String role;
  const DashboardGreeting({super.key, required this.name, required this.role});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final avatarUrl = auth.user?['avatarUrl'];
    final firstName = name.split(' ').first;

    const textColor = AppColors.textDark;

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.menu_rounded, color: textColor, size: 24),
          onPressed: () => Scaffold.of(context).openDrawer(),
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.only(right: 12),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Salom, $firstName 👋',
                style: AppTypography.h1.copyWith(color: textColor),
              ),
              const SizedBox(height: 4),
              Text(
                role == 'FARMER' ? 'Fermer paneli' : 'Investor paneli',
                style: AppTypography.bodyMuted.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.storefront_rounded, color: Color(0xFF16A34A), size: 24),
          onPressed: () => context.push('/services'),
          tooltip: 'Market',
        ),
        const SizedBox(width: 8),
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primaryLight,
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
          child: avatarUrl == null
              ? Text(
                  firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 18),
                )
              : null,
        ),
      ],
    );
  }
}
