import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/shimmer_loader.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/expense_repository.dart';

/// Category meta shared by the feed and the add-form dropdown.
const Map<String, (String, IconData)> kExpenseCategoryMeta = {
  'FEED': ('Yem-xashak', Icons.grass_rounded),
  'MEDICINE': ('Dori-darmon', Icons.medication_rounded),
  'VET_SERVICE': ('Veterinar xizmati', Icons.health_and_safety_rounded),
  'TRANSPORT': ('Transport', Icons.local_shipping_rounded),
  'LABOR': ('Ish haqi', Icons.engineering_rounded),
  'EQUIPMENT': ('Jihozlar', Icons.construction_rounded),
  'OTHER': ('Boshqa', Icons.receipt_long_rounded),
};

/// Per-project expense feed: owner, investors, and staff see it; the owning
/// farmer additionally gets an "add expense" action.
class ProjectExpensesPage extends StatefulWidget {
  final String projectId;
  final String? projectTitle;
  final String? expensePolicy;
  final String? farmerId;

  const ProjectExpensesPage({
    super.key,
    required this.projectId,
    this.projectTitle,
    this.expensePolicy,
    this.farmerId,
  });

  @override
  State<ProjectExpensesPage> createState() => _ProjectExpensesPageState();
}

class _ProjectExpensesPageState extends State<ProjectExpensesPage> {
  final _repository = ExpenseRepository();
  List<dynamic>? _expenses;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _repository.fetchProjectExpenses(widget.projectId);
      if (mounted) setState(() => _expenses = data);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _isOwner {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    return user != null && widget.farmerId != null && user['id']?.toString() == widget.farmerId;
  }

  @override
  Widget build(BuildContext context) {
    final approvedTotal = (_expenses ?? [])
        .where((e) => e['status'] == 'APPROVED')
        .fold<num>(0, (sum, e) => sum + ((e['amount'] as num?) ?? 0));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Harajatlar')),
      floatingActionButton: _isOwner
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              onPressed: () async {
                final added = await context.push<bool>(
                  '/projects/${widget.projectId}/expenses/add',
                  extra: {'expensePolicy': widget.expensePolicy},
                );
                if (added == true) _load();
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Harajat kiritish', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
      body: SafeArea(
        child: _loading
            ? const Padding(padding: AppSpacing.page, child: ShimmerList(count: 5))
            : _error != null
                ? ErrorStateWidget(message: _error!, onRetry: _load)
                : RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: _load,
                    child: (_expenses == null || _expenses!.isEmpty)
                        ? ListView(
                            children: const [
                              SizedBox(height: 120),
                              EmptyState(
                                icon: Icons.receipt_long_rounded,
                                title: 'Harajatlar yo\'q',
                                subtitle: 'Bu loyihada hali harajat kiritilmagan',
                              ),
                            ],
                          )
                        : ListView(
                            padding: AppSpacing.page,
                            children: [
                              if (widget.projectTitle != null) ...[
                                Text(widget.projectTitle!, style: AppTypography.h2),
                                const SizedBox(height: AppSpacing.sm),
                              ],
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(AppSpacing.radius),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Tasdiqlangan harajatlar jami:', style: AppTypography.bodyMuted),
                                    Text(formatMoneySum(approvedTotal),
                                        style: AppTypography.label.copyWith(color: AppColors.primaryDark)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              ..._expenses!.map((e) => _ExpenseTile(expense: Map<String, dynamic>.from(e))),
                              const SizedBox(height: 80),
                            ],
                          ),
                  ),
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final Map<String, dynamic> expense;
  const _ExpenseTile({required this.expense});

  @override
  Widget build(BuildContext context) {
    final meta = kExpenseCategoryMeta[expense['category']] ?? kExpenseCategoryMeta['OTHER']!;
    final isFarmerPaid = expense['payerSource'] == 'FARMER';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(meta.$2, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(meta.$1, style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
                    Text(formatDate(expense['expenseDate']), style: AppTypography.caption),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(formatMoneySum(expense['amount']), style: AppTypography.label),
                  const SizedBox(height: 4),
                  StatusBadge(status: expense['status']?.toString() ?? 'PENDING'),
                ],
              ),
            ],
          ),
          if ((expense['description'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(expense['description'].toString(), style: AppTypography.bodyMuted),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                isFarmerPaid ? Icons.person_rounded : Icons.groups_rounded,
                size: 14,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                isFarmerPaid ? "Fermer to'lagan (qaytariladi)" : 'Loyiha byudjetidan',
                style: AppTypography.caption,
              ),
              const Spacer(),
              if ((expense['receiptUrls'] as List?)?.isNotEmpty == true)
                Row(
                  children: [
                    const Icon(Icons.attach_file_rounded, size: 14, color: AppColors.textMuted),
                    Text('${(expense['receiptUrls'] as List).length} ta chek', style: AppTypography.caption),
                  ],
                ),
            ],
          ),
          if ((expense['reviewComment'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Admin izohi: ${expense['reviewComment']}', style: AppTypography.caption),
            ),
          ],
        ],
      ),
    );
  }
}
