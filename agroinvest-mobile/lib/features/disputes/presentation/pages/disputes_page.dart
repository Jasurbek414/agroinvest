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
      if (_isInvestor) {
        final investments = await _investmentRepository.getMyInvestments();
        final seen = <String, dynamic>{};
        for (final inv in investments) {
          seen[inv['projectId']] = {'id': inv['projectId'], 'title': inv['projectTitle']};
        }
        _projectOptions = seen.values.toList();
      } else {
        final projects = await _projectRepository.getMyProjects();
        _projectOptions = projects.map((p) => {'id': p['id'], 'title': p['title']}).toList();
      }
    } catch (_) {
      _projectOptions = [];
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
    if (projectId == null) return;

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
    } catch (_) {
      // leave picker empty on failure - user can retry by reselecting
    }
  }

  Future<void> _submit() async {
    if (_selectedProjectId == null || _against == null || _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Barcha maydonlarni to'ldiring"), backgroundColor: AppColors.danger),
      );
      return;
    }

    final provider = Provider.of<DisputeProvider>(context, listen: false);
    final success = await provider.fileDispute(
      projectId: _selectedProjectId!,
      againstUserId: _against!['id'],
      disputeType: _disputeType,
      description: _descriptionController.text.trim(),
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shikoyatingiz qabul qilindi'), backgroundColor: AppColors.primary),
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Shikoyatlar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textDark,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Yangi shikoyat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
                const SizedBox(height: 16),
                if (_loadingProjects)
                  const Center(child: CircularProgressIndicator(color: AppColors.primary))
                else if (_projectOptions.isEmpty)
                  Text(
                    _isInvestor
                        ? "Shikoyat ochish uchun avval biror loyihaga sarmoya kiritgan bo'lishingiz kerak."
                        : "Shikoyat ochish uchun avval tasdiqlangan loyihangiz bo'lishi kerak.",
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  )
                else ...[
                  DropdownButtonFormField<String>(
                    value: _selectedProjectId,
                    decoration: const InputDecoration(labelText: 'Loyiha', border: OutlineInputBorder()),
                    items: _projectOptions
                        .map<DropdownMenuItem<String>>((p) => DropdownMenuItem(value: p['id'] as String, child: Text(p['title'] ?? '')))
                        .toList(),
                    onChanged: _onProjectSelected,
                  ),
                  if (!_isInvestor && _selectedProjectId != null) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _against?['id'],
                      decoration: const InputDecoration(labelText: 'Shikoyat qilinayotgan investor', border: OutlineInputBorder()),
                      items: _investorOptions
                          .map<DropdownMenuItem<String>>((o) => DropdownMenuItem(value: o['id'] as String, child: Text(o['name'] ?? '')))
                          .toList(),
                      onChanged: (id) {
                        final found = _investorOptions.firstWhere((o) => o['id'] == id, orElse: () => {});
                        setState(() => _against = found.isEmpty ? null : found);
                      },
                    ),
                  ],
                  if (_isInvestor && _against != null) ...[
                    const SizedBox(height: 8),
                    Text('Shikoyat qilinadigan fermer: ${_against!['name']}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _disputeType,
                    decoration: const InputDecoration(labelText: 'Shikoyat turi', border: OutlineInputBorder()),
                    items: _disputeTypes.entries
                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (v) => setState(() => _disputeType = v ?? _disputeType),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Tafsilotlar', border: OutlineInputBorder(), alignLabelWithHint: true),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: disputeProvider.submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(disputeProvider.submitting ? 'Yuborilmoqda...' : 'Shikoyatni yuborish', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Mening shikoyatlarim', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
          const SizedBox(height: 12),
          if (disputeProvider.loading)
            const Column(children: [ShimmerCard(), ShimmerCard()])
          else if (disputeProvider.disputes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text("Shikoyatlar topilmadi", style: TextStyle(color: AppColors.textMuted))),
            )
          else
            ...disputeProvider.disputes.map((d) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(d['projectTitle'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                            child: Text(d['status'] ?? '', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(d['description'] ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                      if (d['resolution'] != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                          child: Text('Yechim: ${d['resolution']}', style: const TextStyle(fontSize: 12, color: AppColors.primaryDark)),
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
