import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../../core/widgets/document_upload_picker.dart';

class InvestorProposalForm extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController targetAmountController;
  final TextEditingController returnPctController;
  final TextEditingController durationController;
  final TextEditingController descriptionController;
  final String selectedAssetType;
  final String selectedRegion;
  final ValueChanged<String> onAssetTypeChanged;
  final ValueChanged<String> onRegionChanged;
  final List<String> regions;
  final List<String> docUrls;
  final ValueChanged<List<String>> onDocUrlsChanged;

  const InvestorProposalForm({
    super.key,
    required this.titleController,
    required this.targetAmountController,
    required this.returnPctController,
    required this.durationController,
    required this.descriptionController,
    required this.selectedAssetType,
    required this.selectedRegion,
    required this.onAssetTypeChanged,
    required this.onRegionChanged,
    required this.regions,
    required this.docUrls,
    required this.onDocUrlsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sarlavha
        TextFormField(
          controller: titleController,
          style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13),
          validator: (v) => (v == null || v.isEmpty) ? 'Taklif nomini kiriting' : null,
          decoration: InputDecoration(
            labelText: 'Taklif nomi / Sarlavha',
            hintText: 'Masalan: Chorvachilikka 100 mln so\'mgacha sarmoya',
            labelStyle: const TextStyle(fontSize: 12),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Sarmoya summasi
        TextFormField(
          controller: targetAmountController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13),
          validator: (v) => (v == null || v.isEmpty) ? 'Sarmoya miqdorini kiriting' : null,
          decoration: InputDecoration(
            labelText: 'Sarmoya miqdori (UZS)',
            hintText: 'Masalan: 50000000',
            labelStyle: const TextStyle(fontSize: 12),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Taxminiy yo'nalish
        DropdownButtonFormField<String>(
          value: selectedAssetType,
          onChanged: (val) {
            if (val != null) onAssetTypeChanged(val);
          },
          style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13),
          decoration: InputDecoration(
            labelText: 'Taxminiy yo\'nalish',
            labelStyle: const TextStyle(fontSize: 12),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
            ),
          ),
          items: const [
            DropdownMenuItem(value: 'LIVESTOCK', child: Text('Chorvachilik')),
            DropdownMenuItem(value: 'POULTRY', child: Text('Parrandachilik')),
            DropdownMenuItem(value: 'AGRICULTURE', child: Text('Dehqonchilik')),
            DropdownMenuItem(value: 'GREENHOUSE', child: Text('Issiqxona')),
            DropdownMenuItem(value: 'FISHERY', child: Text('Baliqchilik')),
            DropdownMenuItem(value: 'BEEKEEPING', child: Text('Asalarichilik')),
            DropdownMenuItem(value: 'OTHER', child: Text('Boshqa')),
          ],
        ),
        const SizedBox(height: 14),

        // ROI va Muddat
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: returnPctController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13),
                validator: (v) => (v == null || v.isEmpty) ? 'Kutilayotgan ROI ni kiriting' : null,
                decoration: InputDecoration(
                  labelText: 'Expected ROI (%)',
                  hintText: 'Masalan: 24',
                  labelStyle: const TextStyle(fontSize: 12),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border, width: 1.2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: durationController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13),
                validator: (v) => (v == null || v.isEmpty) ? 'Sarmoya muddatini kiriting' : null,
                decoration: InputDecoration(
                  labelText: 'Muddat (kunlar)',
                  hintText: 'Masalan: 365',
                  labelStyle: const TextStyle(fontSize: 12),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border, width: 1.2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Hudud (Viloyat)
        DropdownButtonFormField<String>(
          value: selectedRegion,
          onChanged: (val) {
            if (val != null) onRegionChanged(val);
          },
          style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13),
          decoration: InputDecoration(
            labelText: 'Hudud (Viloyat)',
            labelStyle: const TextStyle(fontSize: 12),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
            ),
          ),
          items: regions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
        ),
        const SizedBox(height: 14),

        // Qo'shimcha takliflar
        TextFormField(
          controller: descriptionController,
          maxLines: 4,
          style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13),
          validator: (v) => (v == null || v.isEmpty) ? 'Batafsil shartlarni kiriting' : null,
          decoration: InputDecoration(
            labelText: 'Qo\'shimcha shartlar va takliflar',
            hintText: 'Loyiha bo\'yicha o\'z talablaringiz va sheriklik takliflaringizni batafsil yozib bering...',
            labelStyle: const TextStyle(fontSize: 12),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.only(bottom: 6.0),
          child: Text('Taklif hujjatlari (ixtiyoriy)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
        ),
        DocumentUploadPicker(
          category: 'project',
          urls: docUrls,
          onChanged: onDocUrlsChanged,
        ),
        const SizedBox(height: 16),

        // Info Note Warning Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Eslatma: Ushbu tanlangan yo\'nalish va shartlar qat\'iy emas. Loyihasi bor fermerlar sizga boshqa turdagi takliflarni ham bildirishlari va siz bilan bog\'lanishlari mumkin.',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
