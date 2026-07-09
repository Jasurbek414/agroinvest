import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/phone_verification_step.dart';
import '../widgets/profile_details_step.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _phoneController = TextEditingController(text: '+998');
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isPhoneVerified = false;
  String _selectedRole = 'INVESTOR';
  bool _obscurePassword = true;
  bool _isSendingOtp = false;
  // Separate, narrowly-scoped guard against the OTP screen being pushed twice -
  // kept independent of _isSendingOtp (which only covers the send-code network
  // call) so the invariant "at most one /otp route is ever open" holds even if
  // _isSendingOtp's timing changes under future edits.
  bool _otpPageOpen = false;

  @override
  void initState() {
    super.initState();
    // A stale error from some other flow (login, wallet OTP, expired session)
    // must not greet the user on a fresh registration attempt.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Provider.of<AuthProvider>(context, listen: false).clearError();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Ro\'yxatdan o\'tish',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textDark,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _isPhoneVerified ? 'Shaxsiy ma\'lumotlar' : 'Ro\'yxatdan o\'tish',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isPhoneVerified
                      ? 'Tizimda ishlash uchun ma\'lumotlarni to\'ldiring'
                      : 'Telefon raqamingizni SMS orqali tasdiqlang',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 36),

                if (authProvider.error != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.danger.withOpacity(0.15)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            authProvider.error!,
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                if (!_isPhoneVerified)
                  PhoneVerificationStep(
                    phoneController: _phoneController,
                    loading: authProvider.loading || _isSendingOtp,
                    onSendOtp: _sendOtp,
                  )
                else
                  ProfileDetailsStep(
                    nameController: _nameController,
                    emailController: _emailController,
                    passwordController: _passwordController,
                    obscurePassword: _obscurePassword,
                    onTogglePasswordVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                    selectedRole: _selectedRole,
                    onRoleChanged: (val) => setState(() => _selectedRole = val),
                    loading: authProvider.loading,
                    onSubmit: _submitRegister,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _sendOtp() async {
    if (_isSendingOtp || _otpPageOpen) return;
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSendingOtp = true;
      });

      final provider = Provider.of<AuthProvider>(context, listen: false);
      await provider.sendOtpCode(_phoneController.text, 'REGISTER');

      if (!mounted) return;

      // OTP_SEND_TOO_SOON means a still-valid code was already sent moments ago
      // (previous attempt, app restart...). Blocking here would dead-end the user
      // even though the code is sitting in their SMS inbox - so proceed to the
      // entry screen and surface the cooldown as an info note instead.
      final tooSoon = provider.errorCode == 'OTP_SEND_TOO_SOON';
      if (provider.error == null || tooSoon) {
        final infoMessage = tooSoon ? provider.error : null;
        final cooldownSeconds = tooSoon ? _parseWaitSeconds(provider.error) : null;
        if (tooSoon) provider.clearError();

        _otpPageOpen = true;
        final verified = await context.push<bool>(
          '/otp',
          extra: {
            'phoneNumber': _phoneController.text,
            'purpose': 'REGISTER',
            if (infoMessage != null) 'info': infoMessage,
            if (cooldownSeconds != null) 'cooldownSeconds': cooldownSeconds,
          },
        );
        _otpPageOpen = false;

        if (verified == true && mounted) {
          setState(() {
            _isPhoneVerified = true;
          });
        }
      }

      if (mounted) {
        setState(() {
          _isSendingOtp = false;
        });
      }
    }
  }

  /// Extracts the remaining seconds from the backend's "... N soniya kuting"
  /// cooldown message, so the OTP page's resend countdown matches the server.
  int? _parseWaitSeconds(String? message) {
    if (message == null) return null;
    final match = RegExp(r'(\d+)\s*soniya').firstMatch(message);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  void _submitRegister() async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<AuthProvider>(context, listen: false);
      final success = await provider.registerUser(
        fullName: _nameController.text,
        phoneNumber: _phoneController.text,
        email: _emailController.text.isEmpty ? null : _emailController.text,
        password: _passwordController.text,
        role: _selectedRole,
      );

      if (!mounted) return;

      if (success) {
        context.go('/projects');
      } else if (provider.errorCode == 'PHONE_NOT_VERIFIED') {
        // The 10-minute verification ticket expired (or was consumed) - the only
        // recovery is a fresh OTP round-trip, so bounce back to step 1 instead of
        // leaving the user stuck on a form that can never succeed.
        setState(() {
          _isPhoneVerified = false;
        });
      }
    }
  }
}
