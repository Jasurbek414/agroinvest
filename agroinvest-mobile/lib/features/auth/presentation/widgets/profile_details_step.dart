import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_text_field.dart';
import 'role_picker_cards.dart';

/// Step 2 of registration: name, email, password, role and the final submit
/// button, shown once the phone number has been OTP-verified.
class ProfileDetailsStep extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePasswordVisibility;
  final String selectedRole;
  final ValueChanged<String> onRoleChanged;
  final bool loading;
  final VoidCallback onSubmit;

  const ProfileDetailsStep({
    super.key,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePasswordVisibility,
    required this.selectedRole,
    required this.onRoleChanged,
    required this.loading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          label: 'To\'liq ismingiz (F.I.SH)',
          controller: nameController,
          hint: 'Toshmatov Toshmat',
          icon: Icons.person_outline_rounded,
          validator: (val) => val == null || val.isEmpty ? 'Ismingizni kiriting' : null,
        ),
        const SizedBox(height: 18),

        AppTextField(
          label: 'Email manzil (ixtiyoriy)',
          controller: emailController,
          hint: 'example@domain.com',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 18),

        AppTextField(
          label: 'Parol',
          controller: passwordController,
          hint: '••••••••',
          icon: Icons.lock_outline_rounded,
          obscureText: obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: AppColors.textMuted,
            ),
            onPressed: onTogglePasswordVisibility,
          ),
          validator: (val) => val == null || val.length < 6 ? 'Parol kamida 6 ta belgi bo\'lishi shart' : null,
        ),
        const SizedBox(height: 24),

        Text(
          'Sizning rolingiz',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark.withOpacity(0.8)),
        ),
        const SizedBox(height: 8),
        RolePickerCards(selectedRole: selectedRole, onChanged: onRoleChanged),
        const SizedBox(height: 36),

        ElevatedButton(
          onPressed: loading ? null : onSubmit,
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
              : const Text('Ro\'yxatdan o\'tish', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
