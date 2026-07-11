import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../services/data/models/banner_item.dart';
import '../../../services/data/repositories/services_repository.dart';

class DashboardBannersSlider extends StatefulWidget {
  final String role;
  const DashboardBannersSlider({super.key, required this.role});

  @override
  State<DashboardBannersSlider> createState() => _DashboardBannersSliderState();
}

class _DashboardBannersSliderState extends State<DashboardBannersSlider> {
  final _repository = ServicesRepository();
  final _pageController = PageController();
  List<BannerItem> _banners = [];
  bool _loading = true;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadBanners();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadBanners() async {
    try {
      final list = await _repository.getBanners(widget.role);
      if (mounted) {
        setState(() {
          _banners = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      final total = _getDisplayList().length;
      if (total <= 1) return;
      
      final next = (_currentPage + 1) % total;
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  List<Map<String, String>> _getFallbackBanners() {
    return [
      {
        'title': 'Chorvachilik sarmoyalari\n32% gacha yillik ROI',
        'subtitle': 'O\'zbekiston bo\'ylab chorva mollariga ishonchli sarmoya kiriting',
        'image': 'https://images.unsplash.com/photo-1570042225831-d98fa7577f1e?q=80&w=600&auto=format&fit=crop',
      },
      {
        'title': 'To\'liq sug\'urta kafolati\nxavf-xatarlarsiz investitsiya',
        'subtitle': 'Barcha sotib olingan chorva hayvonlari davlat sug\'urtasidan o\'tkaziladi',
        'image': 'https://images.unsplash.com/photo-1545468117-910a39527f51?q=80&w=600&auto=format&fit=crop',
      },
      {
        'title': 'Elektron shartnomalar\ntezkor va qonuniy rasmiylashtirish',
        'subtitle': 'Telefoningiz orqali shartnomalarni SMS tasdiqlash bilan elektron imzolang',
        'image': 'https://images.unsplash.com/photo-1450133064473-71024230f91b?q=80&w=600&auto=format&fit=crop',
      },
    ];
  }

  List<dynamic> _getDisplayList() {
    return _banners.isNotEmpty ? _banners : _getFallbackBanners();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final displayList = _getDisplayList();

    return Column(
      children: [
        SizedBox(
          height: 165,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (page) => setState(() => _currentPage = page),
            itemCount: displayList.length,
            itemBuilder: (context, index) {
              final item = displayList[index];
              final String title = item is BannerItem ? item.title : item['title']!;
              final String? subtitle = item is BannerItem ? null : item['subtitle'];
              final String imageUrl = item is BannerItem ? item.imageUrl : item['image']!;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Image
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: AppColors.primaryDark,
                          child: const Icon(Icons.broken_image_outlined, color: Colors.white24, size: 40),
                        ),
                      ),
                      // Gradient Overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.75),
                              Colors.black.withOpacity(0.15),
                            ],
                            begin: Alignment.bottomLeft,
                            end: Alignment.topRight,
                          ),
                        ),
                      ),
                      // Text Contents
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                height: 1.3,
                                letterSpacing: -0.2,
                              ),
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                subtitle,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        // Dots indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(displayList.length, (i) {
            final active = i == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}
