import 'package:flutter/material.dart';
import '../../data/models/banner_item.dart';
import 'banner_card.dart';

class MarketBannerCarousel extends StatelessWidget {
  final List<BannerItem> banners;
  final ValueChanged<BannerItem> onTap;

  const MarketBannerCarousel({
    super.key,
    required this.banners,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (banners.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Tavsiya etilgan e\'lonlar',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final item = banners[index];
              return Container(
                width: MediaQuery.of(context).size.width * 0.85,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: BannerCard(item: item, onTap: () => onTap(item)),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
