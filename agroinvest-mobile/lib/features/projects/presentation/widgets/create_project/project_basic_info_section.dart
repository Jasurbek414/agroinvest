import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/image_upload_picker.dart';

/// Title, description, region, optional detailed location and project media.
class ProjectBasicInfoSection extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController locationController;
  final String selectedRegion;
  final List<String> regions;
  final ValueChanged<String> onRegionChanged;
  final ValueChanged<List<String>> onMediaChanged;

  const ProjectBasicInfoSection({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.locationController,
    required this.selectedRegion,
    required this.regions,
    required this.onRegionChanged,
    required this.onMediaChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLabel('Loyiha nomi'),
        TextFormField(
          controller: titleController,
          decoration: const InputDecoration(hintText: 'Masalan: 50 ta zotdor qo\'y boqish'),
          validator: (val) => val == null || val.isEmpty ? 'Loyiha nomini kiriting' : null,
        ),
        const SizedBox(height: AppSpacing.lg),

        _buildLabel('Loyiha tavsifi (Batafsil)'),
        TextFormField(
          controller: descriptionController,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Loyiha maqsadi, kutilayotgan hosildorlik va xarajatlar haqida batafsil yozing...'),
          validator: (val) => val == null || val.length < 20 ? 'Tavsif kamida 20 ta belgidan iborat bo\'lishi kerak' : null,
        ),
        const SizedBox(height: AppSpacing.lg),

        _buildLabel('Viloyat / Hudud'),
        DropdownButtonFormField<String>(
          value: selectedRegion,
          items: regions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
          onChanged: (val) => onRegionChanged(val!),
        ),
        const SizedBox(height: AppSpacing.lg),

        _buildLabel('Manzil to\'liq (ixtiyoriy)'),
        TextFormField(
          controller: locationController,
          decoration: const InputDecoration(hintText: 'Masalan: Parkent tumani, Qiziltog\' qishlog\'i'),
        ),
        const SizedBox(height: AppSpacing.lg),

        _buildLabel('Loyiha rasmlari'),
        ImageUploadPicker(category: 'project', onChanged: onMediaChanged),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(text, style: AppTypography.label),
    );
  }
}
