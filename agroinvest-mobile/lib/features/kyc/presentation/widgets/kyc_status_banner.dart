import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class KycStatusBanner extends StatelessWidget {
  final String? status;
  final Map<String, dynamic>? me;

  const KycStatusBanner({
    super.key,
    required this.status,
    required this.me,
  });

  String _getStatusLabel(String? s) {
    if (s == 'VERIFIED') return 'Tasdiqlangan';
    if (s == 'PENDING') return 'Kutilmoqda';
    if (s == 'REJECTED') return 'Rad etilgan';
    return 'Topshirilmagan';
  }

  Color _getStatusColor(String? s) {
    if (s == 'VERIFIED') return AppColors.primary;
    if (s == 'PENDING') return AppColors.accent;
    if (s == 'REJECTED') return AppColors.danger;
    return AppColors.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    final title = _getStatusLabel(status);
    final color = _getStatusColor(status);
    final isRejected = status == 'REJECTED';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: status == 'VERIFIED'
              ? [const Color(0xFF1B5E20), const Color(0xFF4CAF50)]
              : status == 'PENDING'
                  ? [const Color(0xFFF57C00), const Color(0xFFFFB74D)]
                  : status == 'REJECTED'
                      ? [const Color(0xFFD32F2F), const Color(0xFFEF5350)]
                      : [const Color(0xFF757575), const Color(0xFF9E9E9E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                status == 'VERIFIED'
                    ? Icons.verified_user_rounded
                    : status == 'PENDING'
                        ? Icons.hourglass_empty_rounded
                        : status == 'REJECTED'
                            ? Icons.gavel_rounded
                            : Icons.info_outline_rounded,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'KYC Holati: $title',
                style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16),
              ),
            ],
          ),
          if (isRejected && me?['kycRejectedReason'] != null) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 12),
            const Text(
              'Rad etilish sababi:',
              style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              me!['kycRejectedReason'],
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}
