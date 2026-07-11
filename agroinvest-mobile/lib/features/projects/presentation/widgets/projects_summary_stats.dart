import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ProjectsSummaryStats extends StatelessWidget {
  final int totalCount;
  final int activeCount;
  final int fundingCount;
  final int completedCount;

  const ProjectsSummaryStats({
    super.key,
    required this.totalCount,
    required this.activeCount,
    required this.fundingCount,
    required this.completedCount,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildStatCard(
            icon: Icons.grid_view_rounded,
            iconColor: Colors.green,
            label: 'Jami loyihalar',
            value: '$totalCount',
            changeText: '↑ 12.5%',
            changeColor: Colors.green,
          ),
          _buildStatCard(
            icon: Icons.business_center_rounded,
            iconColor: Colors.amber,
            label: 'Faol loyihalar',
            value: '$activeCount',
            changeText: '↑ 8.2%',
            changeColor: Colors.green,
          ),
          _buildStatCard(
            icon: Icons.account_balance_wallet_rounded,
            iconColor: Colors.blue,
            label: 'Investitsiya yig\'ilmoqda',
            value: '$fundingCount',
            changeText: '↑ 15.3%',
            changeColor: Colors.blue,
          ),
          _buildStatCard(
            icon: Icons.check_circle_rounded,
            iconColor: Colors.purple,
            label: 'Yakunlangan loyihalar',
            value: '$completedCount',
            changeText: '↑ 5.6%',
            changeColor: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String changeText,
    required Color changeColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppColors.textMuted),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    value,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.textDark),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    changeText,
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: changeColor),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
