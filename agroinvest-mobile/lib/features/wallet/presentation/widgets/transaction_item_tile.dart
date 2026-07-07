import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class TransactionItemTile extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final String Function(double) formatAmount;

  const TransactionItemTile({
    super.key,
    required this.transaction,
    required this.formatAmount,
  });

  String _getTransactionLabel(String? raw) {
    if (raw == null) return 'Tranzaksiya';
    switch (raw.toUpperCase()) {
      case 'DEPOSIT': return "Hisobni to'ldirish";
      case 'WITHDRAWAL': return "Mablag' yechish";
      case 'PAYOUT': return "Daromad to'lovi";
      case 'COMMISSION': return 'Tizim komissiyasi';
      case 'REFUND': return 'Bekor qilingan sarmoya';
      case 'FARMER_PAYOUT': return 'Fermerga to\'lov';
      default: return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final amt = double.tryParse(transaction['amount'].toString()) ?? 0.0;
    final isCredit = transaction['type'] == 'DEPOSIT' || transaction['type'] == 'PAYOUT';

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 1.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: isCredit ? AppColors.primaryLight : AppColors.danger.withOpacity(0.08),
          child: Icon(
            isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
            color: isCredit ? AppColors.primary : AppColors.danger,
            size: 16,
          ),
        ),
        title: Text(
          _getTransactionLabel(transaction['type']?.toString()),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
        ),
        subtitle: Text(
          transaction['paymentProvider']?.toString() ?? 'SYSTEM',
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
        ),
        trailing: Text(
          '${isCredit ? "+" : "-"} ${formatAmount(amt)}',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            color: isCredit ? AppColors.primary : AppColors.danger,
          ),
        ),
      ),
    );
  }
}
