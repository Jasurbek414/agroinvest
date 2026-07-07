import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/image_upload_picker.dart';
import '../providers/kyc_provider.dart';

class KycPage extends StatefulWidget {
  const KycPage({super.key});

  @override
  State<KycPage> createState() => _KycPageState();
}

class _KycPageState extends State<KycPage> {
  final _passportController = TextEditingController();
  final _pinflController = TextEditingController();
  DateTime? _birthDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<KycProvider>(context, listen: false).fetchMe();
    });
  }

  @override
  void dispose() {
    _passportController.dispose();
    _pinflController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_passportController.text.trim().isEmpty || _pinflController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pasport raqami va JSHSHIR to'ldirilishi shart"), backgroundColor: AppColors.danger),
      );
      return;
    }
    final provider = Provider.of<KycProvider>(context, listen: false);
    final success = await provider.submit(
      passportNumber: _passportController.text.trim(),
      pinfl: _pinflController.text.trim(),
      birthDate: _birthDate?.toIso8601String().split('T').first,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Hujjatlaringiz tekshiruvga yuborildi' : (provider.error ?? 'Xatolik yuz berdi')),
        backgroundColor: success ? AppColors.primary : AppColors.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<KycProvider>(context);
    final kycStatus = provider.me?['kycStatus'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Shaxsni tasdiqlash (KYC)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textDark,
        centerTitle: true,
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Joriy holat', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                      Text(kycStatus ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (kycStatus == 'VERIFIED')
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text('Hisobingiz allaqachon tasdiqlangan!', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ),
                  )
                else ...[
                  if (kycStatus == 'REJECTED' && provider.me?['kycRejectedReason'] != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                      child: Text('Rad etilish sababi: ${provider.me!['kycRejectedReason']}', style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                    ),
                  TextField(
                    controller: _passportController,
                    decoration: const InputDecoration(labelText: 'Pasport seriya va raqami', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pinflController,
                    decoration: const InputDecoration(labelText: 'JSHSHIR (PINFL)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime(now.year - 25),
                        firstDate: DateTime(1940),
                        lastDate: now,
                      );
                      if (picked != null) setState(() => _birthDate = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: "Tug'ilgan sana", border: OutlineInputBorder()),
                      child: Text(_birthDate == null ? "Tanlanmagan" : _birthDate!.toIso8601String().split('T').first),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pasport hujjatlari (kamera yoki galereyadan)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 10),
                  ImageUploadPicker(
                    category: 'kyc',
                    onChanged: (urls) => Provider.of<KycProvider>(context, listen: false).setDocumentUrls(urls),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: provider.submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(provider.submitting ? 'Yuborilmoqda...' : 'Tasdiqlashga yuborish', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
    );
  }
}
