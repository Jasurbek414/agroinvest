import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/format.dart';
import '../../../investments/presentation/providers/investment_provider.dart';

class PortfolioAnalyticsPage extends StatefulWidget {
  const PortfolioAnalyticsPage({super.key});

  @override
  State<PortfolioAnalyticsPage> createState() => _PortfolioAnalyticsPage();
}

class _PortfolioAnalyticsPage extends State<PortfolioAnalyticsPage> {
  final _calcAmountController = TextEditingController(text: '10000000');
  double _roiPercent = 32.0;
  int _durationMonths = 12;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InvestmentProvider>(context, listen: false).fetchMyInvestments();
    });
  }

  @override
  void dispose() {
    _calcAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final investmentProvider = Provider.of<InvestmentProvider>(context);
    final investments = investmentProvider.investments;

    double totalInvested = 0;
    for (final inv in investments) {
      totalInvested += double.tryParse(inv['amount']?.toString() ?? '0') ?? 0.0;
    }

    // Calculations for calculator
    final double inputAmount = double.tryParse(_calcAmountController.text.replaceAll(' ', '')) ?? 0.0;
    final double expectedProfit = inputAmount * (_roiPercent / 100) * (_durationMonths / 12);
    final double totalPayout = inputAmount + expectedProfit;
    final double monthlyProfit = expectedProfit / _durationMonths;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sarmoya & ROI Tahlili', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textDark,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Section 1: Portfolio Overview
          _buildSectionTitle('Sizning Sarmoyalaringiz', Icons.pie_chart_outline_rounded),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Jami kiritilgan kapital', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 4),
                Text(
                  '${formatMoney(totalInvested)} UZS',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textDark),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildOverviewItem('Sarmoyalar', '${investments.length} ta', Colors.blue),
                    _buildOverviewItem('O\'rtacha ROI', '28.5%', Colors.green),
                    _buildOverviewItem('Kutilayotgan foyda', '${formatMoney(totalInvested * 0.285)} UZS', Colors.orange),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Section 2: Interactive ROI Calculator
          _buildSectionTitle('ROI Kalkulyatori', Icons.calculate_outlined),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Input amount
                TextFormField(
                  controller: _calcAmountController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Sarmoya miqdori (UZS)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                  ),
                ),
                const SizedBox(height: 20),

                // ROI Selector slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Kutilayotgan yillik daromad (ROI):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    Text('${_roiPercent.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
                Slider(
                  value: _roiPercent,
                  min: 10,
                  max: 50,
                  divisions: 8,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _roiPercent = val),
                ),
                const SizedBox(height: 10),

                // Duration Selector slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Sarmoya muddati:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    Text('$_durationMonths oy', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
                Slider(
                  value: _durationMonths.toDouble(),
                  min: 3,
                  max: 24,
                  divisions: 7,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _durationMonths = val.toInt()),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 20),

                // Outputs
                _buildCalculatorResultRow('Kutilayotgan jami foyda:', '${formatMoney(expectedProfit)} UZS', isHighlight: true, color: AppColors.primary),
                const SizedBox(height: 10),
                _buildCalculatorResultRow('Oylik sof daromad:', '${formatMoney(monthlyProfit)} UZS'),
                const SizedBox(height: 10),
                _buildCalculatorResultRow('Jami qaytariladigan pul:', '${formatMoney(totalPayout)} UZS'),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.primaryDark),
        ),
      ],
    );
  }

  Widget _buildOverviewItem(String title, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildCalculatorResultRow(String label, String value, {bool isHighlight = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isHighlight ? 13 : 12,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            color: isHighlight ? AppColors.textDark : AppColors.textMuted,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlight ? 15 : 13,
            fontWeight: FontWeight.bold,
            color: color ?? AppColors.textDark,
          ),
        ),
      ],
    );
  }
}
