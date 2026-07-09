import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/format.dart';
import '../providers/wallet_provider.dart';
import '../widgets/wallet_card.dart';
import '../widgets/wallet_stats_card.dart';
import '../widgets/transaction_chart.dart';
import '../widgets/transaction_history_section.dart';
import '../widgets/deposit_bottom_sheet.dart';
import '../widgets/withdrawal_bottom_sheet.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WalletProvider>(context, listen: false).fetchWallet();
    });
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context);
    String formatAmount(double val) => '${formatMoney(val)} UZS';

    final wallet = walletProvider.wallet;
    final transactions = walletProvider.transactions;
    final balanceVal = double.tryParse(wallet?['balance']?.toString() ?? '0') ?? 0.0;
    final frozenVal = double.tryParse(wallet?['frozen']?.toString() ?? '0') ?? 0.0;
    final withdrawnVal = double.tryParse(wallet?['totalWithdrawn']?.toString() ?? '0') ?? 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Hamyon', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textDark,
        centerTitle: true,
      ),
      body: walletProvider.loading && wallet == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : walletProvider.error != null && wallet == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Hamyon ma'lumotlarini yuklashda xatolik yuz berdi",
                          style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => walletProvider.fetchWallet(),
                          child: const Text('Qayta urinish'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: walletProvider.fetchWallet,
                  color: AppColors.primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        WalletCard(balanceText: formatAmount(balanceVal)),
                        const SizedBox(height: 24),

                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _showDepositSheet,
                                icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                                label: const Text("To'ldirish", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _showWithdrawalSheet,
                                icon: const Icon(Icons.arrow_circle_up_rounded, size: 18),
                                label: const Text("Yechib olish", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        Row(
                          children: [
                            Expanded(
                              child: WalletStatsCard(title: 'Muzlatilgan sarmoya', value: formatAmount(frozenVal), color: AppColors.accent),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: WalletStatsCard(title: 'Yechib olingan', value: formatAmount(withdrawnVal), color: AppColors.textMuted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        if (transactions.isNotEmpty) ...[
                          TransactionChart(transactions: transactions, formatAmount: formatAmount),
                          const SizedBox(height: 28),
                        ],

                        TransactionHistorySection(transactions: transactions, formatAmount: formatAmount),
                      ],
                    ),
                  ),
                ),
    );
  }

  void _showDepositSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const DepositBottomSheet(),
    );
  }

  void _showWithdrawalSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const WithdrawalBottomSheet(),
    );
  }
}
