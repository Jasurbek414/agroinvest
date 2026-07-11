import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/shimmer_loader.dart';
import '../../data/news_repository.dart';

/// SuperAdmin-authored news feed at the bottom of the home dashboard.
/// Hidden entirely while empty so the page doesn't grow a dead section.
class NewsSection extends StatefulWidget {
  const NewsSection({super.key});

  @override
  State<NewsSection> createState() => _NewsSectionState();
}

class _NewsSectionState extends State<NewsSection> {
  final _repository = NewsRepository();
  List<Map<String, dynamic>> _news = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await _repository.fetchNews();
      if (mounted) setState(() => _news = list);
    } catch (_) {
      // News is supplementary - on failure the section just stays hidden.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openDetail(Map<String, dynamic> item) {
    final imageUrl = item['imageUrl']?.toString();
    showModalBottomSheet(
      context: context,
      // Home tab lives in a shell-branch navigator; the root navigator keeps
      // the sheet above the floating bottom nav bar.
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            if (imageUrl != null && imageUrl.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  height: 180,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const ShimmerBox(height: 180, width: double.infinity),
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              item['title']?.toString() ?? '',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textDark, letterSpacing: -0.3, height: 1.3),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.calendar_month_outlined, size: 12, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(formatDate(item['createdAt']), style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              item['body']?.toString() ?? '',
              style: const TextStyle(fontSize: 14, color: AppColors.textDark, fontWeight: FontWeight.w500, height: 1.55),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 8),
        child: ShimmerBox(height: 84, width: double.infinity),
      );
    }
    if (_news.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text('Yangiliklar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        const SizedBox(height: 10),
        ..._news.map((item) => _NewsTile(item: item, onTap: () => _openDetail(item))),
      ],
    );
  }
}

class _NewsTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;

  const _NewsTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final imageUrl = item['imageUrl']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: 68,
                          height: 68,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const ShimmerBox(height: 68, width: 68),
                          errorWidget: (_, __, ___) => Container(
                            width: 68,
                            height: 68,
                            color: AppColors.primaryLight,
                            child: const Icon(Icons.newspaper_rounded, color: AppColors.primary, size: 26),
                          ),
                        )
                      : Container(
                          width: 68,
                          height: 68,
                          color: AppColors.primaryLight,
                          child: const Icon(Icons.newspaper_rounded, color: AppColors.primary, size: 26),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title']?.toString() ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.textDark, height: 1.3),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['body']?.toString() ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatDate(item['createdAt']),
                        style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
