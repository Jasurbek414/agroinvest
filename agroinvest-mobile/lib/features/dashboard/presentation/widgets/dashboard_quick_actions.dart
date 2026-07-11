import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';

class DashboardQuickActions extends StatelessWidget {
  const DashboardQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tezkor Xizmatlar',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.primaryDark, letterSpacing: -0.2),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildActionButton(
                context: context,
                icon: Icons.grid_view_rounded,
                label: 'Loyihalar',
                color: Colors.blue,
                onTap: () => context.go('/projects'),
              ),
              _buildActionButton(
                context: context,
                icon: Icons.account_balance_wallet_outlined,
                label: 'Hamyon',
                color: Colors.orange,
                onTap: () => context.push('/wallet'),
              ),
              _buildActionButton(
                context: context,
                icon: Icons.verified_user_outlined,
                label: 'KYC',
                color: Colors.green,
                onTap: () => context.push('/kyc'),
              ),
              _buildActionButton(
                context: context,
                icon: Icons.headset_mic_outlined,
                label: 'Yordam',
                color: Colors.purple,
                onTap: () => context.push('/profile/help'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 64,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.12), width: 1.5),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
