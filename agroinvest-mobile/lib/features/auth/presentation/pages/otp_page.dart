import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';

class OtpPage extends StatefulWidget {
  final String phoneNumber;
  final String purpose;

  const OtpPage({
    super.key,
    required this.phoneNumber,
    required this.purpose,
  });

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final _otpController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('SMS kodni tasdiqlash'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textDark,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                'Kodni kiriting',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.phoneNumber} raqamiga yuborilgan 6 xonali kodni kiriting.',
                style: const TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 32),

              // Error display
              if (authProvider.error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                  ),
                  child: Text(
                    authProvider.error!,
                    style: const TextStyle(color: AppColors.danger, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // OTP pin fields using pin_code_fields
              PinCodeTextField(
                appContext: context,
                length: 6,
                controller: _otpController,
                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(12),
                  fieldHeight: 54,
                  fieldWidth: 44,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.border,
                  selectedColor: AppColors.primary,
                  activeFillColor: Colors.white,
                  inactiveFillColor: Colors.white,
                  selectedFillColor: Colors.white,
                ),
                enableActiveFill: true,
                onChanged: (value) {},
                onCompleted: _verify,
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: authProvider.loading ? null : () => _verify(_otpController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: authProvider.loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Tasdiqlash',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _verify(String code) async {
    if (code.length == 6) {
      final success = await Provider.of<AuthProvider>(context, listen: false).verifyOtpCode(
        widget.phoneNumber,
        widget.purpose,
        code,
      );

      if (success && mounted) {
        Navigator.pop(context, true); // Pop back returning true (verified)
      }
    }
  }
}
