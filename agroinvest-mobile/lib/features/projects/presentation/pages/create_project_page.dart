import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
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

  String _selectedAssetType = 'LIVESTOCK';
  String _selectedRiskLevel = 'MEDIUM';
  String _selectedRegion = 'Toshkent viloyati';

  bool _loading = false;

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

  final List<Map<String, String>> _assetTypes = [
    {'label': 'Chorvachilik', 'value': 'LIVESTOCK'},
    {'label': 'Dehqonchilik', 'value': 'CROP'},
    {'label': 'Issiqxona', 'value': 'GREENHOUSE'},
    {'label': 'Parrandachilik', 'value': 'POULTRY'},
    {'label': 'Asalachilik', 'value': 'BEEKEEPING'},
    {'label': 'Boshqa', 'value': 'OTHER'},
  ];

  final List<Map<String, String>> _riskLevels = [
    {'label': 'Past', 'value': 'LOW'},
    {'label': 'O\'rta', 'value': 'MEDIUM'},
    {'label': 'Yuqori', 'value': 'HIGH'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Yangi loyiha', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textDark,
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Loyiha arizasi',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textDark, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Sarmoya yig\'ishni boshlash uchun loyiha ma\'lumotlarini to\'ldiring. Loyiha admin tomonidan tasdiqlanganidan so\'ng faollashadi.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.4),
                    ),
                    const SizedBox(height: 28),

                    // Title
                    _buildLabel('Loyiha nomi'),
                    TextFormField(
                      controller: _titleController,
                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
                      decoration: _buildInputDecoration('Masalan: Gilos bog\'ini kengaytirish'),
                      validator: (val) => val == null || val.isEmpty ? 'Loyiha nomini kiriting' : null,
                    ),
                    const SizedBox(height: 20),

                    // Description
                    _buildLabel('Loyiha tavsifi (Batafsil)'),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textDark),
                      decoration: _buildInputDecoration('Loyiha maqsadi, kutilayotgan hosildorlik va xarajatlar haqida batafsil yozing...'),
                      validator: (val) => val == null || val.length < 20 ? 'Tavsif kamida 20 ta belgidan iborat bo\'lishi kerak' : null,
                    ),
                    const SizedBox(height: 20),

                    // Row of Asset Type and Risk Level
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildLabel('Aktiv turi'),
                              DropdownButtonFormField<String>(
                                value: _selectedAssetType,
                                decoration: _buildInputDecoration(''),
                                items: _assetTypes.map((t) {
                                  return DropdownMenuItem<String>(
                                    value: f(t['value']),
                                    child: Text(f(t['label']), style: const TextStyle(fontWeight: FontWeight.w600)),
                                  );
                                }).toList(),
                                onChanged: (val) => setState(() => _selectedAssetType = val!),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildLabel('Xavf darajasi'),
                              DropdownButtonFormField<String>(
                                value: _selectedRiskLevel,
                                decoration: _buildInputDecoration(''),
                                items: _riskLevels.map((r) {
                                  return DropdownMenuItem<String>(
                                    value: f(r['value']),
                                    child: Text(f(r['label']), style: const TextStyle(fontWeight: FontWeight.w600)),
                                  );
                                }).toList(),
                                onChanged: (val) => setState(() => _selectedRiskLevel = val!),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Region selection
                    _buildLabel('Viloyat / Hudud'),
                    DropdownButtonFormField<String>(
                      value: _selectedRegion,
                      decoration: _buildInputDecoration(''),
                      items: _regions.map((r) {
                        return DropdownMenuItem<String>(
                          value: r,
                          child: Text(r, style: const TextStyle(fontWeight: FontWeight.w600)),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedRegion = val!),
                    ),
                    const SizedBox(height: 20),

                    // Location Details
                    _buildLabel('Manzil to\'liq (ixtiyoriy)'),
                    TextFormField(
                      controller: _locationController,
                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
                      decoration: _buildInputDecoration('Masalan: Parkent tumani, Qiziltog\' qishlog\'i'),
                    ),
                    const SizedBox(height: 20),

                    // Project photos
                    _buildLabel('Loyiha rasmlari (chorva/dala/issiqxona)'),
                    ImageUploadPicker(
                      category: 'project',
                      onChanged: (urls) => setState(() => _mediaUrls = urls),
                    ),
                    const SizedBox(height: 20),

                    // Financial Inputs Row (Target Amount, Return Pct, Duration)
                    _buildLabel('Kerakli mablag\' miqdori (UZS)'),
                    TextFormField(
                      controller: _targetAmountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
                      decoration: _buildInputDecoration('Minimal: 100 000 UZS'),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Summani kiriting';
                        final num = double.tryParse(val);
                        if (num == null || num < 100000) return 'Kamida 100 000 UZS kiriting';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

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
                                decoration: _buildInputDecoration('Masalan: 35'),
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
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildLabel('Muddati (Kun)'),
                              TextFormField(
                                controller: _durationController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
                                decoration: _buildInputDecoration('Masalan: 180'),
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
                    const SizedBox(height: 36),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _submitRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Arizani yuborish',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String f(String? text) => text ?? '';

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark.withOpacity(0.8),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w400),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
    );
  }

  void _submitRequest() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _loading = true;
      });

      try {
        await _projectRepository.createProject({
          'assetType': _selectedAssetType,
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
            const SnackBar(
              content: Text('Loyiha arizasi muvaffaqiyatli yuborildi!'),
              backgroundColor: AppColors.primary,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _loading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }
}
