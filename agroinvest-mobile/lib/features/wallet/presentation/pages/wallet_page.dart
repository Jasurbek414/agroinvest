import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/wallet_provider.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final _withdrawAmountController = TextEditingController();
  final _bankController = TextEditingController();
  final _cardController = TextEditingController();
  final _depositAmountController = TextEditingController();

  final _withdrawFormKey = GlobalKey<FormState>();
  final _depositFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WalletProvider>(context, listen: false).fetchWallet();
    });
  }

  @override
  void dispose() {
    _withdrawAmountController.dispose();
    _bankController.dispose();
    _cardController.dispose();
    _depositAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context);
    final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String formatAmount(double val) {
      return val.toStringAsFixed(0).replaceAllMapped(formatter, (Match m) => '${m[1]} ') + ' UZS';
    }

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
                        _buildDigitalCard(formatAmount(balanceVal)),
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
                              child: _buildSecondaryBalanceCard('Muzlatilgan sarmoya', formatAmount(frozenVal), AppColors.accent),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSecondaryBalanceCard('Yechib olingan', formatAmount(withdrawnVal), AppColors.textMuted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

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
                              final t = transactions[index];
                              final amt = double.tryParse(t['amount'].toString()) ?? 0.0;
                              final isCredit = t['type'] == 'DEPOSIT' || t['type'] == 'PAYOUT';

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
                                    backgroundColor: isCredit ? AppColors.primaryLight : AppColors.danger.withValues(alpha: 0.08),
                                    child: Icon(
                                      isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                      color: isCredit ? AppColors.primary : AppColors.danger,
                                      size: 16,
                                    ),
                                  ),
                                  title: Text(
                                    _getTransactionLabel(t['type']?.toString()),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                                  ),
                                  subtitle: Text(
                                    t['paymentProvider']?.toString() ?? 'SYSTEM',
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
                            },
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }

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

  Widget _buildDigitalCard(String balanceText) {
    return Container(
      height: 190,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'AgroInvest Card',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              Icon(Icons.nfc_rounded, color: Colors.white.withValues(alpha: 0.8), size: 24),
            ],
          ),
          const Spacer(),
          const Text(
            'Erkin hisob balansi',
            style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            balanceText,
            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '••••  ••••  ••••  8080',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
              const Icon(Icons.spa_rounded, color: Colors.white30, size: 24),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryBalanceCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color),
          ),
        ],
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
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: Form(
            key: _depositFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Hisobni to'ldirish (Simulyatsiya)",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Click / Payme to'lov tizimi orqali hisobingizni mock to'ldirish.",
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _depositAmountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
                  decoration: InputDecoration(
                    labelText: "To'ldirish miqdori (UZS)",
                    prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                    filled: true,
                    fillColor: AppColors.background,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Summani kiriting';
                    final num = double.tryParse(val);
                    if (num == null || num < 5000) return 'Kamida 5000 UZS kiriting';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submitDeposit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("To'ldirish", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  void _submitDeposit() async {
    if (_depositFormKey.currentState!.validate()) {
      Navigator.pop(context);
      final amt = double.parse(_depositAmountController.text);
      final walletProvider = Provider.of<WalletProvider>(context, listen: false);
      final success = await walletProvider.testDeposit(amt);

      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Hisobingiz muvaffaqiyatli to'ldirildi!"), backgroundColor: AppColors.primary),
        );
        _depositAmountController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(walletProvider.error ?? 'Xatolik yuz berdi'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  void _showWithdrawalSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: Form(
            key: _withdrawFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Karta orqali pul yechish',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _withdrawAmountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
                  decoration: InputDecoration(
                    labelText: 'Summa (UZS)',
                    filled: true,
                    fillColor: AppColors.background,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Summani kiriting';
                    final num = double.tryParse(val);
                    if (num == null || num < 5000) return 'Kamida 5000 UZS kiriting';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bankController,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
                  decoration: InputDecoration(
                    labelText: 'Bank nomi (masalan: TBC Bank)',
                    filled: true,
                    fillColor: AppColors.background,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Bank nomini kiriting' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cardController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
                  decoration: InputDecoration(
                    labelText: 'Karta raqami (8600...)',
                    filled: true,
                    fillColor: AppColors.background,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                  validator: (val) => val == null || val.length < 16 ? "Karta raqamini to'liq kiriting" : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submitWithdrawal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("So'rov yuborish", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  void _submitWithdrawal() async {
    if (_withdrawFormKey.currentState!.validate()) {
      Navigator.pop(context);
      final amt = double.parse(_withdrawAmountController.text);
      final bank = _bankController.text;
      final card = _cardController.text;

      final walletProvider = Provider.of<WalletProvider>(context, listen: false);
      final success = await walletProvider.requestWithdrawal(amount: amt, bankName: bank, cardNumber: card);

      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Yechib olish so'rovi qabul qilindi va ko'rib chiqilmoqda"), backgroundColor: AppColors.primary),
        );
        _withdrawAmountController.clear();
        _bankController.clear();
        _cardController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(walletProvider.error ?? 'Xatolik yuz berdi'), backgroundColor: AppColors.danger),
        );
      }
    }
  }
}
