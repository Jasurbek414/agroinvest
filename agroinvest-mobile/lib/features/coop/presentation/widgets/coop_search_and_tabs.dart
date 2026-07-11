import 'package:flutter/material.dart';
import 'package:agroinvest_mobile/core/constants/app_colors.dart';

class CoopSearchAndTabs extends StatelessWidget {
  final String activeTab;
  final ValueChanged<String> onTabChanged;
  final ValueChanged<String> onSearchChanged;

  const CoopSearchAndTabs({
    super.key,
    required this.activeTab,
    required this.onTabChanged,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              onChanged: onSearchChanged,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded, color: Colors.grey, size: 22),
                hintText: 'Kalit so\'zlar bo\'yicha qidirish...',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),

        // Horizontal filter tabs
        Container(
          color: Colors.white,
          padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildTab('ALL', 'Barchasi'),
                _buildTab('BUSINESS_PLAN', 'Biznes Rejalar'),
                _buildTab('INVESTOR_OFFER', 'Investor takliflari'),
                _buildTab('CONTRACT_SALE', 'Tayyor shartnomalar'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTab(String tabId, String label) {
    final active = activeTab == tabId;
    return GestureDetector(
      onTap: () => onTabChanged(tabId),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11.5,
            color: active ? Colors.white : const Color(0xFF475569),
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}
