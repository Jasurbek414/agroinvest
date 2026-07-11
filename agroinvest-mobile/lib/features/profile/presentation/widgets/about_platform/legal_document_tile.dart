import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class LegalDocumentTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final String content;

  const LegalDocumentTile({
    super.key,
    required this.title,
    required this.icon,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: ExpansionTile(
        leading: Icon(icon, color: AppColors.primary, size: 20),
        title: Text(
          title,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
        ),
        iconColor: AppColors.primary,
        collapsedIconColor: AppColors.textMuted,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedAlignment: Alignment.topLeft,
        children: [
          const Divider(color: AppColors.border, height: 16),
          Text(
            content,
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: Color(0xFF334155),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
