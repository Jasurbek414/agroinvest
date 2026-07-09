import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/image_upload_picker.dart';
import '../providers/wallet_provider.dart';

/// Manual top-up request form: real Payme/Click gateway integration is dormant
/// (no merchant credentials configured), so for now the user declares an amount
/// and optionally attaches a bank-transfer receipt photo - staff then reviews it
/// in the web admin's "To'lov so'rovlari" queue before the wallet is credited.
class DepositBottomSheet extends StatefulWidget {
  const DepositBottomSheet({super.key});

  @override
  State<DepositBottomSheet> createState() => _DepositBottomSheetState();
}

class _DepositBottomSheetState extends State<DepositBottomSheet> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  List<String> _proofUrls = [];
  bool _submitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24,
        left: 24,
        right: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Hisobni to'ldirish",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 6),
            const Text(
              "Bank o'tkazmasi qilib, summani va (ixtiyoriy) chek rasmini yuboring - admin tasdiqlagach hamyoningizga tushadi.",
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
              decoration: InputDecoration(
                labelText: "To'ldirish miqdori (UZS)",
                prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                filled: true,
                fillColor: AppColors.background,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Summani kiriting';
                final num = double.tryParse(val);
                if (num == null || num < 1000) return 'Kamida 1000 UZS kiriting';
                return null;
              },
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("To'lov cheki (ixtiyoriy)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
            ),
            const SizedBox(height: 8),
            ImageUploadPicker(
              category: 'deposit',
              maxImages: 1,
              onChanged: (urls) => setState(() => _proofUrls = urls),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(_submitting ? 'Yuborilmoqda...' : "So'rov yuborish", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);

    final amt = double.parse(_amountController.text);
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final success = await walletProvider.requestDeposit(amount: amt, proofUrl: _proofUrls.isNotEmpty ? _proofUrls.first : null);

    if (!mounted) return;
    Navigator.pop(context);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("So'rov yuborildi, admin tekshiruvidan so'ng hamyoningizga tushadi"), backgroundColor: AppColors.primary),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(walletProvider.error ?? 'Xatolik yuz berdi'), backgroundColor: AppColors.danger),
      );
    }
  }
}
