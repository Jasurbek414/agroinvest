import 'package:flutter/material.dart';
import 'package:agroinvest_mobile/core/constants/app_colors.dart';
import 'package:agroinvest_mobile/core/network/dio_client.dart';
import '../widgets/coop_search_and_tabs.dart';
import '../widgets/coop_offer_card.dart';
import '../widgets/add_coop_offer_sheet.dart';

class CoopMarketPage extends StatefulWidget {
  final String? preFilledType;
  final String? preFilledTitle;
  final String? preFilledAmount;
  final String? preFilledDescription;

  const CoopMarketPage({
    super.key,
    this.preFilledType,
    this.preFilledTitle,
    this.preFilledAmount,
    this.preFilledDescription,
  });

  @override
  State<CoopMarketPage> createState() => _CoopMarketPageState();
}

class _CoopMarketPageState extends State<CoopMarketPage> {
  final _dio = DioClient().dio;
  bool _loading = false;
  String _activeTab = 'ALL'; // 'ALL', 'BUSINESS_PLAN', 'INVESTOR_OFFER', 'CONTRACT_SALE'
  List<dynamic> _offers = [];
  String _searchQuery = '';
  
  // Expanded card tracking
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _fetchOffers();
    if (widget.preFilledTitle != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAddOfferDialog();
      });
    }
  }

  Future<void> _fetchOffers() async {
    if (!mounted) return;
    setState(() => _loading = true);
    
    try {
      final typeParam = _activeTab == 'ALL' ? '' : _activeTab;
      final res = await _dio.get('/coop-offers', queryParameters: {'type': typeParam});
      if (res.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          _offers = res.data['data']['content'] ?? [];
        });
      }
    } catch (e) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Xatolik: e\'lonlarni yuklab bo\'lmadi')),
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _submitNewOffer(Map<String, dynamic> payload) async {
    try {
      final res = await _dio.post('/coop-offers', data: payload);
      if (res.statusCode == 201 || res.statusCode == 200) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('E\'lon yuborildi. Moderator tasdiqlashi kutilmoqda!')),
          );
        }
        _fetchOffers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xatolik: e\'lon joylashda muammo yuz berdi')),
        );
      }
      rethrow;
    }
  }

  void _showAddOfferDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return AddCoopOfferSheet(
          onSubmit: _submitNewOffer,
          preFilledType: widget.preFilledType,
          preFilledTitle: widget.preFilledTitle,
          preFilledAmount: widget.preFilledAmount,
          preFilledDescription: widget.preFilledDescription,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredOffers = _offers.where((o) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final titleMatch = (o['title']?.toString() ?? '').toLowerCase().contains(q);
      final descMatch = (o['description']?.toString() ?? '').toLowerCase().contains(q);
      return titleMatch || descMatch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Investitsiya bozori',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black87, letterSpacing: -0.5),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
        actions: [
          IconButton(
            onPressed: _showAddOfferDialog,
            icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Filter tabs & Search components
          CoopSearchAndTabs(
            activeTab: _activeTab,
            onTabChanged: (tabId) {
              setState(() {
                _activeTab = tabId;
                _expandedIndex = null;
              });
              _fetchOffers();
            },
            onSearchChanged: (val) {
              setState(() => _searchQuery = val);
            },
          ),

          // ListView catalog
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : filteredOffers.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.folder_open_rounded, size: 64, color: Color(0xFFCBD5E1)),
                            SizedBox(height: 16),
                            Text(
                              'Faol e\'lonlar topilmadi',
                              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        physics: const BouncingScrollPhysics(),
                        itemCount: filteredOffers.length,
                        itemBuilder: (context, idx) {
                          final o = filteredOffers[idx];
                          return CoopOfferCard(
                            offer: o,
                            isExpanded: _expandedIndex == idx,
                            onTap: () {
                              setState(() {
                                _expandedIndex = _expandedIndex == idx ? null : idx;
                              });
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
