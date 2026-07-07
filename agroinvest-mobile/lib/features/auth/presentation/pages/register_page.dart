import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';

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

                // Error display
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

                if (!_isPhoneVerified) ...[
                  // Step 1: Phone input
                  Text(
                    'Telefon raqami',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    key: const ValueKey('phone_field'),
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
                    decoration: InputDecoration(
                      hintText: '+998901234567',
                      prefixIcon: const Icon(Icons.phone_iphone_rounded, color: AppColors.textMuted),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.length != 13 || !val.startsWith('+998')) {
                        return 'Raqamni +998XXXXXXXXX formatida kiriting';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  ElevatedButton(
                    onPressed: (authProvider.loading || _isSendingOtp) ? null : _sendOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: authProvider.loading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text(
                            'Kodni yuborish',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ] else ...[
                  // Step 2: Name, Email, Password, Role
                  Text(
                    'To\'liq ismingiz (F.I.SH)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark.withOpacity(0.8)),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    key: const ValueKey('name_field'),
                    controller: _nameController,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
                    decoration: InputDecoration(
                      hintText: 'Toshmatov Toshmat',
                      prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.textMuted),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Ismingizni kiriting';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  Text(
                    'Email manzil (ixtiyoriy)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark.withOpacity(0.8)),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    key: const ValueKey('email_field'),
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
                    decoration: InputDecoration(
                      hintText: 'example@domain.com',
                      prefixIcon: const Icon(Icons.mail_outline_rounded, color: AppColors.textMuted),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  Text(
                    'Parol',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark.withOpacity(0.8)),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    key: const ValueKey('password_field'),
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textMuted),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.length < 6) {
                        return 'Parol kamida 6 ta belgi bo\'lishi shart';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Role selector cards
                  Text(
                    'Sizning rolingiz',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark.withOpacity(0.8)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Investor Role Card
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _selectedRole = 'INVESTOR'),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                            decoration: BoxDecoration(
                              color: _selectedRole == 'INVESTOR' ? AppColors.primaryLight : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _selectedRole == 'INVESTOR' ? AppColors.primary : AppColors.border,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.trending_up_rounded,
                                  color: _selectedRole == 'INVESTOR' ? AppColors.primary : AppColors.textMuted,
                                  size: 28,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Investor',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: _selectedRole == 'INVESTOR' ? AppColors.primaryDark : AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Sarmoya kiritish',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _selectedRole == 'INVESTOR' ? AppColors.primary.withOpacity(0.8) : AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Farmer Role Card
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _selectedRole = 'FARMER'),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                            decoration: BoxDecoration(
                              color: _selectedRole == 'FARMER' ? AppColors.primaryLight : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _selectedRole == 'FARMER' ? AppColors.primary : AppColors.border,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.agriculture_rounded,
                                  color: _selectedRole == 'FARMER' ? AppColors.primary : AppColors.textMuted,
                                  size: 28,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Fermer',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: _selectedRole == 'FARMER' ? AppColors.primaryDark : AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Loyiha yaratish',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _selectedRole == 'FARMER' ? AppColors.primary.withOpacity(0.8) : AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),

                  ElevatedButton(
                    onPressed: authProvider.loading ? null : _submitRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: authProvider.loading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text(
                            'Ro\'yxatdan o\'tish',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _sendOtp() async {
    if (_isSendingOtp) return;
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

        final verified = await context.push<bool>(
          '/otp',
          extra: {
            'phoneNumber': _phoneController.text,
            'purpose': 'REGISTER',
            if (infoMessage != null) 'info': infoMessage,
            if (cooldownSeconds != null) 'cooldownSeconds': cooldownSeconds,
          },
        );

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
