import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../wallet/presentation/pages/payment_webview_page.dart';
import '../../data/repositories/services_repository.dart';
import '../../data/models/banner_item.dart';
import '../widgets/banner_card.dart';
import '../widgets/services_empty_state.dart';

/// Superadmin-managed announcements feed (real backend data via GET /banners) -
/// previously this tab was a hardcoded fake marketplace with no backend at all.
class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  final _repository = ServicesRepository();
  List<BannerItem> _banners = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final role = Provider.of<AuthProvider>(context, listen: false).user?['role']?.toString();
    final audience = (role == 'INVESTOR' || role == 'FARMER') ? role! : 'ALL';
    try {
      final banners = await _repository.getBanners(audience);
      if (!mounted) return;
      setState(() => _banners = banners);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openBanner(BannerItem item) {
    if (item.linkUrl == null || item.linkUrl!.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Yopish', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
            ),
          ],
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PaymentWebviewPage(checkoutUrl: item.linkUrl!, title: item.title)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Market', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                              "E'lonlarni yuklashda xatolik yuz berdi",
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
                : _banners.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [ServicesEmptyState()],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _banners.length,
                        itemBuilder: (context, index) {
                          final item = _banners[index];
                          return BannerCard(item: item, onTap: () => _openBanner(item));
                        },
                      ),
      ),
    );
  }
}
