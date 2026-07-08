import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class TransactionChart extends StatelessWidget {
  final List<dynamic> transactions;
  final String Function(double) formatAmount;

  const TransactionChart({
    super.key,
    required this.transactions,
    required this.formatAmount,
  });

  @override
  Widget build(BuildContext context) {
    final recent = transactions.take(8).toList().reversed.toList();
    final maxAmount = recent
        .map((t) => (double.tryParse(t['amount'].toString()) ?? 0.0).abs())
        .fold<double>(0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 18, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 6, bottom: 12),
            child: Text("So'nggi harakatlar", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          ),
          SizedBox(
            height: 120,
            child: BarChart(
              BarChartData(
                maxY: maxAmount == 0 ? 1 : maxAmount * 1.2,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final t = recent[group.x.toInt()];
                      final isCredit = t['type'] == 'DEPOSIT' || t['type'] == 'PAYOUT' || t['type'] == 'FARMER_PAYOUT';
                      final amt = double.tryParse(t['amount'].toString()) ?? 0.0;
                      return BarTooltipItem(
                        '${isCredit ? "+" : "-"}${formatAmount(amt)}',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                      );
                    },
                  ),
                ),
                barGroups: List.generate(recent.length, (i) {
                  final t = recent[i];
                  final isCredit = t['type'] == 'DEPOSIT' || t['type'] == 'PAYOUT' || t['type'] == 'FARMER_PAYOUT';
                  final amt = (double.tryParse(t['amount'].toString()) ?? 0.0).abs();
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: amt,
                        color: isCredit ? AppColors.primary : AppColors.danger,
                        width: 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
