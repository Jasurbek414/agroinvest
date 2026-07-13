import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:agroinvest_mobile/core/constants/app_colors.dart';
import 'package:agroinvest_mobile/core/widgets/document_upload_picker.dart';
import 'package:agroinvest_mobile/core/storage/secure_storage.dart';

class AddCoopOfferSheet extends StatefulWidget {
  final Future<void> Function(Map<String, dynamic> payload) onSubmit;
  final String? preFilledType;
  final String? preFilledTitle;
  final String? preFilledAmount;
  final String? preFilledDescription;

  const AddCoopOfferSheet({
    super.key,
    required this.onSubmit,
    this.preFilledType,
    this.preFilledTitle,
    this.preFilledAmount,
    this.preFilledDescription,
  });

  @override
  State<AddCoopOfferSheet> createState() => _AddCoopOfferSheetState();
}

class _AddCoopOfferSheetState extends State<AddCoopOfferSheet> {
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
  bool _submitting = false;
  List<String> _docUrls = [];

  @override
  void initState() {
    super.initState();
    _formType = widget.preFilledType ?? 'BUSINESS_PLAN';
    _titleController.text = widget.preFilledTitle ?? '';
    _amountController.text = widget.preFilledAmount ?? '';
    _descController.text = widget.preFilledDescription ?? '';
    _loadUserPhone();
  }

  Future<void> _loadUserPhone() async {
    try {
      final userDataStr = await SecureStorage.getUserData();
      if (userDataStr != null) {
        final userData = jsonDecode(userDataStr);
        final phone = userData['phoneNumber']?.toString();
        if (phone != null && phone.isNotEmpty) {
          setState(() {
            _phoneController.text = phone;
          });
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
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
            // Drag Handle Bar
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
            
            // Dropdown selection
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
                  setState(() => _formType = val);
                }
              },
            ),
            const SizedBox(height: 16),

            // Title
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

            // Dynamic fields according to selected category
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

            // Phone
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

            // Description / Terms
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
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.only(bottom: 6.0),
              child: Text('Loyiha hujjatlari (ixtiyoriy)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
            ),
            DocumentUploadPicker(
              category: 'coop',
              urls: _docUrls,
              onChanged: (urls) => setState(() => _docUrls = urls),
            ),
            const SizedBox(height: 24),

            // Submit button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                shadowColor: AppColors.primary.withOpacity(0.2),
              ),
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Tasdiqlash va yuborish', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_titleController.text.isEmpty ||
        _amountController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Iltimos, barcha majburiy maydonlarni to\'ldiring')),
      );
      return;
    }

    setState(() => _submitting = true);

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

    final documentsString = _docUrls.isNotEmpty 
        ? '\n\nHujjatlar:\n' + _docUrls.join('\n') 
        : '';

    try {
      final payload = {
        'title': _titleController.text,
        'description': finalDescription + documentsString,
        'type': _formType,
        'amount': double.tryParse(_amountController.text) ?? 0.0,
        'contactPhone': _phoneController.text,
      };
      
      await widget.onSubmit(payload);
    } catch (_) {
      // Caught inside callbacks
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
