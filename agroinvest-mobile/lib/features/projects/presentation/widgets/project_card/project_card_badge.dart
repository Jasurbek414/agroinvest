import 'package:flutter/material.dart';

/// Frosted pill badge overlaid on the card image (asset type on the left,
/// risk level on the right). White at ~92% opacity keeps the colored label
/// readable on any photo without needing a gradient scrim.
class ProjectCardBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const ProjectCardBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: color),
          ),
        ],
      ),
    );
  }
}
