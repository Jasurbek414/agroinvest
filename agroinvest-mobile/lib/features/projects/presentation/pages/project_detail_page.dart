import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/asset_type_meta.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/project_image_gallery.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/projects_provider.dart';
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
      appBar: AppBar(
        title: const Text('Loyiha tafsilotlari', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textDark,
        centerTitle: true,
      ),
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

    final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String formatAmount(double val) {
      return val.toStringAsFixed(0).replaceAllMapped(formatter, (Match m) => '${m[1]} ') + ' UZS';
    }

    final isFunding = p['status'] == 'FUNDING' || p['status'] == 'APPROVED';
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final assetType = p['assetType']?.toString() ?? 'OTHER';
    final meta = getAssetTypeMeta(assetType);
    final mediaUrls = (p['mediaUrls'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Photo/video evidence carousel - previously farmers uploaded
                // photos that investors could never actually see anywhere.
                ProjectImageCarousel(
                  imageUrls: mediaUrls,
                  assetType: assetType,
                  height: 220,
                  borderRadius: BorderRadius.zero,
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Minimalist Premium Banner Header
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border, width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: meta.color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(meta.icon, size: 13, color: meta.color),
                                  const SizedBox(width: 5),
                                  Text(
                                    meta.label,
                                    style: TextStyle(color: meta.color, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              p['title'] ?? '',
                              style: const TextStyle(color: AppColors.textDark, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.person_outline_rounded, size: 16, color: AppColors.textMuted),
                                const SizedBox(width: 6),
                                Text(
                                  p['farmerName'] ?? 'Noma\'lum fermer',
                                  style: const TextStyle(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 14),
                                const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textMuted),
                                const SizedBox(width: 6),
                                Text(
                                  p['region'] ?? 'O\'zbekiston',
                                  style: const TextStyle(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Description
                      const Text(
                        'Loyiha tavsifi',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        p['description'] ?? '',
                        style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.5, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 24),

                      // Financial metrics
                      const Text(
                        'Moliyaviy ko\'rsatkichlar',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard('Kutilayotgan foyda', '+${p['expectedReturnPct']}%', AppColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricCard('Muddati', '${p['durationDays']} kun', AppColors.textDark),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard('Risk darajasi', p['riskLevel'] ?? 'MEDIUM', Colors.amber.shade800),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricCard('Loyiha holati', p['status'] ?? 'PENDING', AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Progress Bar Container
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border, width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Yig\'ilgan mablag\'', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
                                Text(formatAmount(raised), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.textDark)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: percent,
                                backgroundColor: AppColors.background,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${(percent * 100).toStringAsFixed(0)}% moliyalashtirildi', style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold)),
                                Text('Maqsad: ${formatAmount(target)}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom actions area
        _buildBottomActions(auth, isFunding, p),
      ],
    );
  }

  Widget _buildBottomActions(AuthProvider auth, bool isFunding, Map<String, dynamic> p) {
    final user = auth.user;

    if (user == null) {
      // Guest
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
        ),
        child: ElevatedButton(
          onPressed: () => context.push('/login'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text('Kirish va sarmoya kiritish', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ),
      );
    }

    final role = user['role'];

    if (role == 'FARMER') {
      // Farmer
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
        ),
        child: ElevatedButton.icon(
          onPressed: () => context.push('/projects/${widget.projectId}/report'),
          icon: const Icon(Icons.upload_file_rounded),
          label: const Text('Hisobot yuborish', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      );
    }

    if (role == 'INVESTOR' && isFunding) {
      // Investor
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
        ),
        child: ElevatedButton(
          onPressed: () => _showInvestSheet(p),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text('Sarmoya kiritish', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildMetricCard(String label, String value, Color valColor) {
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
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: valColor)),
        ],
      ),
    );
  }

  void _showInvestSheet(Map<String, dynamic> p) {
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

    final minInvestment = double.tryParse(p['minInvestment']?.toString() ?? '');
    final maxInvestment = double.tryParse(p['maxInvestment']?.toString() ?? '');
    final target = double.tryParse(p['targetAmount']?.toString() ?? '') ?? 0;
    final raised = double.tryParse(p['raisedAmount']?.toString() ?? '') ?? 0;
    final remaining = target - raised;

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
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Sarmoya kiritish summasi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 6),
                Text(
                  minInvestment != null
                      ? 'Minimal: ${minInvestment.toStringAsFixed(0)} UZS'
                          '${maxInvestment != null ? " · Maksimal: ${maxInvestment.toStringAsFixed(0)} UZS" : ""}'
                      : 'Kiritilgan summa hamyoningizdagi balansingizdan chegirib qolinadi.',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
                  decoration: InputDecoration(
                    labelText: 'Sarmoya miqdori (UZS)',
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
                  // Mirrors the backend's own limit checks (InvestmentService.createInvestment)
                  // client-side, so the user finds out before submitting instead of via a
                  // generic server error.
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Summani kiriting';
                    final amount = double.tryParse(val);
                    if (amount == null || amount <= 0) return 'Musbat summa kiriting';
                    if (minInvestment != null && amount < minInvestment) {
                      return 'Minimal summa: ${minInvestment.toStringAsFixed(0)} UZS';
                    }
                    if (maxInvestment != null && amount > maxInvestment) {
                      return 'Maksimal summa: ${maxInvestment.toStringAsFixed(0)} UZS';
                    }
                    if (remaining > 0 && amount > remaining) {
                      return 'Loyihani to\'liq moliyalashtirish uchun ${remaining.toStringAsFixed(0)} UZS yetarli';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submitInvestment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Sarmoyani tasdiqlash', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
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
            const SnackBar(
              content: Text('Sarmoyangiz muvaffaqiyatli qabul qilindi!'),
              backgroundColor: AppColors.primary,
            ),
          );
          Provider.of<ProjectsProvider>(context, listen: false)
              .fetchProjectById(widget.projectId);
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
