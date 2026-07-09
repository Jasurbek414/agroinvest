import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// Role-based call-to-action bar pinned to the bottom of the project detail
/// page: login prompt for guests, "submit report" for the owning farmer, and
/// "invest" for investors while the project is still funding.
class ProjectBottomActionsBar extends StatelessWidget {
  final Map<String, dynamic>? user;
  final Map<String, dynamic> project;
  final bool isFunding;
  final VoidCallback onLogin;
  final VoidCallback onSubmitReport;
  final VoidCallback onInvest;

  const ProjectBottomActionsBar({
    super.key,
    required this.user,
    required this.project,
    required this.isFunding,
    required this.onLogin,
    required this.onSubmitReport,
    required this.onInvest,
  });

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Container(
        padding: AppSpacing.page,
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.border, width: 1.5))),
        child: ElevatedButton(
          onPressed: onLogin,
          child: const Text('Kirish va sarmoya kiritish'),
        ),
      );
    }

    final role = user!['role'];

    if (role == 'FARMER' && project['farmerId']?.toString() == user!['id']?.toString()) {
      return Container(
        padding: AppSpacing.page,
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.border, width: 1.5))),
        child: ElevatedButton.icon(
          onPressed: onSubmitReport,
          icon: const Icon(Icons.upload_file_rounded),
          label: const Text('Hisobot yuborish'),
        ),
      );
    }

    if (role == 'INVESTOR' && isFunding) {
      return Container(
        padding: AppSpacing.page,
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.border, width: 1.5))),
        child: ElevatedButton(
          onPressed: onInvest,
          child: const Text('Sarmoya kiritish'),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
