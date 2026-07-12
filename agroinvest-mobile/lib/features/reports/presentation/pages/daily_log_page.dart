import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/image_upload_picker.dart';
import '../../data/report_repository.dart';

/// The farmer's <1-minute daily livestock log: 4 numeric fields (prefilled from
/// the previous daily report), optional note/photo, best-effort GPS. Submits a
/// DAILY report with structured metrics.
class DailyLogPage extends StatefulWidget {
  final String projectId;

  const DailyLogPage({super.key, required this.projectId});

  @override
  State<DailyLogPage> createState() => _DailyLogPageState();
}

class _DailyLogPageState extends State<DailyLogPage> {
  final _formKey = GlobalKey<FormState>();
  final _repository = ReportRepository();

  final _headcountController = TextEditingController();
  final _deathsController = TextEditingController(text: '0');
  final _feedController = TextEditingController();
  final _weightController = TextEditingController();
  final _noteController = TextEditingController();

  List<String> _mediaUrls = [];
  Position? _position;
  bool _submitting = false;
  bool _prefilling = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _prefillFromLastLog();
    _captureLocation();
  }

  @override
  void dispose() {
    _headcountController.dispose();
    _deathsController.dispose();
    _feedController.dispose();
    _weightController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// Yesterday's numbers are the best default for today - the farmer only
  /// corrects what changed, which is what makes this form fast.
  Future<void> _prefillFromLastLog() async {
    try {
      final reports = await _repository.fetchProjectReports(widget.projectId, size: 10);
      final lastDaily = reports.firstWhere(
        (r) => r['reportType'] == 'DAILY' && r['metrics'] != null,
        orElse: () => null,
      );
      if (lastDaily != null && mounted) {
        final metrics = Map<String, dynamic>.from(lastDaily['metrics']);
        _headcountController.text = (metrics['headcount'] ?? '').toString();
        _feedController.text = (metrics['feedKg'] ?? '').toString();
        _weightController.text = (metrics['avgWeightKg'] ?? '').toString();
      }
    } catch (_) {
      // Prefill is best-effort - an error here must not block the form.
    } finally {
      if (mounted) setState(() => _prefilling = false);
    }
  }

  Future<void> _captureLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return; // GPS optional on daily logs
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      ).timeout(const Duration(seconds: 10));
      if (mounted) setState(() => _position = position);
    } catch (_) {
      // best-effort
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final metrics = <String, dynamic>{
        'headcount': int.parse(_headcountController.text),
        'deaths': int.tryParse(_deathsController.text) ?? 0,
        if (_feedController.text.isNotEmpty) 'feedKg': double.tryParse(_feedController.text),
        if (_weightController.text.isNotEmpty) 'avgWeightKg': double.tryParse(_weightController.text),
        if (_noteController.text.trim().isNotEmpty) 'healthNote': _noteController.text.trim(),
      }..removeWhere((key, value) => value == null);

      await _repository.submitReport(
        projectId: widget.projectId,
        reportType: 'DAILY',
        mediaUrls: _mediaUrls,
        geoLat: _position?.latitude,
        geoLng: _position?.longitude,
        geoAccuracy: _position?.accuracy,
        notes: _noteController.text.trim().isEmpty ? 'Kunlik hisobot' : _noteController.text.trim(),
        metrics: metrics,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kunlik hisobot topshirildi ✓'), backgroundColor: AppColors.primary),
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
      appBar: AppBar(title: const Text('Kunlik hisobot')),
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

                Row(
                  children: [
                    Expanded(
                      child: _NumberField(
                        controller: _headcountController,
                        label: 'Bosh soni',
                        icon: Icons.numbers_rounded,
                        hint: '50',
                        loading: _prefilling,
                        required: true,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _NumberField(
                        controller: _deathsController,
                        label: "O'lim (bugun)",
                        icon: Icons.trending_down_rounded,
                        hint: '0',
                        required: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: _NumberField(
                        controller: _feedController,
                        label: 'Yem (kg)',
                        icon: Icons.grass_rounded,
                        hint: '120',
                        decimal: true,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _NumberField(
                        controller: _weightController,
                        label: "O'rtacha vazn (kg)",
                        icon: Icons.monitor_weight_rounded,
                        hint: '42.5',
                        decimal: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                const Text('Izoh (ixtiyoriy)', style: AppTypography.label),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _noteController,
                  maxLines: 2,
                  style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textDark),
                  decoration: const InputDecoration(hintText: "Hammasi joyida / 2 ta qo'y isitmalayapti..."),
                ),
                const SizedBox(height: AppSpacing.xl),

                const Text('Foto va video (ixtiyoriy)', style: AppTypography.label),
                const SizedBox(height: AppSpacing.sm),
                ImageUploadPicker(
                  category: 'report',
                  maxImages: 10,
                  allowVideo: true,
                  onChanged: (urls) => _mediaUrls = urls,
                ),
                const SizedBox(height: AppSpacing.lg),

                Row(
                  children: [
                    Icon(
                      _position != null ? Icons.location_on_rounded : Icons.location_off_rounded,
                      size: 16,
                      color: _position != null ? AppColors.primary : AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _position != null ? 'GPS joylashuv biriktirildi' : 'GPS mavjud emas (ixtiyoriy)',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Topshirish'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String hint;
  final bool decimal;
  final bool required;
  final bool loading;

  const _NumberField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.hint,
    this.decimal = false,
    this.required = false,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.label),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: decimal),
          inputFormatters: [
            if (decimal)
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
            else
              FilteringTextInputFormatter.digitsOnly,
          ],
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: loading
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                  )
                : Icon(icon, color: AppColors.textMuted, size: 20),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          ),
          validator: required
              ? (val) => (val == null || val.isEmpty || num.tryParse(val) == null) ? 'Kiriting' : null
              : null,
        ),
      ],
    );
  }
}
