import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../investments/data/investment_repository.dart';
import '../../../kyc/presentation/providers/kyc_provider.dart';
import '../providers/projects_provider.dart';

/// Opens the "invest in this project" flow: role check, a KYC preflight gate
/// (mirrors the backend's unverified-investor rejection so the user finds out
/// before filling the form), then an amount form with a mandatory
/// no-guaranteed-return disclaimer checkbox.
Future<void> showInvestmentBottomSheet(
  BuildContext context, {
  required String projectId,
  required Map<String, dynamic> project,
  required InvestmentRepository investmentRepository,
}) async {
  final auth = Provider.of<AuthProvider>(context, listen: false);
  if (auth.user == null) {
    context.push('/login');
    return;
  }
  if (auth.user!['role'] != 'INVESTOR') {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Faqat investorlar sarmoya kiritishi mumkin')),
    );
    return;
  }

  final kycProvider = Provider.of<KycProvider>(context, listen: false);
  await kycProvider.fetchMe();
  if (!context.mounted) return;
  final kycStatus = kycProvider.me?['kycStatus']?.toString();
  if (kycStatus != 'VERIFIED') {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radius)),
        title: const Text('Shaxsni tasdiqlash kerak', style: AppTypography.sectionTitle),
        content: const Text(
          'Sarmoya kiritish uchun avval KYC (shaxsni tasdiqlash) jarayonini yakunlang.',
          style: AppTypography.bodyMuted,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bekor qilish')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/kyc');
            },
            child: const Text('KYC ga o\'tish'),
          ),
        ],
      ),
    );
    return;
  }

  if (!context.mounted) return;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg))),
    builder: (sheetContext) => _InvestmentForm(
      projectId: projectId,
      project: project,
      investmentRepository: investmentRepository,
    ),
  );
}

class _InvestmentForm extends StatefulWidget {
  final String projectId;
  final Map<String, dynamic> project;
  final InvestmentRepository investmentRepository;

  const _InvestmentForm({required this.projectId, required this.project, required this.investmentRepository});

  @override
  State<_InvestmentForm> createState() => _InvestmentFormState();
}

class _InvestmentFormState extends State<_InvestmentForm> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _disclaimerAccepted = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context);

    final amt = double.parse(_amountController.text);

    try {
      await widget.investmentRepository.createInvestment(projectId: widget.projectId, amount: amt);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sarmoyangiz muvaffaqiyatli qabul qilindi!'), backgroundColor: AppColors.primary),
        );
        Provider.of<ProjectsProvider>(context, listen: false).fetchProjectById(widget.projectId);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.project;
    final minInvestment = double.tryParse(p['minInvestment']?.toString() ?? '');
    final maxInvestment = double.tryParse(p['maxInvestment']?.toString() ?? '');
    final target = double.tryParse(p['targetAmount']?.toString() ?? '') ?? 0;
    final raised = double.tryParse(p['raisedAmount']?.toString() ?? '') ?? 0;
    final remaining = target - raised;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: AppSpacing.xl,
        left: AppSpacing.xl,
        right: AppSpacing.xl,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Sarmoya kiritish summasi', style: AppTypography.h2),
            const SizedBox(height: 6),
            Text(
              minInvestment != null
                  ? 'Minimal: ${formatMoney(minInvestment)} so\'m'
                      '${maxInvestment != null ? " · Maksimal: ${formatMoney(maxInvestment)} so'm" : ""}'
                  : 'Kiritilgan summa hamyoningizdagi balansingizdan chegirib qolinadi.',
              style: AppTypography.caption,
            ),
            const SizedBox(height: AppSpacing.xl),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
              decoration: const InputDecoration(labelText: 'Sarmoya miqdori (UZS)'),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Summani kiriting';
                final amount = double.tryParse(val);
                if (amount == null || amount <= 0) return 'Musbat summa kiriting';
                if (minInvestment != null && amount < minInvestment) {
                  return 'Minimal summa: ${formatMoney(minInvestment)} so\'m';
                }
                if (maxInvestment != null && amount > maxInvestment) {
                  return 'Maksimal summa: ${formatMoney(maxInvestment)} so\'m';
                }
                if (remaining > 0 && amount > remaining) {
                  return 'Loyihani to\'liq moliyalashtirish uchun ${formatMoney(remaining)} so\'m yetarli';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            InkWell(
              onTap: () => setState(() => _disclaimerAccepted = !_disclaimerAccepted),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _disclaimerAccepted,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _disclaimerAccepted = val ?? false),
                    ),
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text(
                          'Ko\'rsatilgan daromad kutilayotgan (taxminiy) ko\'rsatkich bo\'lib, KAFOLATLANMAGANLIGINI tushunaman va qabul qilaman.',
                          style: AppTypography.caption,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: _disclaimerAccepted ? _submit : null,
              child: const Text('Sarmoyani tasdiqlash'),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
