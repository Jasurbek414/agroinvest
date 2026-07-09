import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_text_field.dart';

/// Step 1 of registration: phone number entry + "send OTP" button.
class PhoneVerificationStep extends StatelessWidget {
  final TextEditingController phoneController;
  final bool loading;
  final VoidCallback onSendOtp;

  const PhoneVerificationStep({
    super.key,
    required this.phoneController,
    required this.loading,
    required this.onSendOtp,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          label: 'Telefon raqami',
          controller: phoneController,
          hint: '+998901234567',
          icon: Icons.phone_iphone_rounded,
          keyboardType: TextInputType.phone,
          validator: (val) {
            if (val == null || val.length != 13 || !val.startsWith('+998')) {
              return 'Raqamni +998XXXXXXXXX formatida kiriting';
            }
            return null;
          },
        ),
        const SizedBox(height: 28),
        ElevatedButton(
          onPressed: loading ? null : onSendOtp,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: loading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              : const Text('Kodni yuborish', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
