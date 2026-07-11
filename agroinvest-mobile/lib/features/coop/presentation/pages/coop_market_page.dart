import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class CoopMarketPage extends StatefulWidget {
  const CoopMarketPage({super.key});

  @override
  State<CoopMarketPage> createState() => _CoopMarketPageState();
}

class _CoopMarketPageState extends State<CoopMarketPage> {
  final _dio = DioClient().dio;
  bool _loading = false;
  String _activeTab = 'ALL'; // 'ALL', 'BUSINESS_PLAN', 'INVESTOR_OFFER', 'CONTRACT_SALE'
  List<dynamic> _offers = [];
  String _searchQuery = '';
  
  // Track which card is expanded for premium micro-interactions
  int? _expandedIndex;

  // Universal controllers
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descController = TextEditingController();

  // Dynamic Questionnaire controllers
  final _durationController = TextEditingController();
  final _locationController = TextEditingController();
  final _sectorController = TextEditingController();
  final _roiController = TextEditingController();
  final _contractTypeController = TextEditingController();

  String _formType = 'BUSINESS_PLAN';

  @override
  void initState() {
    super.initState();
    _fetchOffers();
  }

  Future<void> _fetchOffers() async {
    setState(() => _loading = true);
    try {
      final typeParam = _activeTab == 'ALL' ? '' : _activeTab;
      final res = await _dio.get('/coop-offers', queryParameters: {'type': typeParam});
      if (res.statusCode == 200) {
        setState(() {
          _offers = res.data['data']['content'] ?? [];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xatolik: e\'lonlarni yuklab bo\'lmadi')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  String _getOfferTypeLabel(String? type) {
    switch (type) {
      case 'CONTRACT_SALE': return 'Tayyor shartnoma savdosi';
      case 'INVESTOR_OFFER': return 'Investor sarmoya taklifi';
      case 'BUSINESS_PLAN': return 'Biznes reja / Loyiha';
      default: return type ?? 'Boshqa';
    }
  }

  Color _getOfferTypeColor(String? type) {
    switch (type) {
      case 'CONTRACT_SALE': return const Color(0xFF3B82F6);
      case 'INVESTOR_OFFER': return const Color(0xFF10B981);
      case 'BUSINESS_PLAN': return const Color(0xFF8B5CF6);
      default: return Colors.grey;
    }
  }

  IconData _getOfferTypeIcon(String? type) {
    switch (type) {
      case 'CONTRACT_SALE': return Icons.assignment_turned_in_rounded;
      case 'INVESTOR_OFFER': return Icons.monetization_on_rounded;
      case 'BUSINESS_PLAN': return Icons.business_center_rounded;
      default: return Icons.info_outline;
    }
  }

  void _showAddOfferDialog() {
    _titleController.clear();
    _amountController.clear();
    _phoneController.clear();
    _descController.clear();
    _durationController.clear();
    _locationController.clear();
    _sectorController.clear();
    _roiController.clear();
    _contractTypeController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Taklif / Loyiha qo\'shish',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black87, letterSpacing: -0.5),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Dropdown
                    DropdownButtonFormField<String>(
                      value: _formType,
                      decoration: InputDecoration(
                        labelText: 'E\'lon toifasi',
                        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'BUSINESS_PLAN', child: Text('Biznes reja / Loyiha')),
                        DropdownMenuItem(value: 'INVESTOR_OFFER', child: Text('Investor sarmoya taklifi')),
                        DropdownMenuItem(value: 'CONTRACT_SALE', child: Text('Tayyor shartnomalar savdosi')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => _formType = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Title Input
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: _formType == 'BUSINESS_PLAN'
                            ? 'Loyiha / Biznes reja nomi'
                            : _formType == 'INVESTOR_OFFER'
                                ? 'Sarmoya taklifi sarlavhasi'
                                : 'Shartnoma mavzusi',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Amount Input
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: _formType == 'BUSINESS_PLAN'
                            ? 'Talab qilinadigan summa (UZS)'
                            : _formType == 'INVESTOR_OFFER'
                                ? 'Ajratiladigan investitsiya summasi (UZS)'
                                : 'Shartnomaning sotilish narxi (UZS)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Dynamic Fields
                    if (_formType == 'BUSINESS_PLAN') ...[
                      TextField(
                        controller: _sectorController,
                        decoration: InputDecoration(
                          labelText: 'Loyiha sohasi (masalan: Chorvachilik, Issiqxona)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          labelText: 'Loyiha manzili (viloyat, tuman)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _durationController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Loyiha muddati (oylarda)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else if (_formType == 'INVESTOR_OFFER') ...[
                      TextField(
                        controller: _roiController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Kutilayotgan yillik daromad (ROI %)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else if (_formType == 'CONTRACT_SALE') ...[
                      TextField(
                        controller: _contractTypeController,
                        decoration: InputDecoration(
                          labelText: 'Shartnoma turi (masalan: Yer ijarasi, Sherikchilik)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Phone input
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Aloqa uchun telefon raqami',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description Input
                    TextField(
                      controller: _descController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: _formType == 'BUSINESS_PLAN'
                            ? 'Batafsil biznes-reja mazmuni va maqsadlari'
                            : _formType == 'INVESTOR_OFFER'
                                ? 'Hamkorlik shartlari va talablaringiz'
                                : 'Shartnomaning asosiy majburiyatlari va tafsilotlari',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                        shadowColor: AppColors.primary.withOpacity(0.2),
                      ),
                      onPressed: () async {
                        if (_titleController.text.isEmpty ||
                            _amountController.text.isEmpty ||
                            _phoneController.text.isEmpty ||
                            _descController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Iltimos, barcha maydonlarni to\'ldiring')),
                          );
                          return;
                        }

                        String finalDescription = '';
                        if (_formType == 'BUSINESS_PLAN') {
                          finalDescription = 
                              'Sohasi: ${_sectorController.text}\n'
                              'Manzili: ${_locationController.text}\n'
                              'Muddati: ${_durationController.text} oy\n\n'
                              'Batafsil reja: ${_descController.text}';
                        } else if (_formType == 'INVESTOR_OFFER') {
                          finalDescription = 
                              'Kutilayotgan ROI: ${_roiController.text}%\n\n'
                              'Shartlar: ${_descController.text}';
                        } else if (_formType == 'CONTRACT_SALE') {
                          finalDescription = 
                              'Shartnoma turi: ${_contractTypeController.text}\n\n'
                              'Tafsilotlar: ${_descController.text}';
                        }

                        try {
                          final payload = {
                            'title': _titleController.text,
                            'description': finalDescription,
                            'type': _formType,
                            'amount': double.parse(_amountController.text),
                            'contactPhone': _phoneController.text,
                          };
                          
                          final res = await _dio.post('/coop-offers', data: payload);
                          if (res.statusCode == 201 || res.statusCode == 200) {
                            Navigator.pop(context);
                            _fetchOffers();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('E\'lon yuborildi. Moderator tasdiqlashi kutilmoqda!')),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Xatolik: e\'lon joylashda muammo yuz berdi')),
                          );
                        }
                      },
                      child: const Text('Tasdiqlash va yuborish', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'uz_UZ', symbol: 'UZS', decimalDigits: 0);

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
        shape: Border(bottom: BorderSide(color: Colors.grey[150]!, width: 1)),
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
          // Premium top Search panel with soft background
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
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

          // Horizontal selector with high quality active indicators
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildModernTab('ALL', 'Barchasi'),
                  _buildModernTab('BUSINESS_PLAN', 'Biznes Rejalar'),
                  _buildModernTab('INVESTOR_OFFER', 'Investor takliflari'),
                  _buildModernTab('CONTRACT_SALE', 'Tayyor shartnomalar'),
                ],
              ),
            ),
          ),

          // Catalog
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
                          final amount = o['amount'] != null ? currencyFormat.format(o['amount']) : '0 UZS';
                          final isExpanded = _expandedIndex == idx;
                          final accentColor = _getOfferTypeColor(o['type']);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: isExpanded ? accentColor.withOpacity(0.3) : const Color(0xFFF1F5F9),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0F172A).withOpacity(0.03),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(28),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(28),
                                onTap: () {
                                  setState(() {
                                    _expandedIndex = isExpanded ? null : idx;
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Top info row
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: accentColor.withOpacity(0.08),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  _getOfferTypeIcon(o['type']),
                                                  size: 13,
                                                  color: accentColor,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  _getOfferTypeLabel(o['type']),
                                                  style: TextStyle(
                                                    color: accentColor,
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 10,
                                                    letterSpacing: -0.2,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            o['createdAt'] != null && o['createdAt'].toString().length >= 10
                                                ? o['createdAt'].toString().substring(0, 10)
                                                : o['createdAt']?.toString() ?? '',
                                            style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      
                                      // Title text
                                      Text(
                                        o['title'] ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15,
                                          color: Color(0xFF1E293B),
                                          letterSpacing: -0.4,
                                        ),
                                      ),
                                      const SizedBox(height: 8),

                                      // Description body with smooth line clamp expand interaction
                                      Text(
                                        o['description'] ?? '',
                                        maxLines: isExpanded ? 20 : 3,
                                        overflow: isExpanded ? TextOverflow.clip : TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFF475569),
                                          fontSize: 13,
                                          height: 1.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      
                                      // Toggle Indicator
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            isExpanded ? 'Yopish' : 'Batafsil o\'qish',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: accentColor),
                                          ),
                                          Icon(
                                            isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                            size: 16,
                                            color: accentColor,
                                          ),
                                        ],
                                      ),

                                      const Divider(height: 24, color: Color(0xFFF1F5F9), thickness: 1.5),

                                      // Footer info (sum + contact button)
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'TALAB QILINADIGAN SUMMA',
                                                style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w900, letterSpacing: 0.3),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                amount,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 15,
                                                  color: accentColor,
                                                  letterSpacing: -0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                          
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFFF1F5F9),
                                              foregroundColor: const Color(0xFF1E293B),
                                              elevation: 0,
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                            ),
                                            onPressed: () async {
                                              if (o['contactPhone'] != null) {
                                                final launchUri = Uri(
                                                  scheme: 'tel',
                                                  path: o['contactPhone'],
                                                );
                                                await launchUrl(launchUri);
                                              }
                                            },
                                            icon: Icon(Icons.phone_in_talk_rounded, size: 14, color: accentColor),
                                            label: Text(
                                              o['contactPhone'] ?? 'Bog\'lanish',
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTab(String tabId, String label) {
    final active = _activeTab == tabId;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTab = tabId;
          _expandedIndex = null; // collapse on switch
        });
        _fetchOffers();
      },
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
