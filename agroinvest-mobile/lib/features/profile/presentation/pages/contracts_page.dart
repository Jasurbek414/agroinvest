import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/format.dart';
import '../../../investments/presentation/providers/investment_provider.dart';
import '../../../../core/network/dio_client.dart';

class ContractsPage extends StatefulWidget {
  const ContractsPage({super.key});

  @override
  State<ContractsPage> createState() => _ContractsPage();
}

class _ContractsPage extends State<ContractsPage> {
  final _dio = DioClient().dio;
  bool _signing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InvestmentProvider>(context, listen: false).fetchMyInvestments();
    });
  }

  Future<void> _signContract(String investmentId) async {
    final otpController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    // Open verification dialog (imzolashni OTP bilan tasdiqlash)
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Shartnomani imzolash', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Ushbu shartnomani imzolash uchun telefoningizga yuborilgan tasdiqlash kodini kiriting (Sinov kodi: 1234):',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'SMS kod',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.sms_outlined),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Kodni kiriting';
                    if (val.trim() != '1234') return 'Kod noto\'g\'ri';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Orqaga'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Tasdiqlash'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _signing = true);
    try {
      await _dio.post('/investments/$investmentId/sign');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shartnoma muvaffaqiyatli imzolandi!'), backgroundColor: AppColors.primary),
      );
      Provider.of<InvestmentProvider>(context, listen: false).fetchMyInvestments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imzolashda xatolik: $e'), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _signing = false);
    }
  }

  void _viewAgreementDetails(Map<String, dynamic> inv) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final amountVal = double.tryParse(inv['amount']?.toString() ?? '0') ?? 0.0;
        final share = double.tryParse(inv['sharePct']?.toString() ?? '0') ?? 0.0;
        final formattedAmount = '${formatMoney(amountVal)} UZS';

        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Sarmoya Shartnomasi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'INVESTITSIYA KELISHUVI',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.primaryDark),
                ),
                const SizedBox(height: 12),
                Text(
                  'Shartnoma ID: ${inv['id']}\nLoyiha: ${inv['projectTitle']}\nSana: ${inv['createdAt']?.toString().split('T').first ?? ''}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.5),
                ),
                const SizedBox(height: 20),
                const Text(
                  '1. SHARTNOMA MAVZUSI',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                ),
                const SizedBox(height: 6),
                Text(
                  'Ushbu shartnomaga muvofiq, Investor loyihani rivojlantirish uchun jami $formattedAmount miqdorida sarmoya kiritadi. Loyiha muvaffaqiyatli yakunlangandan so‘ng, investor loyihaning jami ulushidan ${share.toStringAsFixed(4)}% daromad olish huquqiga ega bo‘ladi.',
                  style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  '2. TOMONLARNING HUQUQ VA MAJBURIYATLARI',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Fermer olingan mablag‘larni faqatgina belgilangan harajatlar smetasi bo‘yicha ishlatishga, hisobotlarni va veterinar nazorati hujjatlarini o‘z vaqtida taqdim etishga majburdir. Investor loyiha holatini masofaviy kuzatish huquqiga ega.',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  '3. FORS-MAJOR VA NIZOLAR',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tabiiy ofatlar va kutilmagan hayvon kasalliklari fors-major hisoblanadi. Kelib chiqqan har qanday nizo birinchi navbatda platforma administratorlari yordamida muzokaralar yo‘li bilan, aks holda qonun hujjatlariga muvofiq sudda ko‘rib chiqiladi.',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.5),
                ),
                const SizedBox(height: 32),
                if (inv['contractSignedAt'] != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_rounded, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('SHARTNOMA IMZOLANGAN', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12)),
                              const SizedBox(height: 2),
                              Text('Sana: ${inv['contractSignedAt']?.toString().split('T').first}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _signContract(inv['id']);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Shartnomani imzolash', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
                const SizedBox(height: 30),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final investmentProvider = Provider.of<InvestmentProvider>(context);
    final investments = investmentProvider.investments;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Elektron shartnomalar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textDark,
        centerTitle: true,
      ),
      body: investmentProvider.loading || _signing
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : investments.isEmpty
              ? const Center(
                  child: Text(
                    'Shartnomalar mavjud emas.\nAvval loyihaga sarmoya kiriting.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: investments.length,
                  itemBuilder: (context, index) {
                    final inv = investments[index];
                    final isSigned = inv['contractSignedAt'] != null;
                    final amountVal = double.tryParse(inv['amount']?.toString() ?? '0') ?? 0.0;
                    final formattedAmount = '${formatMoney(amountVal)} UZS';

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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  inv['projectTitle'] ?? 'Loyiha',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isSigned ? AppColors.primary.withOpacity(0.08) : AppColors.accent.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: isSigned ? AppColors.primary.withOpacity(0.1) : AppColors.accent.withOpacity(0.1)),
                                ),
                                child: Text(
                                  isSigned ? 'Imzolangan' : 'Kutilmoqda',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isSigned ? AppColors.primary : AppColors.accent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Sarmoya miqdori', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                  const SizedBox(height: 2),
                                  Text(formattedAmount, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('Ulush', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                  const SizedBox(height: 2),
                                  Text('${(double.tryParse(inv['sharePct']?.toString() ?? '0') ?? 0.0).toStringAsFixed(4)}%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 24, color: AppColors.border),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _viewAgreementDetails(inv),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('Ko\'rish', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ),
                              ),
                              if (!isSigned) ...[
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _signContract(inv['id']),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      elevation: 0,
                                    ),
                                    child: const Text('Imzolash', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
