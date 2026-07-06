import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

const Map<String, String> _uzLabels = {
  'PENDING': 'Kutilmoqda',
  'APPROVED': 'Tasdiqlangan',
  'FUNDING': "Mablag' yig'ish",
  'ACTIVE': 'Faol',
  'COMPLETED': 'Yakunlangan',
  'CANCELLED': 'Bekor qilingan',
  'REJECTED': 'Rad etilgan',
  'REFUNDED': 'Qaytarilgan',
  'RESERVED': 'Zahiralangan',
  'CONFIRMED': 'Tasdiqlangan',
  'PAID_OUT': "To'langan",
  'VERIFIED': 'Tasdiqlangan',
};

/// Single source of truth for status -> color mapping across the app (investments,
/// projects, withdrawals, disputes) - previously each page defined its own switch
/// statement, some using raw Colors.blue/amber instead of the app's own AppColors palette.
class StatusBadge extends StatelessWidget {
  final String status;
  final String? label;

  const StatusBadge({super.key, required this.status, this.label});

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color fg;

    switch (status.toUpperCase()) {
      case 'CONFIRMED':
      case 'ACTIVE':
      case 'APPROVED':
      case 'VERIFIED':
        bg = AppColors.primaryLight;
        fg = AppColors.primaryDark;
        break;
      case 'FUNDING':
        bg = AppColors.info.withValues(alpha: 0.1);
        fg = AppColors.info;
        break;
      case 'CANCELLED':
      case 'REJECTED':
      case 'REFUNDED':
        bg = AppColors.danger.withValues(alpha: 0.1);
        fg = AppColors.danger;
        break;
      case 'COMPLETED':
      case 'PAID_OUT':
        bg = AppColors.border;
        fg = AppColors.textMuted;
        break;
      default:
        bg = AppColors.accent.withValues(alpha: 0.12);
        fg = AppColors.accent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        label ?? _uzLabels[status.toUpperCase()] ?? status,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
