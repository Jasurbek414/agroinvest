import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'transaction_item_tile.dart';

class TransactionHistorySection extends StatelessWidget {
  final List<dynamic> transactions;
  final String Function(double) formatAmount;

  const TransactionHistorySection({super.key, required this.transactions, required this.formatAmount});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tranzaksiyalar tarixi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            Text(
              'Jami: ${transactions.length}',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (transactions.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 36),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: const Column(
              children: [
                Icon(Icons.history_toggle_off_rounded, size: 40, color: AppColors.textMuted),
                SizedBox(height: 10),
                Text('Tranzaksiyalar mavjud emas', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              return TransactionItemTile(
                transaction: transactions[index],
                formatAmount: formatAmount,
              );
            },
          ),
      ],
    );
  }
}
