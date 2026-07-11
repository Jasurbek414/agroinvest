import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// A titled group of menu rows rendered as one rounded card with hairline
/// dividers - replaces the old flat list of identical bordered buttons.
/// Theme-aware (same slate dark palette AppShellScaffold uses), since the
/// Profile tab is where users actually toggle dark mode and immediately see
/// whether the app honors it.
class ProfileMenuSection extends StatelessWidget {
  final String title;
  final List<ProfileMenuTile> tiles;

  const ProfileMenuSection({super.key, required this.title, required this.tiles});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : AppColors.border;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Text(
            title,
            // Same section-heading recipe the dashboard uses ("Loyihalarim"),
            // with a dark-mode color swap AppTypography can't express.
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textDark,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: 1.5),
          ),
          child: Column(
            children: [
              for (var i = 0; i < tiles.length; i++) ...[
                if (i > 0) Divider(height: 1, indent: 62, color: border),
                tiles[i],
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final String? subtitle;
  final int badgeCount;
  final String? trailingText;
  final Color? trailingColor;
  final VoidCallback onTap;

  const ProfileMenuTile({
    super.key,
    required this.icon,
    this.iconColor,
    required this.label,
    this.subtitle,
    this.badgeCount = 0,
    this.trailingText,
    this.trailingColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textDark;
    final color = iconColor ?? AppColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Icon-in-tinted-box, same as InvestmentCard's status indicator.
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(isDark ? 0.18 : 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: textColor),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                    ),
                  ],
                ],
              ),
            ),
            if (badgeCount > 0)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(10)),
                child: Text(
                  badgeCount > 9 ? '9+' : '$badgeCount',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            if (trailingText != null)
              Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (trailingColor ?? AppColors.textMuted).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  trailingText!,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: trailingColor ?? AppColors.textMuted,
                  ),
                ),
              ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
