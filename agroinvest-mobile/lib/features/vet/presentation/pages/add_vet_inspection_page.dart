import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/upload_repository.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/vet_repository.dart';
import 'project_vet_page.dart' show kVetHealthMeta;

/// Farmer uploads the vet's conclusion after a check-up: vet identity, date,
/// health verdict, and the document itself (PDF or photo). Staff verifies it
/// before it appears publicly.
class AddVetInspectionPage extends StatefulWidget {
  final String projectId;

  const AddVetInspectionPage({super.key, required this.projectId});

  @override
  State<AddVetInspectionPage> createState() => _AddVetInspectionPageState();
}

class _AddVetInspectionPageState extends State<AddVetInspectionPage> {
  final _formKey = GlobalKey<FormState>();
  final _repository = VetRepository();
  final _uploadRepository = UploadRepository();
  final _vetNameController = TextEditingController();
  final _licenseController = TextEditingController();
  final _conclusionController = TextEditingController();

  DateTime _inspectionDate = DateTime.now();
  String _healthStatus = 'HEALTHY';
  final List<String> _documentUrls = [];
  bool _uploading = false;
  bool _submitting = false;
  String? _error;

  List<dynamic> _vets = [];
  bool _loadingVets = false;
  String? _selectedVetId;
  bool _isManualEntry = true;

  @override
  void initState() {
    super.initState();
    _loadVeterinarians();
  }

  Future<void> _loadVeterinarians() async {
    setState(() => _loadingVets = true);
    try {
      final list = await _repository.fetchActiveVeterinarians();
      setState(() {
        _vets = list;
        if (_vets.isNotEmpty) {
          _isManualEntry = false;
          _selectedVetId = _vets.first['id']?.toString();
          _vetNameController.text = _vets.first['name']?.toString() ?? '';
          _licenseController.text = _vets.first['licenseNo']?.toString() ?? '';
        } else {
          _isManualEntry = true;
        }
      });
    } catch (_) {
      setState(() => _isManualEntry = true);
    } finally {
      setState(() => _loadingVets = false);
    }
  }

  @override
  void dispose() {
    _vetNameController.dispose();
    _licenseController.dispose();
    _conclusionController.dispose();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
    );
    final path = result?.files.single.path;
    if (path == null) return;

    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final url = await _uploadRepository.uploadFile(path, category: 'vet');
      setState(() => _documentUrls.add(url));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_documentUrls.isEmpty) {
      setState(() => _error = 'Kamida bitta hujjat (PDF yoki foto) yuklang');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _repository.submitInspection(
        projectId: widget.projectId,
        vetName: _vetNameController.text.trim(),
        vetLicenseNo: _licenseController.text.trim().isEmpty ? null : _licenseController.text.trim(),
        inspectionDate: DateFormat('yyyy-MM-dd').format(_inspectionDate),
        documentUrls: _documentUrls,
        conclusion: _conclusionController.text.trim().isEmpty ? null : _conclusionController.text.trim(),
        healthStatus: _healthStatus,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hujjat yuborildi - admin tekshiradi'), backgroundColor: AppColors.primary),
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
      appBar: AppBar(title: const Text('Veterinar hujjati')),
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

                if (_loadingVets) ...[
                  const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  const SizedBox(height: AppSpacing.xl),
                ] else if (_vets.isNotEmpty) ...[
                  const Text('Veterinar shifokorni tanlang', style: AppTypography.label),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String>(
                    value: _selectedVetId,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 13),
                    isExpanded: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.person_pin_rounded, color: AppColors.textMuted),
                    ),
                    items: [
                      ..._vets.map((v) => DropdownMenuItem<String>(
                            value: v['id']?.toString(),
                            child: Text('${v['name']} (${v['specialty'] ?? 'Chorvachilik'})', overflow: TextOverflow.ellipsis),
                          )),
                      const DropdownMenuItem<String>(
                        value: 'custom',
                        child: Text('Boshqa (Qo\'lda kiritish)'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedVetId = val;
                          if (val == 'custom') {
                            _isManualEntry = true;
                            _vetNameController.text = '';
                            _licenseController.text = '';
                          } else {
                            _isManualEntry = false;
                            final selectedVet = _vets.firstWhere((v) => v['id']?.toString() == val);
                            _vetNameController.text = selectedVet['name']?.toString() ?? '';
                            _licenseController.text = selectedVet['licenseNo']?.toString() ?? '';
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],

                if (_isManualEntry || _vets.isEmpty) ...[
                  const Text('Veterinar F.I.SH', style: AppTypography.label),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _vetNameController,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
                    decoration: const InputDecoration(
                      hintText: 'Aliyev Vali G\'aniyevich',
                      prefixIcon: Icon(Icons.medical_services_rounded, color: AppColors.textMuted),
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty) ? 'Veterinar ismini kiriting' : null,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  const Text('Litsenziya raqami (ixtiyoriy)', style: AppTypography.label),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _licenseController,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
                    decoration: const InputDecoration(
                      hintText: 'VET-12345',
                      prefixIcon: Icon(Icons.badge_rounded, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],

                const Text('Ko\'rik sanasi', style: AppTypography.label),
                const SizedBox(height: AppSpacing.sm),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _inspectionDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 90)),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _inspectionDate = picked);
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
                        Text(DateFormat('dd.MM.yyyy').format(_inspectionDate), style: AppTypography.body),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                const Text('Hayvonlar holati', style: AppTypography.label),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: kVetHealthMeta.entries.map((entry) {
                    final selected = _healthStatus == entry.key;
                    return ChoiceChip(
                      selected: selected,
                      onSelected: (_) => setState(() => _healthStatus = entry.key),
                      avatar: Icon(entry.value.$3, size: 16, color: selected ? entry.value.$2 : AppColors.textMuted),
                      label: Text(entry.value.$1),
                      showCheckmark: false,
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.xl),

                const Text('Xulosa (ixtiyoriy)', style: AppTypography.label),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _conclusionController,
                  maxLines: 3,
                  style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textDark),
                  decoration: const InputDecoration(hintText: 'Veterinar xulosasining qisqacha mazmuni'),
                ),
                const SizedBox(height: AppSpacing.xl),

                const Text('Hujjatlar (PDF yoki foto)', style: AppTypography.label),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    ..._documentUrls.asMap().entries.map((entry) {
                      final isPdf = entry.value.toLowerCase().endsWith('.pdf');
                      return Chip(
                        avatar: Icon(
                          isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                          size: 16,
                          color: isPdf ? AppColors.danger : AppColors.primary,
                        ),
                        label: Text('Hujjat ${entry.key + 1}'),
                        deleteIcon: const Icon(Icons.cancel_rounded, size: 18, color: AppColors.danger),
                        onDeleted: () => setState(() => _documentUrls.removeAt(entry.key)),
                      );
                    }),
                    ActionChip(
                      avatar: _uploading
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                          : const Icon(Icons.upload_file_rounded, size: 16, color: AppColors.primary),
                      label: const Text('Yuklash'),
                      onPressed: _uploading ? null : _pickDocument,
                    ),
                  ],
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
