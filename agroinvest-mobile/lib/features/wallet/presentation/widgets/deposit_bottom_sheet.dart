import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/image_upload_picker.dart';
import '../../../../core/network/dio_client.dart';
import '../providers/wallet_provider.dart';

/// Manual top-up request form: real Payme/Click gateway integration is dormant
/// (no merchant credentials configured), so for now the user declares an amount
/// and optionally attaches a bank-transfer receipt photo - staff then reviews it
/// in the web admin's "To'lov so'rovlari" queue before the wallet is credited.
class DepositBottomSheet extends StatefulWidget {
  const DepositBottomSheet({super.key});

  @override
  State<DepositBottomSheet> createState() => _DepositBottomSheetState();
}

class _DepositBottomSheetState extends State<DepositBottomSheet> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  List<String> _proofUrls = [];
  bool _submitting = false;

  String? _bankDetails;
  String? _bankDocUrl;
  bool _loadingDetails = false;

  @override
  void initState() {
    super.initState();
    _fetchBankDetails();
  }

  Future<void> _fetchBankDetails() async {
    setState(() => _loadingDetails = true);
    try {
      final dio = DioClient().dio;
      final res = await dio.get('/settings/bank-details');
      if (res.statusCode == 200) {
        setState(() {
          _bankDetails = res.data['data']['bankDetails']?.toString();
          _bankDocUrl = res.data['data']['bankDocUrl']?.toString();
        });
      }
    } catch (_) {}
    finally {
      if (mounted) setState(() => _loadingDetails = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24,
        left: 24,
        right: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Hisobni to'ldirish",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 6),
            const Text(
              "Kompaniya hisob raqamiga to'lov qilib, summani va to'lov cheki (kvitansiyasi) rasmini yuboring - admin tasdiqlagach balansingiz to'ldiriladi.",
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),

            if (_loadingDetails) ...[
              const Center(child: Padding(
                padding: EdgeInsets.all(12.0),
                child: CircularProgressIndicator(color: AppColors.primary),
              )),
              const SizedBox(height: 16),
            ] else if (_bankDetails != null && _bankDetails!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_balance_rounded, color: AppColors.primary, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          "Kompaniya bank hisob raqami:",
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _bankDetails!,
                      style: TextStyle(fontSize: 11, color: Colors.grey[900], height: 1.4, fontFamily: 'monospace', fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _bankDetails!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Hisob raqami rekvizitlari nusxalandi!")),
                              );
                            },
                            icon: const Icon(Icons.copy_rounded, size: 12),
                            label: const Text("Nusxalash", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        if (_bankDocUrl != null && _bankDocUrl!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final uri = Uri.parse(_bankDocUrl!);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                }
                              },
                              icon: const Icon(Icons.file_download_rounded, size: 12),
                              label: const Text("Hujjatni yuklash", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary, width: 1.2),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            TextFormField(
              controller: _amountController,
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
                if (num == null || num < 1000) return 'Kamida 1000 UZS kiriting';
                return null;
              },
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("To'lov cheki (ixtiyoriy)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
            ),
            const SizedBox(height: 8),
            ImageUploadPicker(
              category: 'deposit',
              maxImages: 1,
              onChanged: (urls) => setState(() => _proofUrls = urls),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(_submitting ? 'Yuborilmoqda...' : "So'rov yuborish", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);

    final amt = double.parse(_amountController.text);
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final success = await walletProvider.requestDeposit(amount: amt, proofUrl: _proofUrls.isNotEmpty ? _proofUrls.first : null);

    if (!mounted) return;
    Navigator.pop(context);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("So'rov yuborildi, admin tekshiruvidan so'ng hamyoningizga tushadi"), backgroundColor: AppColors.primary),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(walletProvider.error ?? 'Xatolik yuz berdi'), backgroundColor: AppColors.danger),
      );
    }
  }
}
