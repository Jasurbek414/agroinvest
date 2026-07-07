import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/animal_type_meta.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/asset_type_meta.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/image_upload_picker.dart';
import '../../data/project_repository.dart';

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

  final List<Map<String, String>> _riskLevels = [
    {'label': 'Past', 'value': 'LOW'},
    {'label': 'O\'rta', 'value': 'MEDIUM'},
    {'label': 'Yuqori', 'value': 'HIGH'},
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

                    _buildLabel('Loyiha nomi'),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(hintText: 'Masalan: 50 ta zotdor qo\'y boqish'),
                      validator: (val) => val == null || val.isEmpty ? 'Loyiha nomini kiriting' : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    _buildLabel('Loyiha tavsifi (Batafsil)'),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(hintText: 'Loyiha maqsadi, kutilayotgan hosildorlik va xarajatlar haqida batafsil yozing...'),
                      validator: (val) => val == null || val.length < 20 ? 'Tavsif kamida 20 ta belgidan iborat bo\'lishi kerak' : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    _buildLabel('Aktiv turi'),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: kAssetTypeMeta.entries.map((entry) {
                        final selected = _selectedAssetType == entry.key;
                        return ChoiceChip(
                          selected: selected,
                          onSelected: (_) => setState(() {
                            _selectedAssetType = entry.key;
                            if (!_isAnimalProject) _selectedAnimalType = null;
                          }),
                          avatar: Icon(entry.value.icon, size: 16, color: selected ? entry.value.color : AppColors.textMuted),
                          label: Text(entry.value.label),
                          showCheckmark: false,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    _buildLabel('Xavf darajasi'),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: _riskLevels.map((r) {
                        final selected = _selectedRiskLevel == r['value'];
                        return ChoiceChip(
                          selected: selected,
                          onSelected: (_) => setState(() => _selectedRiskLevel = r['value']!),
                          label: Text(r['label']!),
                          showCheckmark: false,
                        );
                      }).toList(),
                    ),

                    if (_isAnimalProject) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _buildLabel('Hayvon turi'),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: kAnimalTypeMeta.entries.map((entry) {
                          final selected = _selectedAnimalType == entry.key;
                          return ChoiceChip(
                            selected: selected,
                            onSelected: (_) => setState(() => _selectedAnimalType = entry.key),
                            avatar: Text(entry.value.emoji, style: const TextStyle(fontSize: 14)),
                            label: Text(entry.value.label),
                            showCheckmark: false,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildLabel('Bosh soni'),
                                TextFormField(
                                  controller: _headcountController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  decoration: const InputDecoration(hintText: '50'),
                                  validator: (val) => _isAnimalProject && (val == null || int.tryParse(val) == null || int.parse(val) < 1)
                                      ? 'Kiriting'
                                      : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildLabel('Bir bosh narxi (so\'m)'),
                                TextFormField(
                                  controller: _pricePerHeadController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  decoration: const InputDecoration(hintText: '1 500 000'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),

                    _buildLabel('Viloyat / Hudud'),
                    DropdownButtonFormField<String>(
                      value: _selectedRegion,
                      items: _regions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                      onChanged: (val) => setState(() => _selectedRegion = val!),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    _buildLabel('Manzil to\'liq (ixtiyoriy)'),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(hintText: 'Masalan: Parkent tumani, Qiziltog\' qishlog\'i'),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    _buildLabel('Loyiha rasmlari'),
                    ImageUploadPicker(category: 'project', onChanged: (urls) => setState(() => _mediaUrls = urls)),
                    const SizedBox(height: AppSpacing.xl),

                    // --- Moliyalash usuli ---
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
                          const Text('Moliyalashtirish usuli', style: AppTypography.sectionTitle),
                          const SizedBox(height: 4),
                          const Text(
                            'Hayvonlarni investor puliga sotib olasizmi yoki o\'zingizniki bilan kirasizmi?',
                            style: AppTypography.caption,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _FundingModeOption(
                            selected: _fundingMode == 'INVESTOR_FUNDED',
                            icon: Icons.account_balance_rounded,
                            title: 'To\'liq investor puliga',
                            subtitle: 'Barcha hayvonlar yig\'ilgan mablag\'ga sotib olinadi',
                            onTap: () => setState(() => _fundingMode = 'INVESTOR_FUNDED'),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _FundingModeOption(
                            selected: _fundingMode == 'FARMER_ASSETS',
                            icon: Icons.agriculture_rounded,
                            title: 'O\'z hayvonlarim bilan',
                            subtitle: 'Mavjud hayvonlarimni loyihaga qo\'shaman (admin tasdiqlaydi)',
                            onTap: () => setState(() => _fundingMode = 'FARMER_ASSETS'),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _FundingModeOption(
                            selected: _fundingMode == 'MIXED',
                            icon: Icons.call_split_rounded,
                            title: 'Aralash',
                            subtitle: 'Qisman o\'zim, qisman investor mablag\'i',
                            onTap: () => setState(() => _fundingMode = 'MIXED'),
                          ),
                          if (_hasContribution) ...[
                            const SizedBox(height: AppSpacing.lg),
                            _buildLabel('Mening hissam qiymati (so\'m)'),
                            TextFormField(
                              controller: _contributionValueController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: const InputDecoration(hintText: '5 000 000'),
                              validator: (val) => _hasContribution && (val == null || double.tryParse(val) == null || double.parse(val) <= 0)
                                  ? 'Hissa qiymatini kiriting'
                                  : null,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _buildLabel('Izoh (necha bosh, qanday holatda)'),
                            TextFormField(
                              controller: _contributionNotesController,
                              maxLines: 2,
                              decoration: const InputDecoration(hintText: 'Masalan: 10 ta sog\'lom qo\'y, 8 oylik'),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // --- Foyda taqsimoti (kelishuv asosida) ---
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
                          const Text('Foyda taqsimoti (kelishuv)', style: AppTypography.sectionTitle),
                          const SizedBox(height: 4),
                          Text(
                            'Sof foydadan investorlar jamoasiga qancha ulush taklif qilasiz? (${_minSharePct.toInt()}%–${_maxSharePct.toInt()}%)',
                            style: AppTypography.caption,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _SharePill(label: 'Investorlar', value: _investorSharePct.toInt(), color: AppColors.primary),
                              const Icon(Icons.swap_horiz_rounded, color: AppColors.textMuted, size: 18),
                              _SharePill(label: 'Fermer', value: 100 - _investorSharePct.toInt(), color: AppColors.accent),
                            ],
                          ),
                          Slider(
                            value: _investorSharePct,
                            min: _minSharePct,
                            max: _maxSharePct,
                            divisions: (_maxSharePct - _minSharePct).toInt().clamp(1, 100),
                            activeColor: AppColors.primary,
                            label: '${_investorSharePct.toInt()}%',
                            onChanged: (val) => setState(() => _investorSharePct = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // --- Harajatlar siyosati ---
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
                          const Text('Joriy harajatlar siyosati', style: AppTypography.sectionTitle),
                          const SizedBox(height: 4),
                          const Text('Yem, dori, transport kabi harajatlarni kim ko\'taradi?', style: AppTypography.caption),
                          const SizedBox(height: AppSpacing.md),
                          _ExpensePolicyOption(
                            selected: _expensePolicy == 'INVESTOR_BUDGET',
                            title: 'Loyiha byudjetidan',
                            subtitle: 'Yig\'ilgan mablag\' ichidan, shaffof hisobda',
                            onTap: () => setState(() => _expensePolicy = 'INVESTOR_BUDGET'),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _ExpensePolicyOption(
                            selected: _expensePolicy == 'FARMER_REIMBURSED',
                            title: 'O\'zim to\'layman',
                            subtitle: 'Sotuvdan keyin, foyda bo\'linishidan OLDIN qaytariladi',
                            onTap: () => setState(() => _expensePolicy = 'FARMER_REIMBURSED'),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _ExpensePolicyOption(
                            selected: _expensePolicy == 'MIXED',
                            title: 'Aralash',
                            subtitle: 'Har bir harajatda alohida belgilayman',
                            onTap: () => setState(() => _expensePolicy = 'MIXED'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // --- Hisobot chastotasi ---
                    _buildLabel('Hisobot chastotasi (har necha kunda)'),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _reportFrequencyDays.toDouble(),
                            min: 1,
                            max: 14,
                            divisions: 13,
                            activeColor: AppColors.primary,
                            label: '$_reportFrequencyDays kun',
                            onChanged: (val) => setState(() => _reportFrequencyDays = val.round()),
                          ),
                        ),
                        SizedBox(
                          width: 64,
                          child: Text(
                            _reportFrequencyDays == 1 ? 'Kunlik' : '$_reportFrequencyDays kun',
                            textAlign: TextAlign.center,
                            style: AppTypography.label,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    _buildLabel('Kerakli mablag\' miqdori (UZS)'),
                    TextFormField(
                      controller: _targetAmountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
                      decoration: const InputDecoration(hintText: 'Minimal: 100 000 UZS'),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Summani kiriting';
                        final num = double.tryParse(val);
                        if (num == null || num < 100000) return 'Kamida 100 000 UZS kiriting';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildLabel('Kutilayotgan daromad (%)'),
                              TextFormField(
                                controller: _returnPctController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
                                decoration: const InputDecoration(hintText: 'Masalan: 35'),
                                validator: (val) {
                                  if (val == null || val.isEmpty) return 'Foizni kiriting';
                                  final num = double.tryParse(val);
                                  if (num == null || num < 0) return 'Musbat foiz kiriting';
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildLabel('Muddati (Kun)'),
                              TextFormField(
                                controller: _durationController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
                                decoration: const InputDecoration(hintText: 'Masalan: 180'),
                                validator: (val) {
                                  if (val == null || val.isEmpty) return 'Kunni kiriting';
                                  final num = int.tryParse(val);
                                  if (num == null || num < 1) return 'Kamida 1 kun bo\'lishi shart';
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(text, style: AppTypography.label),
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

class _FundingModeOption extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FundingModeOption({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? AppColors.primary : AppColors.textMuted, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: selected ? AppColors.primaryDark : AppColors.textDark,
                  )),
                  Text(subtitle, style: AppTypography.caption),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ExpensePolicyOption extends StatelessWidget {
  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ExpensePolicyOption({required this.selected, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: selected ? AppColors.primaryDark : AppColors.textDark,
                  )),
                  Text(subtitle, style: AppTypography.caption),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SharePill extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _SharePill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$value%', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
        Text(label, style: AppTypography.caption),
      ],
    );
  }
}
