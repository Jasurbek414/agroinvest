import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/animal_type_meta.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/asset_type_meta.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/project_image_gallery.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../kyc/presentation/providers/kyc_provider.dart';
import '../providers/projects_provider.dart';
import '../../data/project_repository.dart';
import '../../../investments/data/investment_repository.dart';

class ProjectDetailPage extends StatefulWidget {
  final String projectId;

  const ProjectDetailPage({super.key, required this.projectId});

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _investmentRepository = InvestmentRepository();
  final _projectRepository = ProjectRepository();
  bool _disclaimerAccepted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProjectsProvider>(context, listen: false)
          .fetchProjectById(widget.projectId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectsProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Loyiha tafsilotlari')),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : provider.error != null
              ? ErrorStateWidget(
                  message: provider.error!,
                  onRetry: () => Provider.of<ProjectsProvider>(context, listen: false).fetchProjectById(widget.projectId),
                )
              : provider.selectedProject == null
                  ? const Center(child: Text('Loyiha topilmadi'))
                  : _buildDetails(provider.selectedProject!),
    );
  }

  Widget _buildDetails(Map<String, dynamic> p) {
    final raised = double.tryParse(p['raisedAmount'].toString()) ?? 0.0;
    final target = double.tryParse(p['targetAmount'].toString()) ?? 1.0;
    final percent = (raised / target).clamp(0.0, 1.0);

    final isFunding = p['status'] == 'FUNDING' || p['status'] == 'APPROVED';
    final isActiveOrFunding = isFunding || p['status'] == 'ACTIVE';
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final assetType = p['assetType']?.toString() ?? 'OTHER';
    final meta = getAssetTypeMeta(assetType);
    final mediaUrls = (p['mediaUrls'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
    final animalType = p['animalType']?.toString();
    final investorSharePct = (p['investorSharePct'] as num?)?.toInt() ?? 70;
    final farmerSharePct = (p['farmerSharePct'] as num?)?.toInt() ?? 30;
    final contributionValue = (p['farmerContributionValue'] as num?)?.toDouble() ?? 0;
    final farmerId = p['farmerId']?.toString();
    final expensePolicy = p['expensePolicy']?.toString();
    final projectTitle = p['title']?.toString();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProjectImageCarousel(
                  imageUrls: mediaUrls,
                  assetType: assetType,
                  height: 220,
                  borderRadius: BorderRadius.zero,
                ),
                Padding(
                  padding: AppSpacing.page,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header banner
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                          border: Border.all(color: AppColors.border, width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _Tag(icon: meta.icon, label: meta.label, color: meta.color),
                                if (animalType != null) ...[
                                  const SizedBox(width: 8),
                                  _Tag(
                                    icon: null,
                                    emoji: getAnimalTypeMeta(animalType).emoji,
                                    label: getAnimalTypeMeta(animalType).label,
                                    color: getAnimalTypeMeta(animalType).color,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(p['title'] ?? '', style: AppTypography.h2),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                const Icon(Icons.person_outline_rounded, size: 16, color: AppColors.textMuted),
                                const SizedBox(width: 6),
                                Text(p['farmerName'] ?? 'Noma\'lum fermer', style: AppTypography.label),
                                if (p['farmerVerified'] == true) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.verified_rounded, size: 15, color: AppColors.primary),
                                ],
                                const SizedBox(width: 14),
                                const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textMuted),
                                const SizedBox(width: 6),
                                Text(p['region'] ?? 'O\'zbekiston', style: AppTypography.label),
                              ],
                            ),
                            if ((double.tryParse(p['farmerRating']?.toString() ?? '0') ?? 0) > 0) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, size: 15, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text((double.tryParse(p['farmerRating'].toString()) ?? 0).toStringAsFixed(1), style: AppTypography.label),
                                  const SizedBox(width: 8),
                                  Text('· ${p['farmerTotalProjects'] ?? 0} ta yakunlangan loyiha', style: AppTypography.caption),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      const Text('Loyiha tavsifi', style: AppTypography.sectionTitle),
                      const SizedBox(height: AppSpacing.sm),
                      Text(p['description'] ?? '', style: AppTypography.bodyMuted.copyWith(height: 1.5)),
                      const SizedBox(height: AppSpacing.xl),

                      // --- Farmer contribution banner ---
                      if (contributionValue > 0) ...[
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(AppSpacing.radius),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.agriculture_rounded, color: AppColors.primaryDark),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Fermer o\'z hissasini qo\'shdi: ${formatMoneySum(contributionValue)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark),
                                    ),
                                    if (p['farmerContributionVerifiedAt'] != null)
                                      const Text('Admin tomonidan tasdiqlangan ✓', style: AppTypography.caption),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],

                      // --- Financial metrics ---
                      const Text('Moliyaviy ko\'rsatkichlar', style: AppTypography.sectionTitle),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(child: _MetricCard(label: 'Kutilayotgan foyda', value: '+${p['expectedReturnPct']}%', color: AppColors.primary)),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(child: _MetricCard(label: 'Muddati', value: '${p['durationDays']} kun', color: AppColors.textDark)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(child: _MetricCard(label: 'Risk darajasi', value: p['riskLevel'] ?? 'MEDIUM', color: Colors.amber.shade800)),
                          Expanded(child: _MetricCard(label: 'Loyiha holati', value: p['status'] ?? 'PENDING', color: AppColors.primary)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // --- Negotiated profit split card ---
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppSpacing.radius),
                          border: Border.all(color: AppColors.border, width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Sof foyda taqsimoti', style: AppTypography.sectionTitle),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: SizedBox(
                                      height: 10,
                                      child: Row(
                                        children: [
                                          Expanded(flex: investorSharePct, child: Container(color: AppColors.primary)),
                                          Expanded(flex: farmerSharePct, child: Container(color: AppColors.accent)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(children: [
                                  Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                                  const SizedBox(width: 6),
                                  Text('Investorlar $investorSharePct%', style: AppTypography.caption),
                                ]),
                                Row(children: [
                                  Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
                                  const SizedBox(width: 6),
                                  Text('Fermer $farmerSharePct%', style: AppTypography.caption),
                                ]),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // --- Funding progress ---
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppSpacing.radius),
                          border: Border.all(color: AppColors.border, width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Yig\'ilgan mablag\'', style: AppTypography.bodyMuted),
                                Text(formatMoneySum(raised), style: AppTypography.label),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: percent,
                                backgroundColor: AppColors.background,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${(percent * 100).toStringAsFixed(0)}% moliyalashtirildi', style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold)),
                                Text('Maqsad: ${formatMoneySum(target)}', style: AppTypography.caption),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // --- Co-investors link ---
                      if ((p['totalInvestors'] as num?) != null && (p['totalInvestors'] as num) > 0)
                        _LinkRow(
                          icon: Icons.groups_rounded,
                          label: 'Sherik investorlar',
                          trailing: '${p['totalInvestors']} ta',
                          onTap: auth.user == null ? null : () => _showInvestorsSheet(context),
                        ),

                      // --- Reports timeline link ---
                      _LinkRow(
                        icon: Icons.history_rounded,
                        label: 'Hisobotlar tarixi',
                        onTap: auth.user == null
                            ? null
                            : () => context.push('/projects/${widget.projectId}/reports', extra: {'title': projectTitle}),
                      ),

                      // --- Expenses link ---
                      _LinkRow(
                        icon: Icons.receipt_long_rounded,
                        label: 'Harajatlar',
                        onTap: auth.user == null
                            ? null
                            : () => context.push('/projects/${widget.projectId}/expenses', extra: {
                                  'title': projectTitle,
                                  'expensePolicy': expensePolicy,
                                  'farmerId': farmerId,
                                }),
                      ),

                      // --- Vet inspections link ---
                      _LinkRow(
                        icon: Icons.health_and_safety_rounded,
                        label: 'Veterinar nazorati',
                        onTap: () => context.push('/projects/${widget.projectId}/vet', extra: {
                          'title': projectTitle,
                          'farmerId': farmerId,
                        }),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // --- Farmer-only quick actions ---
                      if (auth.user != null && auth.user!['role'] == 'FARMER' && farmerId == auth.user!['id']?.toString() && isActiveOrFunding) ...[
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => context.push('/projects/${widget.projectId}/daily-log'),
                                icon: const Icon(Icons.today_rounded, size: 18),
                                label: const Text('Kunlik hisobot', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => context.push('/projects/${widget.projectId}/expenses/add', extra: {'expensePolicy': expensePolicy}),
                                icon: const Icon(Icons.add_card_rounded, size: 18),
                                label: const Text('Harajat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        _buildBottomActions(auth, isFunding, p),
      ],
    );
  }

  Future<void> _showInvestorsSheet(BuildContext context) async {
    List<dynamic> investors = [];
    String? error;
    try {
      investors = await _projectRepository.getProjectInvestors(widget.projectId);
    } catch (e) {
      error = e.toString();
    }
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Sherik investorlar', style: AppTypography.h2),
            const SizedBox(height: AppSpacing.lg),
            if (error != null)
              Text(error, style: const TextStyle(color: AppColors.danger))
            else if (investors.isEmpty)
              const Text('Hozircha investorlar yo\'q', style: AppTypography.bodyMuted)
            else
              ...investors.map((inv) {
                final m = Map<String, dynamic>.from(inv);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      const CircleAvatar(radius: 16, backgroundColor: AppColors.primaryLight, child: Icon(Icons.person_rounded, size: 16, color: AppColors.primary)),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: Text(m['maskedName']?.toString() ?? 'Investor', style: AppTypography.body)),
                      Text('${(m['sharePct'] as num?)?.toStringAsFixed(1) ?? '0'}%', style: AppTypography.label),
                    ],
                  ),
                );
              }),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(AuthProvider auth, bool isFunding, Map<String, dynamic> p) {
    final user = auth.user;

    if (user == null) {
      return Container(
        padding: AppSpacing.page,
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.border, width: 1.5))),
        child: ElevatedButton(
          onPressed: () => context.push('/login'),
          child: const Text('Kirish va sarmoya kiritish'),
        ),
      );
    }

    final role = user['role'];

    if (role == 'FARMER') {
      return Container(
        padding: AppSpacing.page,
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.border, width: 1.5))),
        child: ElevatedButton.icon(
          onPressed: () => context.push('/projects/${widget.projectId}/report'),
          icon: const Icon(Icons.upload_file_rounded),
          label: const Text('Hisobot yuborish'),
        ),
      );
    }

    if (role == 'INVESTOR' && isFunding) {
      return Container(
        padding: AppSpacing.page,
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.border, width: 1.5))),
        child: ElevatedButton(
          onPressed: () => _showInvestSheet(p),
          child: const Text('Sarmoya kiritish'),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _showInvestSheet(Map<String, dynamic> p) async {
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

    // KYC preflight: mirrors the backend gate (InvestmentService now rejects
    // unverified investors) so the user finds out before filling the form.
    final kycProvider = Provider.of<KycProvider>(context, listen: false);
    await kycProvider.fetchMe();
    if (!mounted) return;
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

    _disclaimerAccepted = false;

    final minInvestment = double.tryParse(p['minInvestment']?.toString() ?? '');
    final maxInvestment = double.tryParse(p['maxInvestment']?.toString() ?? '');
    final target = double.tryParse(p['targetAmount']?.toString() ?? '') ?? 0;
    final raised = double.tryParse(p['raisedAmount']?.toString() ?? '') ?? 0;
    final remaining = target - raised;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg))),
      builder: (context) {
        return StatefulBuilder(builder: (context, setSheetState) {
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
                    onTap: () => setSheetState(() => _disclaimerAccepted = !_disclaimerAccepted),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _disclaimerAccepted,
                            activeColor: AppColors.primary,
                            onChanged: (val) => setSheetState(() => _disclaimerAccepted = val ?? false),
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
                    onPressed: _disclaimerAccepted ? _submitInvestment : null,
                    child: const Text('Sarmoyani tasdiqlash'),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  void _submitInvestment() async {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context);

      final amt = double.parse(_amountController.text);

      try {
        await _investmentRepository.createInvestment(projectId: widget.projectId, amount: amt);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sarmoyangiz muvaffaqiyatli qabul qilindi!'), backgroundColor: AppColors.primary),
          );
          Provider.of<ProjectsProvider>(context, listen: false).fetchProjectById(widget.projectId);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
          );
        }
      }
    }
  }
}

class _Tag extends StatelessWidget {
  final IconData? icon;
  final String? emoji;
  final String label;
  final Color color;

  const _Tag({this.icon, this.emoji, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, size: 13, color: color),
          if (emoji != null) Text(emoji!, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.caption),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback? onTap;

  const _LinkRow({required this.icon, required this.label, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radius),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(label, style: AppTypography.body)),
            if (trailing != null) ...[
              Text(trailing!, style: AppTypography.caption),
              const SizedBox(width: 4),
            ],
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}
