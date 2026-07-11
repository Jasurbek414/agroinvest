import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class CheckoutBottomSheet extends StatefulWidget {
  final Map<String, dynamic> item;
  final String Function(double) formatAmount;

  const CheckoutBottomSheet({
    super.key,
    required this.item,
    required this.formatAmount,
  });

  @override
  State<CheckoutBottomSheet> createState() => _CheckoutBottomSheetState();
}

class _CheckoutBottomSheetState extends State<CheckoutBottomSheet> {
  int _quantity = 1;
  bool _submitting = false;
  bool _success = false;

  final _phoneController = TextEditingController(text: '+998 ');
  final _addressController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.item['title']?.toString() ?? '';
    final price = double.tryParse(widget.item['price']?.toString() ?? '0') ?? 0.0;
    final unit = widget.item['unit']?.toString() ?? '';
    final provider = widget.item['provider']?.toString() ?? '';
    final total = price * _quantity;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 24,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _success
            ? _buildSuccessView()
            : _buildFormView(title, price, unit, provider, total),
      ),
    );
  }

  Widget _buildFormView(String title, double price, String unit, String provider, double total) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Buyurtma berish',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Product Info Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Row(
            children: [
              Icon(widget.item['icon'] as IconData? ?? Icons.storefront_rounded, color: const Color(0xFF16A34A), size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Yetkazib beruvchi: $provider',
                      style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Quantity Selector
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Miqdori:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                  icon: const Icon(Icons.remove_circle_outline_rounded, size: 22),
                  color: const Color(0xFF16A34A),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$_quantity $unit',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF1E293B)),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _quantity++),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 22),
                  color: const Color(0xFF16A34A),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Contact details form
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13),
          decoration: InputDecoration(
            labelText: 'Telefon raqam',
            labelStyle: const TextStyle(fontSize: 12),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.2),
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _addressController,
          style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13),
          decoration: InputDecoration(
            labelText: 'Yetkazib berish manzili / Sharh',
            labelStyle: const TextStyle(fontSize: 12),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.2),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Total price row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Umumiy qiymat:', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
            Text(
              widget.formatAmount(total),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF16A34A)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Order button
        ElevatedButton(
          onPressed: _submitting ? null : _submitOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF16A34A),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _submitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Buyurtmani tasdiqlash', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        const Center(
          child: Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF16A34A),
            size: 64,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Buyurtmangiz qabul qilindi!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 8),
        const Text(
          'Yaqin daqiqalar ichida buyurtmangizni va yetkazib berish shartlarini tasdiqlash uchun operatorimiz siz bilan bog\'lanadi.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11.5, color: AppColors.textMuted, height: 1.4, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF16A34A),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Tushunarli', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Future<void> _submitOrder() async {
    setState(() => _submitting = true);
    // Simulate API request delay
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _submitting = false;
        _success = true;
      });
    }
  }
}
