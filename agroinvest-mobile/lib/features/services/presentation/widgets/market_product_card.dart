import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class MarketProductCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final String Function(double) formatAmount;
  final VoidCallback onTap;

  const MarketProductCard({
    super.key,
    required this.item,
    required this.formatAmount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = item['title']?.toString() ?? '';
    final price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
    final unit = item['unit']?.toString() ?? '';
    final provider = item['provider']?.toString() ?? '';
    final rating = double.tryParse(item['rating']?.toString() ?? '5.0') ?? 5.0;
    final IconData icon = item['icon'] as IconData? ?? Icons.storefront_rounded;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Product Icon box + Rating badge
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          icon,
                          size: 40,
                          color: const Color(0xFF16A34A),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 10),
                              const SizedBox(width: 2),
                              Text(
                                rating.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Provider Name
              Text(
                provider,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              // Title
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF1E293B), fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              // Price and Order action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatAmount(price),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF16A34A)),
                        ),
                        Text(
                          '/ $unit',
                          style: const TextStyle(fontSize: 8.5, color: AppColors.textMuted, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF16A34A),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white, size: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
