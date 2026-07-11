import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

  final _titleController = TextEditingController();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
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
        SnackBar(content: Text('Xatolik: e\'lonlarni yuklab bo\'lmadi')),
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

  void _showAddOfferDialog() {
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
            return Padding(
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
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _formType,
                      decoration: const InputDecoration(
                        labelText: 'E\'lon turi',
                        border: OutlineInputBorder(),
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
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Sarlavha',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Talab qilinadigan summa (UZS)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Telefon raqam',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _descController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Tavsif va batafsil reja',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
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
                            const SnackBar(content: Text('Iltimos, barcha maydonlarni to\'ldiring')),
                          );
                          return;
                        }
                        try {
                          final payload = {
                            'title': _titleController.text,
                            'description': _descController.text,
                            'type': _formType,
                            'amount': double.parse(_amountController.text),
                            'contactPhone': _phoneController.text,
                          };
                          final res = await _dio.post('/coop-offers', data: payload);
                          if (res.statusCode == 201 || res.statusCode == 200) {
                            Navigator.pop(context);
                            _titleController.clear();
                            _amountController.clear();
                            _phoneController.clear();
                            _descController.clear();
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
                      child: const Text('Tasdiqlash va yuborish', style: TextStyle(fontWeight: FontWeight.bold)),
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
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
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

          // Catalog list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _offers.isEmpty
                    ? const Center(
                        child: Text(
                          'Ushbu bo\'limda hozircha faol e\'lonlar yo\'q',
                          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _offers.length,
                        itemBuilder: (context, idx) {
                          final o = _offers[idx];
                          final amount = o['amount'] != null ? currencyFormat.format(o['amount']) : '0 UZS';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getOfferTypeColor(o['type']).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          _getOfferTypeLabel(o['type']),
                                          style: TextStyle(
                                            color: _getOfferTypeColor(o['type']),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        o['createdAt']?.toString().substring(0, 10) ?? '',
                                        style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    o['title'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    o['description'] ?? '',
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                  const Divider(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Summa',
                                            style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            amount,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                                          ),
                                        ],
                                      ),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey[100],
                                          foregroundColor: Colors.black87,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        label: Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: active ? Colors.white : Colors.black87)),
        selected: active,
        selectedColor: AppColors.primary,
        backgroundColor: Colors.grey[100],
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
