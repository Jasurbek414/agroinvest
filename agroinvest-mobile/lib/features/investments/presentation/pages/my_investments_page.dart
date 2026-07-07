import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/shimmer_loader.dart';
import '../../../../core/widgets/status_badge.dart';
import '../providers/investment_provider.dart';

const _portfolioStatusColors = {
  'RESERVED': AppColors.accent,
  'CONFIRMED': AppColors.primary,
  'ACTIVE': AppColors.primaryDark,
  'PAID_OUT': AppColors.info,
  'REFUNDED': Colors.purple,
  'CANCELLED': AppColors.danger,
};

const _portfolioStatusLabels = {
  'RESERVED': 'Zahiralangan',
  'CONFIRMED': 'Tasdiqlangan',
  'ACTIVE': 'Faol',
  'PAID_OUT': "To'langan",
  'REFUNDED': 'Qaytarilgan',
  'CANCELLED': 'Bekor qilingan',
};

class MyInvestmentsPage extends StatefulWidget {
  const MyInvestmentsPage({super.key});

  @override
  State<MyInvestmentsPage> createState() => _MyInvestmentsPageState();
}

class _MyInvestmentsPageState extends State<MyInvestmentsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InvestmentProvider>(context, listen: false).fetchMyInvestments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<InvestmentProvider>(context);

    final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String formatAmount(double val) {
      return val.toStringAsFixed(0).replaceAllMapped(formatter, (Match m) => '${m[1]} ') + ' UZS';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Investitsiyalarim', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textDark,
      ),
      body: provider.loading
          ? const ShimmerList()
          : provider.error != null
              ? ErrorStateWidget(message: provider.error!, onRetry: () => provider.fetchMyInvestments())
              : provider.investments.isEmpty
                  ? const EmptyState(icon: Icons.trending_up_rounded, title: 'Sarmoyalar topilmadi')
                  : RefreshIndicator(
                      onRefresh: () => provider.fetchMyInvestments(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.investments.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return _buildPortfolioSummary(provider.investments, formatAmount);
                          }
                          final inv = provider.investments[index - 1];
                          final amount = double.tryParse(inv['amount']?.toString() ?? '0') ?? 0.0;
                          final status = inv['status']?.toString() ?? 'PENDING';
                          final projectTitle = inv['projectTitle']?.toString() ?? 'Agro loyiha';
                          final share = double.tryParse(inv['sharePct']?.toString() ?? '0') ?? 0.0;

                          return Card(
                            color: Colors.white,
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: const BorderSide(color: AppColors.border),
                            ),
                            elevation: 0,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          projectTitle,
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                        ),
                                      ),
                                      StatusBadge(status: status),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Kiritilgan sarmoya', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                          const SizedBox(height: 2),
                                          Text(formatAmount(amount), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          const Text('Loyiha ulushi', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                          const SizedBox(height: 2),
                                          Text('${share.toStringAsFixed(4)}%', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (status == 'RESERVED' || status == 'CONFIRMED') ...[
                                    const Divider(height: 24, color: AppColors.border),
                                    ElevatedButton(
                                      onPressed: () => _confirmCancel(context, provider, inv['id']),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.danger.withOpacity(0.1),
                                        foregroundColor: AppColors.danger,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: const Text('Sarmoyani bekor qilish', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  // Portfolio overview card: total invested + a status breakdown pie chart -
  // previously this page was a bare list with no aggregate view of the
  // investor's overall position across every project.
  Widget _buildPortfolioSummary(List<dynamic> investments, String Function(double) formatAmount) {
    double total = 0;
    final Map<String, int> statusCounts = {};
    for (final inv in investments) {
      total += double.tryParse(inv['amount']?.toString() ?? '0') ?? 0.0;
      final status = inv['status']?.toString() ?? 'UNKNOWN';
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Portfolio', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(formatAmount(total), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textDark)),
          Text('${investments.length} ta sarmoya', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 26,
                      sections: statusCounts.entries.map((e) {
                        final color = _portfolioStatusColors[e.key] ?? AppColors.textMuted;
                        return PieChartSectionData(
                          color: color,
                          value: e.value.toDouble(),
                          title: '${e.value}',
                          radius: 30,
                          titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: statusCounts.entries.map((e) {
                      final color = _portfolioStatusColors[e.key] ?? AppColors.textMuted;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text(
                              '${_portfolioStatusLabels[e.key] ?? e.key} (${e.value})',
                              style: const TextStyle(fontSize: 11.5, color: AppColors.textDark, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmCancel(BuildContext context, InvestmentProvider provider, String investmentId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sarmoyani bekor qilish'),
          content: const Text('Haqiqatan ham ushbu sarmoyani bekor qilmoqchimisiz? (Mablag\' hamyoningizga qaytariladi)'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Orqaga'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final success = await provider.cancelUserInvestment(investmentId);
                if (mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sarmoya bekor qilindi va pulingiz qaytarildi'), backgroundColor: AppColors.primary),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(provider.error ?? 'Xatolik yuz berdi'), backgroundColor: AppColors.danger),
                    );
                  }
                }
              },
              child: const Text('Bekor qilish', style: TextStyle(color: AppColors.danger)),
            ),
          ],
        );
      },
    );
  }
}
