import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/project_repository.dart';

/// Bottom sheet listing masked co-investor names and their share percentages.
Future<void> showProjectInvestorsSheet(
  BuildContext context,
  ProjectRepository projectRepository,
  String projectId,
) async {
  List<dynamic> investors = [];
  String? error;
  try {
    investors = await projectRepository.getProjectInvestors(projectId);
  } catch (e) {
    error = e.toString();
  }
  if (!context.mounted) return;
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg))),
    builder: (context) => Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Sherik investorlar', style: AppTypography.h2),
          const SizedBox(height: AppSpacing.lg),
          if (error != null)
            Text(error, style: const TextStyle(color: AppColors.danger))
          else if (investors.isEmpty)
            const Text('Hozircha investorlar yo\'q', style: AppTypography.bodyMuted)
          else
            ...investors.map((inv) {
              final m = Map<String, dynamic>.from(inv);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    const CircleAvatar(radius: 16, backgroundColor: AppColors.primaryLight, child: Icon(Icons.person_rounded, size: 16, color: AppColors.primary)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: Text(m['maskedName']?.toString() ?? 'Investor', style: AppTypography.body)),
                    Text('${(m['sharePct'] as num?)?.toStringAsFixed(1) ?? '0'}%', style: AppTypography.label),
                  ],
                ),
              );
            }),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    ),
  );
}
