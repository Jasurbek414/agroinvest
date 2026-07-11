import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// KYC nudge shown under the profile header for every state except VERIFIED:
/// not-submitted users get a call-to-action, PENDING a "being reviewed" note,
/// REJECTED the admin's reason and a resubmit shortcut.
class ProfileKycBanner extends StatelessWidget {
  final String? kycStatus;
  final String? rejectedReason;
  final VoidCallback onTap;

  const ProfileKycBanner({
    super.key,
    required this.kycStatus,
    this.rejectedReason,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (kycStatus == 'VERIFIED') return const SizedBox.shrink();

    final (color, icon, title, subtitle) = switch (kycStatus) {
      'PENDING' => (
          AppColors.info,
          Icons.hourglass_top_rounded,
          "Hujjatlar ko'rib chiqilmoqda",
          'KYC arizangiz tekshirilmoqda - odatda 1 ish kuni ichida yakunlanadi.',
        ),
      'REJECTED' => (
          AppColors.danger,
          Icons.error_outline_rounded,
          'KYC rad etildi',
          rejectedReason?.isNotEmpty == true
              ? 'Sabab: $rejectedReason. Qayta yuborish uchun bosing.'
              : "Hujjatlaringiz rad etildi. Qayta yuborish uchun bosing.",
        ),
      _ => (
          AppColors.accent,
          Icons.verified_user_outlined,
          'Shaxsingizni tasdiqlang',
          "Sarmoya kiritish va pul yechish uchun KYC dan o'ting - bir marta, 2 daqiqa.",
        ),
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.25), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted, fontWeight: FontWeight.w500, height: 1.35),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
