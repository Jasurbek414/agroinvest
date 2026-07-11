import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class InvestmentFilterTabs extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  const InvestmentFilterTabs({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterChip('ALL', 'Barchasi'),
          _buildFilterChip('ACTIVE', 'Faol'),
          _buildFilterChip('PENDING', 'Kutilayotgan'),
          _buildFilterChip('COMPLETED', 'Yakunlangan'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterType, String label) {
    final isSelected = selectedFilter == filterType;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => onFilterChanged(filterType),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: 1.2,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textMuted,
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
