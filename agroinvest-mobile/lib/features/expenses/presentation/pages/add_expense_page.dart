import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/image_upload_picker.dart';
import '../../data/expense_repository.dart';
import 'project_expenses_page.dart' show kExpenseCategoryMeta;

/// Farmer form: one running expense with receipt photos. Payer is decided by
/// the project's expense policy server-side; only MIXED projects show a chooser.
class AddExpensePage extends StatefulWidget {
  final String projectId;
  final String? expensePolicy;

  const AddExpensePage({super.key, required this.projectId, this.expensePolicy});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final _repository = ExpenseRepository();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _category = 'FEED';
  DateTime _expenseDate = DateTime.now();
  List<String> _receiptUrls = [];
  String _payerSource = 'INVESTOR_BUDGET';
  bool _submitting = false;
  String? _error;

  bool get _isMixed => widget.expensePolicy == 'MIXED';

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _repository.submitExpense(
        projectId: widget.projectId,
        category: _category,
        amount: double.parse(_amountController.text.replaceAll(' ', '')),
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        receiptUrls: _receiptUrls,
        expenseDate: DateFormat('yyyy-MM-dd').format(_expenseDate),
        payerSource: _isMixed ? _payerSource : null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harajat yuborildi - admin tasdiqlashini kuting'), backgroundColor: AppColors.primary),
      );
      context.pop(true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Harajat kiritish')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.page,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.danger.withOpacity(0.2)),
                    ),
                    child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                const Text('Harajat toifasi', style: AppTypography.label),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: kExpenseCategoryMeta.entries.map((entry) {
                    final selected = _category == entry.key;
                    return ChoiceChip(
                      selected: selected,
                      onSelected: (_) => setState(() => _category = entry.key),
                      avatar: Icon(entry.value.$2, size: 16, color: selected ? AppColors.primary : AppColors.textMuted),
                      label: Text(entry.value.$1),
                      showCheckmark: false,
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.xl),

                const Text("Summa (so'm)", style: AppTypography.label),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
                  decoration: const InputDecoration(
                    hintText: '500 000',
                    prefixIcon: Icon(Icons.payments_rounded, color: AppColors.textMuted),
                  ),
                  validator: (val) {
                    final parsed = double.tryParse((val ?? '').replaceAll(' ', ''));
                    if (parsed == null || parsed <= 0) return 'Summani kiriting';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xl),

                const Text('Harajat sanasi', style: AppTypography.label),
                const SizedBox(height: AppSpacing.sm),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _expenseDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 90)),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _expenseDate = picked);
                  },
                  borderRadius: BorderRadius.circular(AppSpacing.radius),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppSpacing.radius),
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, color: AppColors.textMuted, size: 20),
                        const SizedBox(width: AppSpacing.md),
                        Text(DateFormat('dd.MM.yyyy').format(_expenseDate), style: AppTypography.body),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                if (_isMixed) ...[
                  const Text("Kim to'ladi?", style: AppTypography.label),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _PayerCard(
                          selected: _payerSource == 'INVESTOR_BUDGET',
                          icon: Icons.groups_rounded,
                          label: 'Loyiha byudjeti',
                          onTap: () => setState(() => _payerSource = 'INVESTOR_BUDGET'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _PayerCard(
                          selected: _payerSource == 'FARMER',
                          icon: Icons.person_rounded,
                          label: "O'zim to'ladim",
                          onTap: () => setState(() => _payerSource = 'FARMER'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],

                const Text('Izoh (ixtiyoriy)', style: AppTypography.label),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textDark),
                  decoration: const InputDecoration(hintText: 'Masalan: 2 tonna beda sotib olindi'),
                ),
                const SizedBox(height: AppSpacing.xl),

                const Text('Chek / hujjat fotosi', style: AppTypography.label),
                const SizedBox(height: AppSpacing.sm),
                ImageUploadPicker(
                  category: 'expense',
                  onChanged: (urls) => _receiptUrls = urls,
                ),
                const SizedBox(height: AppSpacing.xxl),

                ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Yuborish'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PayerCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PayerCard({required this.selected, required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radius),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? AppColors.primary : AppColors.textMuted),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: selected ? AppColors.primaryDark : AppColors.textDark,
            )),
          ],
        ),
      ),
    );
  }
}
