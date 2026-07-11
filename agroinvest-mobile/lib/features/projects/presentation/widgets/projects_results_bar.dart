import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Thin strip between the filters and the list: how many projects the current
/// filter + search combination yields, plus a one-tap reset when anything is
/// narrowed down.
class ProjectsResultsBar extends StatelessWidget {
  final int count;
  final bool hasActiveFilters;
  final VoidCallback onClear;

  const ProjectsResultsBar({
    super.key,
    required this.count,
    required this.hasActiveFilters,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$count ta ',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
                const TextSpan(
                  text: 'loyiha topildi',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (hasActiveFilters)
            InkWell(
              onTap: onClear,
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.filter_alt_off_rounded, size: 14, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text(
                      'Tozalash',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
