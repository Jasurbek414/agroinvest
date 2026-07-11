import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import 'package:intl/intl.dart';

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

  // Universal controllers
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descController = TextEditingController();

  // Dynamic Questionnaire controllers
  final _durationController = TextEditingController(); // months (for Business Plan)
  final _locationController = TextEditingController(); // location (for Business Plan)
  final _sectorController = TextEditingController(); // e.g. Chorvachilik (for Business Plan)
  final _roiController = TextEditingController(); // ROI % (for Investor Offer)
  final _contractTypeController = TextEditingController(); // e.g. Yer ijarasi (for Contract Sale)

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

  String _getOfferTypeLabel(String type) {
    switch (type) {
      case 'CONTRACT_SALE': return 'Tayyor shartnoma savdosi';
      case 'INVESTOR_OFFER': return 'Investor sarmoya taklifi';
      case 'BUSINESS_PLAN': return 'Biznes reja / Loyiha';
      default: return type;
    }
  }

  Color _getOfferTypeColor(String type) {
    switch (type) {
      case 'CONTRACT_SALE': return Colors.blue;
      case 'INVESTOR_OFFER': return Colors.teal;
      case 'BUSINESS_PLAN': return Colors.purple;
      default: return Colors.grey;
    }
  }

  IconData _getOfferTypeIcon(String type) {
    switch (type) {
      case 'CONTRACT_SALE': return Icons.assignment_turned_in_rounded;
      case 'INVESTOR_OFFER': return Icons.monetization_on_rounded;
      case 'BUSINESS_PLAN': return Icons.business_center_rounded;
      default: return Icons.info_outline;
    }
  }

  void _showAddOfferDialog() {
    // Clear old forms
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Yangi e\'lon qo\'shish',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Form Type Selector
                    DropdownButtonFormField<String>(
                      value: _formType,
                      decoration: InputDecoration(
                        labelText: 'E\'lon turi',
                        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

                    // Universal Field: Title
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: _formType == 'BUSINESS_PLAN'
                            ? 'Loyiha / Biznes reja nomi'
                            : _formType == 'INVESTOR_OFFER'
                                ? 'Sarmoya taklifi sarlavhasi'
                                : 'Shartnoma mavzusi',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Universal Field: Amount
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: _formType == 'BUSINESS_PLAN'
                            ? 'Talab qilinadigan summa (UZS)'
                            : _formType == 'INVESTOR_OFFER'
                                ? 'Ajratiladigan investitsiya summasi (UZS)'
                                : 'Shartnomaning sotilish narxi (UZS)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ==========================================
                    // DYNAMIC QUESTIONNAIRE ACCORDING TO TYPE
                    // ==========================================
                    if (_formType == 'BUSINESS_PLAN') ...[
                      // 1. Business Plan Specific Questionnaire
                      TextField(
                        controller: _sectorController,
                        decoration: InputDecoration(
                          labelText: 'Loyiha sohasi (masalan: Chorvachilik, Issiqxona)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          labelText: 'Loyiha amalga oshiriladigan manzil',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _durationController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Loyiha muddati (oylarda)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else if (_formType == 'INVESTOR_OFFER') ...[
                      // 2. Investor Offer Specific Questionnaire
                      TextField(
                        controller: _roiController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Kutilayotgan yillik daromad (ROI %)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else if (_formType == 'CONTRACT_SALE') ...[
                      // 3. Contract Sale Specific Questionnaire
                      TextField(
                        controller: _contractTypeController,
                        decoration: InputDecoration(
                          labelText: 'Shartnoma turi (masalan: Yer ijarasi, Sherikchilik)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Universal Field: Contact Phone
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Aloqa uchun telefon raqami',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Universal Field: Description
                    TextField(
                      controller: _descController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: _formType == 'BUSINESS_PLAN'
                            ? 'Batafsil biznes-reja mazmuni va maqsadlari'
                            : _formType == 'INVESTOR_OFFER'
                                ? 'Hamkorlik shartlari va talablaringiz'
                                : 'Shartnomaning asosiy majburiyatlari va tafsilotlari',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        if (_titleController.text.isEmpty ||
                            _amountController.text.isEmpty ||
                            _phoneController.text.isEmpty ||
                            _descController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Iltimos, asosiy maydonlarni to\'ldiring')),
                          );
                          return;
                        }

                        // Build structured description based on dynamic questionnaire fields
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

    // Filter local listing by search query
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
        title: const Text('Investitsiya bozori', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        actions: [
          IconButton(
            onPressed: _showAddOfferDialog,
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 24),
          ),
        ],
      ),
      body: Column(
        children: [
          // Elegant Search Bar on top
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
                hintText: 'Kalit so\'z bo\'yicha qidirish...',
                hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                fillColor: const Color(0xFFF1F5F9),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildTabButton('ALL', 'Barchasi'),
                  _buildTabButton('BUSINESS_PLAN', 'Biznes Rejalar'),
                  _buildTabButton('INVESTOR_OFFER', 'Investor takliflari'),
                  _buildTabButton('CONTRACT_SALE', 'Tayyor shartnomalar'),
                ],
              ),
            ),
          ),

          // Dynamic Offer Listing
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : filteredOffers.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.folder_open_rounded, size: 48, color: Colors.grey),
                            SizedBox(height: 12),
                            Text(
                              'E\'lonlar topilmadi',
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
                          final isDark = Theme.of(context).brightness == Brightness.dark;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Type Badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: _getOfferTypeColor(o['type']).withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              _getOfferTypeIcon(o['type']),
                                              size: 12,
                                              color: _getOfferTypeColor(o['type']),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              _getOfferTypeLabel(o['type']),
                                              style: TextStyle(
                                                color: _getOfferTypeColor(o['type']),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        o['createdAt']?.toString().substring(0, 10) ?? '',
                                        style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  
                                  // Title
                                  Text(
                                    o['title'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                                  ),
                                  const SizedBox(height: 8),

                                  // Structured text layout with line breaks
                                  Text(
                                    o['description'] ?? '',
                                    style: const TextStyle(color: Colors.black54, fontSize: 12.5, height: 1.45),
                                  ),
                                  const Divider(height: 28, color: Color(0xFFF1F5F9)),

                                  // Footer
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Summa / Qiymat',
                                            style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            amount,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                                          ),
                                        ],
                                      ),
                                      
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFF1F5F9),
                                          foregroundColor: Colors.black87,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        onPressed: () {},
                                        icon: const Icon(Icons.phone_in_talk_rounded, size: 14, color: AppColors.primary),
                                        label: Text(
                                          o['contactPhone'] ?? 'Bog\'lanish',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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

  Widget _buildTabButton(String tabId, String label) {
    final active = _activeTab == tabId;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11,
            color: active ? Colors.white : Colors.black87,
          ),
        ),
        selected: active,
        selectedColor: AppColors.primary,
        backgroundColor: const Color(0xFFF1F5F9),
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _activeTab = tabId;
            });
            _fetchOffers();
          }
        },
      ),
    );
  }
}
