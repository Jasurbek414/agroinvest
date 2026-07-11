import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
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
const _otpLength = 4;

class _OtpPageState extends State<OtpPage> {
  // Hand-rolled 4-box input (one TextEditingController + FocusNode per digit)
  // instead of the pin_code_fields package: that package was the source of a
  // real Flutter framework-level crash on some devices ('_elements.contains
  // (element)' / LateInitializationError on internal _children) triggered
  // during this exact registration flow. Those are debug-only assert()
  // checks, but the underlying element-tree inconsistency they were guarding
  // against was very likely still happening (silently) in release builds -
  // plausibly explaining the "page appears twice" / stale-state symptoms
  // reported earlier. Plain TextFields + FocusNodes, matching the pattern
  // already used and working on the web OTPInput, avoid that surface area
  // entirely.
  final List<TextEditingController> _digitControllers = List.generate(_otpLength, (_) => TextEditingController());
  final List<FocusNode> _digitFocusNodes = List.generate(_otpLength, (_) => FocusNode());
  Timer? _resendTimer;
  int _secondsLeft = _resendCooldownSeconds;
  bool _isVerifying = false;
  String? _infoMessage;
  String? _errorMessage;

  // Same dedup purpose as the web OTPInput's firedForRef: guards against a
  // duplicate verify request for the same already-submitted code (whatever
  // the trigger), which the backend would otherwise report as "expired" even
  // though the code was correct and already used.
  String? _lastAttemptedCode;

  @override
  void initState() {
    super.initState();
    _infoMessage = widget.infoMessage;
    _startResendCooldown(widget.initialCooldownSeconds ?? _resendCooldownSeconds);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<AuthProvider>(context, listen: false).clearError();
        FocusScope.of(context).requestFocus(_digitFocusNodes.first);
      }
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (final c in _digitControllers) {
      c.dispose();
    }
    for (final f in _digitFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _enteredCode => _digitControllers.map((c) => c.text).join();

  void _clearDigits() {
    for (final c in _digitControllers) {
      c.clear();
    }
    _lastAttemptedCode = null;
    if (mounted) {
      FocusScope.of(context).requestFocus(_digitFocusNodes.first);
    }
  }

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty) {
      if (index < _otpLength - 1) {
        _digitFocusNodes[index + 1].requestFocus();
      } else {
        _digitFocusNodes[index].unfocus();
      }
    } else if (index > 0) {
      // Backspace cleared this box - jump back so the next keystroke lands
      // on the previous digit, without any raw key-event listening.
      _digitFocusNodes[index - 1].requestFocus();
    }

    final code = List.generate(_otpLength, (i) => i == index ? value : _digitControllers[i].text).join();
    if (code.length == _otpLength) {
      _verify(code);
    } else {
      _lastAttemptedCode = null;
    }
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
    setState(() {
      _errorMessage = null;
    });
    try {
      await provider.sendOtpCode(widget.phoneNumber, widget.purpose);
      if (!mounted) return;
      setState(() => _infoMessage = null);
      _startResendCooldown(_resendCooldownSeconds);
    } catch (e) {
      if (!mounted) return;
      final errMsg = e.toString();
      final tooSoon = errMsg.contains('OTP_SEND_TOO_SOON') || errMsg.contains('soniya kuting');
      if (tooSoon) {
        final remaining = _parseWaitSeconds(errMsg) ?? _resendCooldownSeconds;
        setState(() => _infoMessage = errMsg);
        _startResendCooldown(remaining);
      } else {
        setState(() {
          _errorMessage = errMsg;
        });
      }
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
        title: const Text(
          'SMS kodni tasdiqlash',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 18),
        ),
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
                '${widget.phoneNumber} raqamiga yuborilgan $_otpLength xonali kodni kiriting.',
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
               if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.danger, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // 4-box OTP input
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_otpLength, (index) {
                  return Padding(
                    padding: EdgeInsets.only(right: index < _otpLength - 1 ? 12 : 0),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: TextField(
                        controller: _digitControllers[index],
                        focusNode: _digitFocusNodes[index],
                        enabled: !_isVerifying,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                          ),
                        ),
                        onChanged: (value) => _onDigitChanged(index, value),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isVerifying ? null : () => _verify(_enteredCode),
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
    if (code.length != _otpLength || _isVerifying || code == _lastAttemptedCode) return;

    _lastAttemptedCode = code;
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      await Provider.of<AuthProvider>(context, listen: false).verifyOtpCode(
        widget.phoneNumber,
        widget.purpose,
        code,
      );
      if (context.mounted) {
        GoRouter.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      _clearDigits();
      setState(() {
        _isVerifying = false;
        _lastAttemptedCode = null;
        _errorMessage = e.toString();
      });
    }
  }
}
