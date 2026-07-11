import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../wallet/presentation/pages/payment_webview_page.dart';
import '../../data/repositories/services_repository.dart';
import '../../data/models/banner_item.dart';
import '../widgets/market_banner_carousel.dart';
import '../widgets/market_product_card.dart';
import '../widgets/checkout_bottom_sheet.dart';

const List<Map<String, dynamic>> _catalogItems = [
  {
    'id': '1',
    'title': 'Sifatli Press Beda',
    'category': 'FEED',
    'price': 38000.0,
    'unit': 'toy',
    'rating': 4.8,
    'provider': 'Agro-Baza MCHJ',
    'description': 'Toshkent viloyatida yetishtirilgan sifatli ko\'k beda presslangan toylari. Yuqori to\'yimlilik darajasi.',
    'icon': Icons.grass_rounded,
  },
  {
    'id': '2',
    'title': 'Makkajo\'xori don yem',
    'category': 'FEED',
    'price': 3200.0,
    'unit': 'kg',
    'rating': 4.6,
    'provider': 'Yem-Kombinat MCHJ',
    'description': 'Tabiiy va toza makkajo\'xori doni, chorva mollarining semirishi uchun eng ma\'qul ozuqa.',
    'icon': Icons.grain_rounded,
  },
  {
    'id': '3',
    'title': 'Bug\'doy kepagi (Otrub)',
    'category': 'FEED',
    'price': 2600.0,
    'unit': 'kg',
    'rating': 4.5,
    'provider': 'Don-Tashkent LLC',
    'description': 'Sifatli bug\'doy kepagi, oqsil va mineral moddalarga boy.',
    'icon': Icons.bakery_dining_rounded,
  },
  {
    'id': '4',
    'title': 'Qoramol vetchilik ko\'rigi',
    'category': 'VET',
    'price': 150000.0,
    'unit': 'bosh',
    'rating': 4.9,
    'provider': 'VetService MCHJ',
    'description': 'Tajribali veterinar shifokorlar tomonidan chorva mollarining to\'liq profilaktik ko\'rigi va maslahatlar.',
    'icon': Icons.health_and_safety_rounded,
  },
  {
    'id': '5',
    'title': 'Emlash va vaksina xizmati',
    'category': 'VET',
    'price': 15000.0,
    'unit': 'bosh',
    'rating': 4.7,
    'provider': 'BioVet LLC',
    'description': 'Mavsumiy yuqumli kasalliklarga qarshi chorva mollarini sifatli vaksinalar bilan emlash.',
    'icon': Icons.vaccines_rounded,
  },
  {
    'id': '6',
    'title': 'Avtomatik suv idishi',
    'category': 'EQUIPMENT',
    'price': 180000.0,
    'unit': 'dona',
    'rating': 4.6,
    'provider': 'AgroTex MCHJ',
    'description': 'Qoramol va qo\'ylar uchun zanglamaydigan po\'latdan yasalgan avtomatik suv berish idishi.',
    'icon': Icons.water_drop_rounded,
  },
  {
    'id': '7',
    'title': 'Sut sog\'ish uskunasi',
    'category': 'EQUIPMENT',
    'price': 4200000.0,
    'unit': 'dona',
    'rating': 4.8,
    'provider': 'AgroTex MCHJ',
    'description': 'Bir vaqtning o\'zida 2 ta qoramolni sog\'ishga mo\'ljallangan yarim avtomat sut sog\'ish uskunasi.',
    'icon': Icons.electric_bolt_rounded,
  },
];

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
  String _selectedCategory = 'FEED'; // FEED, VET, EQUIPMENT

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
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

  void _showCheckoutSheet(Map<String, dynamic> item, String Function(double) formatAmount) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => CheckoutBottomSheet(item: item, formatAmount: formatAmount),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = _catalogItems.where((element) => element['category'] == _selectedCategory).toList();

    final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String formatAmount(double val) {
      return val.toStringAsFixed(0).replaceAllMapped(formatter, (Match m) => '${m[1]} ') + ' UZS';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Agro Market',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.textDark, letterSpacing: -0.5),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        shape: const Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            // Dynamic Banner Carousel from Backend Banners
            if (!_loading && _error == null && _banners.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: MarketBannerCarousel(banners: _banners, onTap: _openBanner),
                ),
              ),

            // Category Tabs Section
            SliverToBoxAdapter(
              child: _buildCategorySelectionRow(),
            ),

            // Products Grid
            filteredProducts.isEmpty
                ? const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text('Ushbu bo\'limda hozircha mahsulotlar yo\'q', style: TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.all(16.0),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.85,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = filteredProducts[index];
                          return MarketProductCard(
                            item: item,
                            formatAmount: formatAmount,
                            onTap: () => _showCheckoutSheet(item, formatAmount),
                          );
                        },
                        childCount: filteredProducts.length,
                      ),
                    ),
                  ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelectionRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Kategoriyalar',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
          ),
        ),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildCategoryChip('FEED', '🌾 Yem-hashak'),
              _buildCategoryChip('VET', '🩺 Veterinariya'),
              _buildCategoryChip('EQUIPMENT', '🚜 Uskunalar'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String catCode, String label) {
    final isSelected = _selectedCategory == catCode;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedCategory = catCode),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF16A34A) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF16A34A) : AppColors.border,
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
