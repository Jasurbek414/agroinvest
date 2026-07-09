import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/wallet_provider.dart';

/// Card-withdrawal request form, shown via showModalBottomSheet from WalletPage.
/// Extracted out of wallet_page.dart (previously ~200 lines inline) together with
/// its TZ F-1.8 2FA handshake: a fresh OTP round-trip via /otp is required before
/// the request is submitted, reusing the same route/purpose="WITHDRAWAL" flow
/// already used at registration.
class WithdrawalBottomSheet extends StatefulWidget {
  const WithdrawalBottomSheet({super.key});

  @override
  State<WithdrawalBottomSheet> createState() => _WithdrawalBottomSheetState();
}

class _WithdrawalBottomSheetState extends State<WithdrawalBottomSheet> {
  final _amountController = TextEditingController();
  final _bankController = TextEditingController();
  final _cardController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSendingOtp = false;

  @override
  void dispose() {
    _amountController.dispose();
    _bankController.dispose();
    _cardController.dispose();
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
              'Karta orqali pul yechish',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
              decoration: InputDecoration(
                labelText: 'Summa (UZS)',
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
                if (num == null || num < 5000) return 'Kamida 5000 UZS kiriting';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bankController,
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
              decoration: InputDecoration(
                labelText: 'Bank nomi (masalan: TBC Bank)',
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
              validator: (val) => val == null || val.isEmpty ? 'Bank nomini kiriting' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cardController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
              decoration: InputDecoration(
                labelText: 'Karta raqami (8600...)',
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
              validator: (val) => val == null || val.length < 16 ? "Karta raqamini to'liq kiriting" : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("So'rov yuborish", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _submit() async {
    if (_isSendingOtp) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSendingOtp = true);
    Navigator.pop(context);

    final amt = double.parse(_amountController.text);
    final bank = _bankController.text;
    final card = _cardController.text;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final phoneNumber = authProvider.user?['phoneNumber']?.toString();
    if (phoneNumber == null) {
      if (mounted) setState(() => _isSendingOtp = false);
      return;
    }

    await authProvider.sendOtpCode(phoneNumber, 'WITHDRAWAL');
    if (!mounted) return;

    // OTP_SEND_TOO_SOON = a still-valid code is already in the user's inbox
    // (e.g. a withdrawal attempt moments ago) - proceed to the entry screen
    // with an info note instead of dead-ending on a snackbar.
    final tooSoon = authProvider.errorCode == 'OTP_SEND_TOO_SOON';
    String? infoMessage;
    if (tooSoon) {
      infoMessage = authProvider.error;
      authProvider.clearError();
    } else if (authProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.error!), backgroundColor: AppColors.danger),
      );
      setState(() => _isSendingOtp = false);
      return;
    }

    final verified = await context.push<bool>(
      '/otp',
      extra: {
        'phoneNumber': phoneNumber,
        'purpose': 'WITHDRAWAL',
        if (infoMessage != null) 'info': infoMessage,
      },
    );
    if (!mounted || verified != true) {
      setState(() => _isSendingOtp = false);
      return;
    }

    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final success = await walletProvider.requestWithdrawal(amount: amt, bankName: bank, cardNumber: card);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Yechib olish so'rovi qabul qilindi va ko'rib chiqilmoqda"), backgroundColor: AppColors.primary),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(walletProvider.error ?? 'Xatolik yuz berdi'), backgroundColor: AppColors.danger),
      );
    }

    setState(() => _isSendingOtp = false);
  }
}
