import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/shimmer_loader.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../projects/data/project_repository.dart';
import '../../../investments/data/investment_repository.dart';
import '../providers/dispute_provider.dart';

const _disputeTypes = {
  'PROJECT_ABANDONED': "Loyiha e'tiborsiz qoldirilgan",
  'NO_REPORTS': 'Hisobotlar yuborilmayapti',
  'FUNDS_MISUSE': "Mablag' noto'g'ri ishlatilgan",
  'PAYOUT_DELAY': "To'lov kechikmoqda",
  'OTHER': 'Boshqa',
};

class DisputesPage extends StatefulWidget {
  const DisputesPage({super.key});

  @override
  State<DisputesPage> createState() => _DisputesPageState();
}

class _DisputesPageState extends State<DisputesPage> {
  final _projectRepository = ProjectRepository();
  final _investmentRepository = InvestmentRepository();
  final _descriptionController = TextEditingController();

  List<dynamic> _projectOptions = [];
  List<dynamic> _investorOptions = [];
  String? _selectedProjectId;
  Map<String, dynamic>? _against; // {'id':..., 'name':...}
  String _disputeType = 'PROJECT_ABANDONED';
  bool _loadingProjects = true;

  bool get _isInvestor => Provider.of<AuthProvider>(context, listen: false).user?['role'] == 'INVESTOR';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DisputeProvider>(context, listen: false).fetchMyDisputes();
      _loadProjectOptions();
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadProjectOptions() async {
    setState(() => _loadingProjects = true);
    try {
      final List<dynamic> options = [
        {'id': 'GENERAL', 'title': "Platforma bo'yicha umumiy taklif / shikoyat"}
      ];

      if (_isInvestor) {
        final investments = await _investmentRepository.getMyInvestments();
        final seen = <String, dynamic>{};
        for (final inv in investments) {
          seen[inv['projectId']] = {'id': inv['projectId'], 'title': inv['projectTitle']};
        }
        options.addAll(seen.values);
      } else {
        final projects = await _projectRepository.getMyProjects();
        options.addAll(projects.map((p) => {'id': p['id'], 'title': p['title']}));
      }
      _projectOptions = options;
    } catch (e) {
      _projectOptions = [
        {'id': 'GENERAL', 'title': "Platforma bo'yicha umumiy taklif / shikoyat"}
      ];
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Loyihalarni yuklashda xatolik: $e"), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingProjects = false);
    }
  }

  Future<void> _onProjectSelected(String? projectId) async {
    setState(() {
      _selectedProjectId = projectId;
      _against = null;
      _investorOptions = [];
    });
    if (projectId == null || projectId == 'GENERAL') {
      if (projectId == 'GENERAL') {
        setState(() => _against = {'id': null, 'name': 'Platforma'});
      }
      return;
    }

    try {
      if (_isInvestor) {
        final project = await _projectRepository.getProjectById(projectId);
        setState(() => _against = {'id': project['farmerId'], 'name': project['farmerName']});
      } else {
        final investments = await _investmentRepository.getProjectInvestments(projectId);
        setState(() {
          _investorOptions = investments
              .map((inv) => {'id': inv['investorId'], 'name': inv['investorName']})
              .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Loyiha tafsilotlarini yuklashda xatolik: $e"), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _submit() async {
    final isGeneral = _selectedProjectId == 'GENERAL';
    if (_selectedProjectId == null || (!isGeneral && _against == null) || _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Barcha maydonlarni to'ldiring"), backgroundColor: AppColors.danger),
      );
      return;
    }

    final provider = Provider.of<DisputeProvider>(context, listen: false);
    final success = await provider.fileDispute(
      projectId: isGeneral ? null : _selectedProjectId,
      againstUserId: isGeneral ? null : _against!['id'],
      disputeType: _disputeType,
      description: _descriptionController.text.trim(),
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Murojaatingiz qabul qilindi'), backgroundColor: AppColors.primary),
      );
      _descriptionController.clear();
      setState(() {
        _selectedProjectId = null;
        _against = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Xatolik yuz berdi'), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final disputeProvider = Provider.of<DisputeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : AppColors.border;
    final textColor = isDark ? Colors.white : AppColors.textDark;
    final subTextColor = isDark ? const Color(0xFF94A3B8) : AppColors.textMuted;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Shikoyatlar & Takliflar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: cardBg,
        elevation: 0,
        foregroundColor: textColor,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.gavel_rounded, color: AppColors.danger, size: 22),
                    const SizedBox(width: 8),
                    Text('Yangi shikoyat / taklif', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                  ],
                ),
                const SizedBox(height: 16),
                if (_loadingProjects)
                  const Center(child: CircularProgressIndicator(color: AppColors.primary))
                else ...[
                  DropdownButtonFormField<String>(
                    value: _selectedProjectId,
                    dropdownColor: cardBg,
                    style: TextStyle(color: textColor, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Loyiha',
                      labelStyle: TextStyle(color: subTextColor, fontSize: 13),
                      prefixIcon: const Icon(Icons.business_center_outlined, color: AppColors.primary, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _projectOptions
                        .map<DropdownMenuItem<String>>((p) => DropdownMenuItem(
                              value: p['id'] as String,
                              child: Text(
                                p['title'] ?? '',
                                style: TextStyle(color: textColor, fontSize: 13),
                              ),
                            ))
                        .toList(),
                    onChanged: _onProjectSelected,
                  ),
                  if (!_isInvestor && _selectedProjectId != null && _selectedProjectId != 'GENERAL') ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _against?['id'],
                      dropdownColor: cardBg,
                      style: TextStyle(color: textColor, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Shikoyat qilinayotgan investor',
                        labelStyle: TextStyle(color: subTextColor, fontSize: 13),
                        prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _investorOptions
                          .map<DropdownMenuItem<String>>((o) => DropdownMenuItem(
                                value: o['id'] as String,
                                child: Text(
                                  o['name'] ?? '',
                                  style: TextStyle(color: textColor, fontSize: 13),
                                ),
                              ))
                          .toList(),
                      onChanged: (id) {
                        final found = _investorOptions.firstWhere((o) => o['id'] == id, orElse: () => {});
                        setState(() => _against = found.isEmpty ? null : found);
                      },
                    ),
                  ],
                  if (_isInvestor && _against != null && _selectedProjectId != 'GENERAL') ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withOpacity(isDark ? 0.08 : 0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person_rounded, color: AppColors.primary, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Shikoyat qilinadigan fermer: ${_against!['name']}',
                              style: TextStyle(fontSize: 12, color: isDark ? AppColors.primaryLight : AppColors.primaryDark, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _disputeType,
                    dropdownColor: cardBg,
                    style: TextStyle(color: textColor, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Murojaat turi',
                      labelStyle: TextStyle(color: subTextColor, fontSize: 13),
                      prefixIcon: const Icon(Icons.category_outlined, color: AppColors.primary, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _disputeTypes.entries
                        .map((e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(
                                e.value,
                                style: TextStyle(color: textColor, fontSize: 13),
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _disputeType = v ?? _disputeType),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    style: TextStyle(color: textColor, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Tafsilotlar',
                      labelStyle: TextStyle(color: subTextColor, fontSize: 13),
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: disputeProvider.submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(disputeProvider.submitting ? 'Yuborilmoqda...' : 'Yuborish', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Mening shikoyat va takliflarim', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
          const SizedBox(height: 12),
          if (disputeProvider.loading)
            const Column(children: [ShimmerCard(), ShimmerCard()])
          else if (disputeProvider.disputes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text("Shikoyat va takliflar topilmadi", style: TextStyle(color: subTextColor))),
            )
          else
            ...disputeProvider.disputes.map((d) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              d['projectTitle'] ?? 'Platforma (Umumiy)',
                              style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight.withOpacity(isDark ? 0.08 : 0.4),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              d['status'] ?? 'OPEN',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? AppColors.primaryLight : AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        d['description'] ?? '',
                        style: TextStyle(fontSize: 13, color: subTextColor),
                      ),
                      if (d['resolution'] != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withOpacity(isDark ? 0.08 : 0.4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Yechim: ${d['resolution']}',
                            style: TextStyle(fontSize: 12, color: isDark ? AppColors.primaryLight : AppColors.primaryDark),
                          ),
                        ),
                      ],
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}
