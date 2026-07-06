import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/status_badge.dart';
import '../providers/investment_provider.dart';

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
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : provider.error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(provider.error!, style: const TextStyle(color: AppColors.danger)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => provider.fetchMyInvestments(),
                          child: const Text('Qayta yuklash'),
                        ),
                      ],
                    ),
                  ),
                )
              : provider.investments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.trending_up_rounded, size: 64, color: AppColors.textMuted.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          const Text('Sarmoyalar topilmadi', style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => provider.fetchMyInvestments(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.investments.length,
                        itemBuilder: (context, index) {
                          final inv = provider.investments[index];
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
                                        backgroundColor: AppColors.danger.withValues(alpha: 0.1),
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
