import 'package:flutter/material.dart';

class PortfolioSummaryCard extends StatelessWidget {
  final List<dynamic> investments;
  final String Function(double) formatAmount;

  const PortfolioSummaryCard({
    super.key,
    required this.investments,
    required this.formatAmount,
  });

  @override
  Widget build(BuildContext context) {
    double totalInvested = 0;
    double expectedReturns = 0;
    int activeCount = 0;

    for (final inv in investments) {
      final amount = double.tryParse(inv['amount']?.toString() ?? '0') ?? 0.0;
      totalInvested += amount;
      final status = inv['status']?.toString() ?? '';
      if (status == 'ACTIVE') {
        activeCount++;
      }
      expectedReturns += amount * 0.24; // projected 24% returns
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF15803D), Color(0xFF166534)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF166534).withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'UMUMIY PORTFEL',
                style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.show_chart_rounded, color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '${investments.length} ta loyiha',
                      style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            formatAmount(totalInvested),
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem('Taxminiy ROI (24%)', formatAmount(expectedReturns)),
              _buildSummaryItem('Faol loyihalar', '$activeCount ta'),
              _buildSummaryItem('Status', 'Barqaror', valueColor: const Color(0xFF86EFAC)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, {Color valueColor = Colors.white}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: valueColor, fontSize: 13, fontWeight: FontWeight.w900)),
      ],
    );
  }
}
