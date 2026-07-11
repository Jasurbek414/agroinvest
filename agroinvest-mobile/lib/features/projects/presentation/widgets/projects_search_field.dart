import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ProjectsSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onFilterTap;
  final int activeFiltersCount;

  const ProjectsSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onFilterTap,
    this.activeFiltersCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(14);

    return Row(
      children: [
        // Search text box
        Expanded(
          child: SizedBox(
            height: 46,
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
              decoration: InputDecoration(
                hintText: 'Loyiha nomi yoki fermer nomi',
                hintStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, _) {
                    if (value.text.isEmpty) return const SizedBox.shrink();
                    return IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                      onPressed: () {
                        controller.clear();
                        onChanged('');
                      },
                    );
                  },
                ),
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: borderRadius,
                  borderSide: const BorderSide(color: AppColors.border, width: 1.2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: borderRadius,
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // "Filtrlar" badge button
        Stack(
          clipBehavior: Clip.none,
          children: [
            InkWell(
              onTap: onFilterTap,
              borderRadius: borderRadius,
              child: Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: borderRadius,
                  border: Border.all(color: AppColors.border, width: 1.2),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.tune_rounded, color: Color(0xFF16A34A), size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Filtrlar',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.textDark),
                    ),
                  ],
                ),
              ),
            ),
            if (activeFiltersCount > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: Color(0xFF16A34A),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$activeFiltersCount',
                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
