import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/status_badge.dart';

import 'package:go_router/go_router.dart';

class InvestmentCard extends StatelessWidget {
  final Map<String, dynamic> investment;
  final String Function(double) formatAmount;
  final VoidCallback onCancel;
  final VoidCallback onAddReview;
  final VoidCallback onViewContract;
  final VoidCallback? onSignContract;

  const InvestmentCard({
    super.key,
    required this.investment,
    required this.formatAmount,
    required this.onCancel,
    required this.onAddReview,
    required this.onViewContract,
    this.onSignContract,
  });

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(investment['amount']?.toString() ?? '0') ?? 0.0;
    final status = investment['status']?.toString() ?? 'PENDING';
    final projectTitle = investment['projectTitle']?.toString() ?? 'Agro loyiha';
    final share = double.tryParse(investment['sharePct']?.toString() ?? '0') ?? 0.0;
    final createdAtStr = investment['createdAt']?.toString();
    final date = createdAtStr != null ? createdAtStr.split('T').first : '';
    final isSigned = investment['contractSignedAt'] != null;

    IconData statusIcon;
    Color statusBgColor;
    Color statusIconColor;

    switch (status) {
      case 'ACTIVE':
        statusIcon = Icons.trending_up_rounded;
        statusBgColor = const Color(0xFFDCFCE7);
        statusIconColor = const Color(0xFF16A34A);
        break;
      case 'CONFIRMED':
        statusIcon = Icons.check_circle_outline_rounded;
        statusBgColor = const Color(0xFFEFF6FF);
        statusIconColor = const Color(0xFF2563EB);
        break;
      case 'RESERVED':
        statusIcon = Icons.watch_later_outlined;
        statusBgColor = const Color(0xFFFEF3C7);
        statusIconColor = const Color(0xFFD97706);
        break;
      case 'PAID_OUT':
        statusIcon = Icons.check_circle_rounded;
        statusBgColor = const Color(0xFFF3E8FF);
        statusIconColor = const Color(0xFF9333EA);
        break;
      default:
        statusIcon = Icons.info_outline_rounded;
        statusBgColor = const Color(0xFFF1F5F9);
        statusIconColor = const Color(0xFF64748B);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            final pId = investment['projectId'];
            if (pId != null) {
              context.push('/projects/$pId');
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    // Status icon indicator box
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: statusBgColor, borderRadius: BorderRadius.circular(10)),
                      child: Icon(statusIcon, color: statusIconColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    // Title and status badge
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            projectTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: AppColors.textDark),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              StatusBadge(status: status),
                              if (date.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Icon(Icons.calendar_month_outlined, size: 10, color: AppColors.textMuted),
                                const SizedBox(width: 2),
                                Text(
                                  date,
                                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: AppColors.textMuted.withOpacity(0.7)),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 10),
                // Investment stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Kiritilgan sarmoya', style: TextStyle(fontSize: 9.5, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(formatAmount(amount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.textDark)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Loyiha ulushi', style: TextStyle(fontSize: 9.5, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text('${share.toStringAsFixed(4)}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.primary)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Contract status row
                Row(
                  children: [
                    Icon(
                      isSigned ? Icons.verified_user_rounded : Icons.pending_actions_rounded,
                      size: 13,
                      color: isSigned ? AppColors.primary : AppColors.accent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isSigned ? 'Shartnoma imzolangan' : 'Shartnoma imzolanmagan',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSigned ? AppColors.primary : AppColors.accent,
                      ),
                    ),
                  ],
                ),
                // Context actions
                const SizedBox(height: 10),
                const Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onViewContract,
                        icon: const Icon(Icons.description_outlined, size: 13),
                        label: Text(
                          isSigned ? 'Shartnomani ko\'rish' : 'Shartnoma imzolash',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isSigned ? AppColors.primary : AppColors.accent,
                          side: BorderSide(color: isSigned ? AppColors.primary : AppColors.accent, width: 1.2),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    if (status == 'ACTIVE') ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final pId = investment['projectId'];
                            if (pId != null) {
                              context.push('/projects/$pId/reports', extra: {'title': projectTitle});
                            }
                          },
                          icon: const Icon(Icons.history_rounded, size: 13),
                          label: const Text('Hisobotlar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary, width: 1.2),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                    if (status == 'RESERVED' || status == 'CONFIRMED') ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onCancel,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.danger,
                            side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.2),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Bekor qilish', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ),
                    ],
                    if (status == 'PAID_OUT') ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onAddReview,
                          icon: const Icon(Icons.star_outline_rounded, size: 13),
                          label: const Text("Sharh qoldirish", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary, width: 1.2),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
