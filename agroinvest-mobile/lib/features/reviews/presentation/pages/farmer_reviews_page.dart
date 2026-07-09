import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import '../../data/review_repository.dart';

/// Dedicated farmer-reputation feed (TZ F-9.2), reached from a project's
/// star-rating row - previously reviews only existed as a bottom sheet buried
/// inside "Sarmoyalarim" (my_investments_page.dart) with no way to browse them.
class FarmerReviewsPage extends StatefulWidget {
  final String farmerId;
  final String? farmerName;

  const FarmerReviewsPage({super.key, required this.farmerId, this.farmerName});

  @override
  State<FarmerReviewsPage> createState() => _FarmerReviewsPageState();
}

class _FarmerReviewsPageState extends State<FarmerReviewsPage> {
  final _repository = ReviewRepository();
  List<dynamic> _reviews = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final reviews = await _repository.getFarmerReviews(widget.farmerId);
      if (!mounted) return;
      setState(() => _reviews = reviews);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.farmerName ?? 'Fermer sharhlari', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textDark,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _error != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            const Text(
                              "Sharhlarni yuklashda xatolik yuz berdi",
                              style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(onPressed: _load, child: const Text('Qayta urinish')),
                          ],
                        ),
                      ),
                    ],
                  )
                : _reviews.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(48),
                            child: Column(
                              children: [
                                Icon(Icons.rate_review_outlined, size: 48, color: AppColors.textMuted),
                                SizedBox(height: 12),
                                Text('Bu fermer uchun hali sharh yo\'q', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _reviews.length,
                        itemBuilder: (context, index) {
                          final r = _reviews[index] as Map<String, dynamic>;
                          final rating = (r['rating'] as num?)?.toInt() ?? 0;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border, width: 1.5),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(r['investorName']?.toString() ?? '', style: AppTypography.label),
                                    Row(
                                      children: List.generate(
                                        5,
                                        (i) => Icon(
                                          Icons.star_rounded,
                                          size: 16,
                                          color: i < rating ? Colors.amber : AppColors.border,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if ((r['comment']?.toString() ?? '').isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(r['comment'].toString(), style: AppTypography.bodyMuted),
                                ],
                                const SizedBox(height: 8),
                                Text(
                                  '${r['projectTitle'] ?? ''} · ${formatDate(r['createdAt'])}',
                                  style: AppTypography.caption,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
