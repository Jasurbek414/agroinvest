import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/project_repository.dart';
import '../widgets/create_project/asset_type_picker.dart';
import '../widgets/create_project/expense_policy_section.dart';
import '../widgets/create_project/funding_mode_section.dart';
import '../widgets/create_project/profit_share_slider.dart';
import '../widgets/create_project/project_basic_info_section.dart';
import '../widgets/create_project/report_frequency_and_targets_section.dart';

class CreateProjectPage extends StatefulWidget {
  const CreateProjectPage({super.key});

  @override
  State<CreateProjectPage> createState() => _CreateProjectPageState();
}

class _CreateProjectPageState extends State<CreateProjectPage> {
  final _formKey = GlobalKey<FormState>();
  final _projectRepository = ProjectRepository();
  List<String> _mediaUrls = [];

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
      // Fall back to hardcoded defaults - the slider still works.
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Yangi loyiha')),
      body: (_loading || _loadingSettings)
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: AppSpacing.page,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Loyiha arizasi', style: AppTypography.h1),
                    const SizedBox(height: 6),
                    const Text(
                      'Sarmoya yig\'ishni boshlash uchun loyiha ma\'lumotlarini to\'ldiring. Loyiha admin tomonidan tasdiqlanganidan so\'ng faollashadi.',
                      style: AppTypography.bodyMuted,
                    ),
                    const SizedBox(height: AppSpacing.xl),

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

                    ProjectBasicInfoSection(
                      titleController: _titleController,
                      descriptionController: _descriptionController,
                      locationController: _locationController,
                      selectedRegion: _selectedRegion,
                      regions: _regions,
                      onRegionChanged: (val) => setState(() => _selectedRegion = val),
                      onMediaChanged: (urls) => setState(() => _mediaUrls = urls),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    AssetTypePicker(
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
                    const SizedBox(height: AppSpacing.xl),

                    FundingModeSection(
                      fundingMode: _fundingMode,
                      hasContribution: _hasContribution,
                      contributionValueController: _contributionValueController,
                      contributionNotesController: _contributionNotesController,
                      onFundingModeChanged: (val) => setState(() => _fundingMode = val),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    ProfitShareSlider(
                      investorSharePct: _investorSharePct,
                      minSharePct: _minSharePct,
                      maxSharePct: _maxSharePct,
                      onChanged: (val) => setState(() => _investorSharePct = val),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    ExpensePolicySection(
                      expensePolicy: _expensePolicy,
                      onChanged: (val) => setState(() => _expensePolicy = val),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    ReportFrequencyAndTargetsSection(
                      reportFrequencyDays: _reportFrequencyDays,
                      onReportFrequencyChanged: (val) => setState(() => _reportFrequencyDays = val),
                      targetAmountController: _targetAmountController,
                      returnPctController: _returnPctController,
                      durationController: _durationController,
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    ElevatedButton(
                      onPressed: _submitRequest,
                      child: const Text('Arizani yuborish'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isAnimalProject && _selectedAnimalType == null) {
      setState(() => _error = 'Hayvon turini tanlang');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
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
        'mediaUrls': _mediaUrls,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Loyiha arizasi muvaffaqiyatli yuborildi!'), backgroundColor: AppColors.primary),
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
