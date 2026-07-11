import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/project_repository.dart';
import '../widgets/create_project/asset_type_picker.dart';
import '../widgets/create_project/expense_policy_section.dart';
import '../widgets/create_project/funding_mode_section.dart';
import '../widgets/create_project/profit_share_slider.dart';
import '../widgets/create_project/project_basic_info_section.dart';
import '../widgets/create_project/report_frequency_and_targets_section.dart';
import '../widgets/create_project/role_indicator_header.dart';
import '../widgets/create_project/investor_proposal_form.dart';
import '../../../../core/widgets/document_upload_picker.dart';

class CreateProjectPage extends StatefulWidget {
  const CreateProjectPage({super.key});

  @override
  State<CreateProjectPage> createState() => _CreateProjectPageState();
}

class _CreateProjectPageState extends State<CreateProjectPage> {
  final _formKey = GlobalKey<FormState>();
  final _projectRepository = ProjectRepository();
  List<String> _mediaUrls = [];
  List<String> _docUrls = [];

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _returnPctController = TextEditingController();
  final _durationController = TextEditingController();
  final _headcountController = TextEditingController();
  final _pricePerHeadController = TextEditingController();
  final _contributionValueController = TextEditingController();
  final _contributionNotesController = TextEditingController();

  String _selectedAssetType = 'LIVESTOCK';
  String? _selectedAnimalType;
  String _selectedRiskLevel = 'MEDIUM';
  String _selectedRegion = 'Toshkent viloyati';
  String _fundingMode = 'INVESTOR_FUNDED';
  String _expensePolicy = 'INVESTOR_BUDGET';
  double _investorSharePct = 70;
  int _reportFrequencyDays = 14;

  bool _loading = false;
  bool _loadingSettings = true;
  double _minSharePct = 50;
  double _maxSharePct = 90;
  String? _error;

  final List<String> _regions = [
    'Toshkent viloyati',
    'Toshkent shahri',
    'Samarqand viloyati',
    'Farg\'ona viloyati',
    'Andijon viloyati',
    'Namangan viloyati',
    'Buxoro viloyati',
    'Xorazm viloyati',
    'Qashqadaryo viloyati',
    'Surxondaryo viloyati',
    'Jizzax viloyati',
    'Sirdaryo viloyati',
    'Navoiy viloyati',
    'Qoraqalpog\'iston Respublikasi'
  ];

  bool get _isAnimalProject => _selectedAssetType == 'LIVESTOCK' || _selectedAssetType == 'POULTRY';
  bool get _hasContribution => _fundingMode == 'FARMER_ASSETS' || _fundingMode == 'MIXED';

  @override
  void initState() {
    super.initState();
    _loadPublicSettings();
  }

  Future<void> _loadPublicSettings() async {
    try {
      final settings = await _projectRepository.getPublicSettings();
      final min = (settings['minInvestorSharePct'] as num?)?.toDouble() ?? 50;
      final max = (settings['maxInvestorSharePct'] as num?)?.toDouble() ?? 90;
      final defaultShare = (settings['defaultInvestorSharePct'] as num?)?.toDouble() ?? 70;
      if (mounted) {
        setState(() {
          _minSharePct = min;
          _maxSharePct = max;
          _investorSharePct = defaultShare.clamp(min, max);
        });
      }
    } catch (_) {
      // Fall back to defaults
    } finally {
      if (mounted) setState(() => _loadingSettings = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _targetAmountController.dispose();
    _returnPctController.dispose();
    _durationController.dispose();
    _headcountController.dispose();
    _pricePerHeadController.dispose();
    _contributionValueController.dispose();
    _contributionNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final role = (user != null ? user['role']?.toString().toUpperCase() : '') ?? '';
    final isInvestor = role.contains('INVEST');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          isInvestor ? 'Sarmoya taklifi joylash' : 'Yangi loyiha',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textDark),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textDark,
        shape: const Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      body: (_loading || _loadingSettings)
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Premium Gradient Indicator Card (Modular Component)
                    RoleIndicatorHeader(isInvestor: isInvestor),
                    const SizedBox(height: 20),

                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.danger.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12.5, fontWeight: FontWeight.bold))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    if (isInvestor)
                      // Investor Form (Modular Component)
                      InvestorProposalForm(
                        titleController: _titleController,
                        targetAmountController: _targetAmountController,
                        returnPctController: _returnPctController,
                        durationController: _durationController,
                        descriptionController: _descriptionController,
                        selectedAssetType: _selectedAssetType,
                        selectedRegion: _selectedRegion,
                        regions: _regions,
                        onAssetTypeChanged: (val) => setState(() => _selectedAssetType = val),
                        onRegionChanged: (val) => setState(() => _selectedRegion = val),
                        docUrls: _docUrls,
                        onDocUrlsChanged: (urls) => setState(() => _docUrls = urls),
                      )
                    else
                      // Farmer Form (Beautified Card Flow)
                      _buildFarmerForm(),

                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => _submitRequest(isInvestor),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        isInvestor ? 'Taklifni e\'lon qilish' : 'Arizani yuborish',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFarmerForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionCard(
          title: 'Asosiy ma\'lumotlar',
          icon: Icons.info_outline_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProjectBasicInfoSection(
                titleController: _titleController,
                descriptionController: _descriptionController,
                locationController: _locationController,
                selectedRegion: _selectedRegion,
                regions: _regions,
                onRegionChanged: (val) => setState(() => _selectedRegion = val),
                onMediaChanged: (urls) => setState(() => _mediaUrls = urls),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.only(bottom: 6.0),
                child: Text('Loyiha hujjatlari', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              DocumentUploadPicker(
                category: 'project',
                urls: _docUrls,
                onChanged: (urls) => setState(() => _docUrls = urls),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Yo\'nalish & Hayvonlar',
          icon: Icons.pets_rounded,
          child: AssetTypePicker(
            selectedAssetType: _selectedAssetType,
            selectedRiskLevel: _selectedRiskLevel,
            selectedAnimalType: _selectedAnimalType,
            isAnimalProject: _isAnimalProject,
            headcountController: _headcountController,
            pricePerHeadController: _pricePerHeadController,
            onAssetTypeChanged: (val) => setState(() {
              _selectedAssetType = val;
              if (!_isAnimalProject) _selectedAnimalType = null;
            }),
            onRiskLevelChanged: (val) => setState(() => _selectedRiskLevel = val),
            onAnimalTypeChanged: (val) => setState(() => _selectedAnimalType = val),
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Moliyalashtirish shakli',
          icon: Icons.payments_outlined,
          child: FundingModeSection(
            fundingMode: _fundingMode,
            hasContribution: _hasContribution,
            contributionValueController: _contributionValueController,
            contributionNotesController: _contributionNotesController,
            onFundingModeChanged: (val) => setState(() => _fundingMode = val),
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Taqsimotlar & Foyda',
          icon: Icons.analytics_outlined,
          child: ProfitShareSlider(
            investorSharePct: _investorSharePct,
            minSharePct: _minSharePct,
            maxSharePct: _maxSharePct,
            onChanged: (val) => setState(() => _investorSharePct = val),
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Xarajatlar siyosati',
          icon: Icons.policy_outlined,
          child: ExpensePolicySection(
            expensePolicy: _expensePolicy,
            onChanged: (val) => setState(() => _expensePolicy = val),
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Hisobotlar & Maqsadlar',
          icon: Icons.bar_chart_rounded,
          child: ReportFrequencyAndTargetsSection(
            reportFrequencyDays: _reportFrequencyDays,
            onReportFrequencyChanged: (val) => setState(() => _reportFrequencyDays = val),
            targetAmountController: _targetAmountController,
            returnPctController: _returnPctController,
            durationController: _durationController,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  void _submitRequest(bool isInvestor) async {
    if (!_formKey.currentState!.validate()) return;
    if (!isInvestor && _isAnimalProject && _selectedAnimalType == null) {
      setState(() => _error = 'Hayvon turini tanlang');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (isInvestor) {
        final targetAmt = double.parse(_targetAmountController.text);
        String? animalType;
        int? headcount;
        double? pricePerHead;

        if (_selectedAssetType == 'LIVESTOCK') {
          animalType = 'CATTLE';
          headcount = 1;
          pricePerHead = targetAmt;
        } else if (_selectedAssetType == 'POULTRY') {
          animalType = 'CHICKEN';
          headcount = 1;
          pricePerHead = targetAmt;
        }

        // Investor offer submission
        await _projectRepository.createProject({
          'assetType': _selectedAssetType,
          'animalType': animalType,
          'headcount': headcount,
          'pricePerHead': pricePerHead,
          'fundingMode': 'INVESTOR_FUNDED',
          'expensePolicy': 'INVESTOR_BUDGET',
          'proposedInvestorSharePct': 70.0,
          'reportFrequencyDays': 14,
          'title': 'Sarmoya taklifi: ${_titleController.text}',
          'description': 'SARMOYA TAKLIFI (INVESTOR REKLAMASI)\n\n'
              '${_descriptionController.text}\n\n'
              'Eslatma: Ushbu yo\'nalish va shartlar qat\'iy emas. Fermerlar boshqa qishloq xo\'jaligi takliflari bilan ham murojaat qilishlari mumkin.',
          'region': _selectedRegion,
          'locationDetails': _selectedRegion,
          'targetAmount': targetAmt,
          'minInvestment': targetAmt,
          'expectedReturnPct': double.parse(_returnPctController.text),
          'durationDays': int.parse(_durationController.text),
          'riskLevel': 'LOW',
          'mediaUrls': [
            'https://images.unsplash.com/photo-1545468117-910a39527f51?q=80&w=600&auto=format&fit=crop',
            ..._docUrls
          ],
        });
      } else {
        // Standard Farmer project request
        await _projectRepository.createProject({
          'assetType': _selectedAssetType,
          'animalType': _isAnimalProject ? _selectedAnimalType : null,
          'headcount': _isAnimalProject && _headcountController.text.isNotEmpty ? int.parse(_headcountController.text) : null,
          'pricePerHead': _isAnimalProject && _pricePerHeadController.text.isNotEmpty ? double.parse(_pricePerHeadController.text) : null,
          'fundingMode': _fundingMode,
          'farmerContributionValue': _hasContribution ? double.parse(_contributionValueController.text) : 0,
          'farmerContributionNotes': _hasContribution ? _contributionNotesController.text : null,
          'expensePolicy': _expensePolicy,
          'proposedInvestorSharePct': _investorSharePct,
          'reportFrequencyDays': _reportFrequencyDays,
          'title': _titleController.text,
          'description': _descriptionController.text,
          'region': _selectedRegion,
          'locationDetails': _locationController.text,
          'targetAmount': double.parse(_targetAmountController.text),
          'minInvestment': 100000.0,
          'expectedReturnPct': double.parse(_returnPctController.text),
          'durationDays': int.parse(_durationController.text),
          'riskLevel': _selectedRiskLevel,
          'mediaUrls': [..._mediaUrls, ..._docUrls],
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isInvestor ? 'Sarmoya taklifi muvaffaqiyatli joylashtirildi!' : 'Loyiha arizasi muvaffaqiyatli yuborildi!'),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }
}
