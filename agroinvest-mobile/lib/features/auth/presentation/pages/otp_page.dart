import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';

class OtpPage extends StatefulWidget {
  final String phoneNumber;
  final String purpose;

  /// Optional informational note shown above the pin fields (e.g. "a code was
  /// already sent, wait N seconds to resend") - distinct from error state.
  final String? infoMessage;

  /// Initial resend-cooldown seconds. Defaults to the standard 60s, but the
  /// register flow passes the server's actual remaining cooldown when the user
  /// re-enters this screen mid-cooldown.
  final int? initialCooldownSeconds;

  const OtpPage({
    super.key,
    required this.phoneNumber,
    required this.purpose,
    this.infoMessage,
    this.initialCooldownSeconds,
  });

  @override
  State<OtpPage> createState() => _OtpPageState();
}

const _resendCooldownSeconds = 60;

class _OtpPageState extends State<OtpPage> {
  final _otpController = TextEditingController();
  Timer? _resendTimer;
  int _secondsLeft = _resendCooldownSeconds;
  bool _isVerifying = false;
  String? _infoMessage;

  @override
  void initState() {
    super.initState();
    _infoMessage = widget.infoMessage;
    _startResendCooldown(widget.initialCooldownSeconds ?? _resendCooldownSeconds);
    // Don't inherit a stale error from whatever flow ran before this screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Provider.of<AuthProvider>(context, listen: false).clearError();
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  // Without this, a user whose SMS never arrives has no way back to a resend
  // button short of leaving the page entirely and restarting registration.
  void _startResendCooldown(int seconds) {
    setState(() => _secondsLeft = seconds);
    _resendTimer?.cancel();
    if (seconds <= 0) return;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  void _resend() async {
    final provider = Provider.of<AuthProvider>(context, listen: false);
    await provider.sendOtpCode(widget.phoneNumber, widget.purpose);
    if (!mounted) return;

    if (provider.error == null) {
      setState(() => _infoMessage = null);
      _startResendCooldown(_resendCooldownSeconds);
    } else if (provider.errorCode == 'OTP_SEND_TOO_SOON') {
      // Local timer drifted from the server's cooldown - resync the countdown
      // to what the backend reported instead of showing a scary error.
      final remaining = _parseWaitSeconds(provider.error) ?? _resendCooldownSeconds;
      setState(() => _infoMessage = provider.error);
      provider.clearError();
      _startResendCooldown(remaining);
    }
  }

  int? _parseWaitSeconds(String? message) {
    if (message == null) return null;
    final match = RegExp(r'(\d+)\s*soniya').firstMatch(message);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

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
              const Text(
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

              // Info note (amber) - e.g. "code already sent, wait to resend"
              if (_infoMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppColors.accent, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _infoMessage!,
                          style: const TextStyle(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

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
                onPressed: _isVerifying ? null : () => _verify(_otpController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isVerifying
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text(
                        'Tasdiqlash',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 20),
              Center(
                child: _secondsLeft > 0
                    ? Text(
                        'Kodni qayta yuborish: 0:${_secondsLeft.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w500),
                      )
                    : TextButton(
                        onPressed: (authProvider.loading || _isVerifying) ? null : _resend,
                        child: const Text(
                          'Kodni qayta yuborish',
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _verify(String code) async {
    if (code.length == 6 && !_isVerifying) {
      setState(() {
        _isVerifying = true;
      });

      final success = await Provider.of<AuthProvider>(context, listen: false).verifyOtpCode(
        widget.phoneNumber,
        widget.purpose,
        code,
      );

      if (!mounted) return;

      if (success) {
        if (context.canPop()) {
          context.pop(true); // Pop back returning true (verified)
        }
      } else {
        // A wrong/expired code (or a transient network failure) previously left
        // the pin boxes full with no clean way to retry - clear them so the
        // next attempt starts fresh instead of editing on top of a stale code.
        _otpController.clear();
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }
}
