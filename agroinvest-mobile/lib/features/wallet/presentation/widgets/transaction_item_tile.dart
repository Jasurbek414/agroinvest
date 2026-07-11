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

  void _showReceiptSheet(BuildContext context, double amt, bool isCredit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Elektron Kvitansiya', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 20),
              // Receipt frame
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, color: AppColors.primary, size: 48),
                    const SizedBox(height: 12),
                    const Text('TO\'LOV MUVAFFAQIYATLI', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary, fontSize: 13, letterSpacing: 0.5)),
                    const SizedBox(height: 20),
                    _buildReceiptRow('Tranzaksiya turi:', _getTransactionLabel(transaction['type']?.toString())),
                    const SizedBox(height: 10),
                    _buildReceiptRow('Provayder:', transaction['paymentProvider']?.toString() ?? 'SYSTEM'),
                    const SizedBox(height: 10),
                    _buildReceiptRow('Tranzaksiya ID:', transaction['id']?.toString().substring(0, 18) ?? '—'),
                    const SizedBox(height: 10),
                    _buildReceiptRow('Sana:', transaction['createdAt']?.toString().split('T').first ?? '—'),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Jami miqdor:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(
                          '${isCredit ? "+" : "-"} ${formatAmount(amt)}',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: isCredit ? AppColors.primary : AppColors.danger),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kvitansiya telefonga yuklab olindi (PDF)'), backgroundColor: AppColors.primary),
                  );
                },
                icon: const Icon(Icons.download_rounded),
                label: const Text('Kvitansiyani yuklab olish', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final amt = double.tryParse(transaction['amount'].toString()) ?? 0.0;
    final isCredit = transaction['type'] == 'DEPOSIT' ||
        transaction['type'] == 'PAYOUT' ||
        transaction['type'] == 'FARMER_PAYOUT';

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 1.5),
      ),
      child: InkWell(
        onTap: () => _showReceiptSheet(context, amt, isCredit),
        borderRadius: BorderRadius.circular(16),
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
      ),
    );
  }
}
