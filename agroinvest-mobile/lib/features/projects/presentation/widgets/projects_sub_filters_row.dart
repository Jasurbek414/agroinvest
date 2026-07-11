import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ProjectsSubFiltersRow extends StatefulWidget {
  final String selectedCategory;
  final String selectedRegion;
  final String selectedSort;
  final bool isGridView;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onRegionChanged;
  final ValueChanged<String> onSortChanged;
  final ValueChanged<bool> onLayoutChanged;

  const ProjectsSubFiltersRow({
    super.key,
    required this.selectedCategory,
    required this.selectedRegion,
    required this.selectedSort,
    required this.isGridView,
    required this.onCategoryChanged,
    required this.onRegionChanged,
    required this.onSortChanged,
    required this.onLayoutChanged,
  });

  @override
  State<ProjectsSubFiltersRow> createState() => _ProjectsSubFiltersRowState();
}

class _ProjectsSubFiltersRowState extends State<ProjectsSubFiltersRow> {
  Widget _buildDropdownButton({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      itemBuilder: (context) => options.map((opt) => PopupMenuItem(value: opt, child: Text(opt))).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border, width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 7.5, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textDark),
                ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 12, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          // Category dropdown
          _buildDropdownButton(
            label: 'Kategoriya',
            value: widget.selectedCategory,
            options: ['Barchasi', 'Chorvachilik', 'Dehqonchilik', 'Issiqxona'],
            onChanged: widget.onCategoryChanged,
          ),
          const SizedBox(width: 8),
          // Region dropdown
          _buildDropdownButton(
            label: 'Hudud',
            value: widget.selectedRegion,
            options: ['Barchasi', 'Toshkent v.', 'Qashqadaryo v.', 'Farg\'ona v.'],
            onChanged: widget.onRegionChanged,
          ),
          const SizedBox(width: 8),
          // Sort dropdown
          _buildDropdownButton(
            label: 'Saralash',
            value: widget.selectedSort,
            options: ['Yangilari', 'ROI yuqori', 'Muddati kam'],
            onChanged: widget.onSortChanged,
          ),
          const Spacer(),
          // Layout switch: Grid & List Toggle
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Grid icon
                GestureDetector(
                  onTap: () => widget.onLayoutChanged(true),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: widget.isGridView ? const Color(0xFF16A34A) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.grid_view_rounded,
                      size: 14,
                      color: widget.isGridView ? Colors.white : AppColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                // List icon
                GestureDetector(
                  onTap: () => widget.onLayoutChanged(false),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: !widget.isGridView ? const Color(0xFF16A34A) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.format_list_bulleted_rounded,
                      size: 14,
                      color: !widget.isGridView ? Colors.white : AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
