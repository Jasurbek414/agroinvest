import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'dashed_border_painter.dart';

class KycPhotoUploadBox extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? url;
  final bool uploading;
  final VoidCallback onTap;

  const KycPhotoUploadBox({
    super.key,
    required this.title,
    required this.subtitle,
    required this.url,
    required this.uploading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: uploading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 150,
        child: CustomPaint(
          painter: url == null ? DashedBorderPainter(color: AppColors.border, strokeWidth: 1.5) : null,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: uploading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : url != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(url!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add_a_photo_outlined, color: AppColors.primary, size: 24),
                          ),
                          const SizedBox(height: 12),
                          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark), textAlign: TextAlign.center),
                          const SizedBox(height: 4),
                          Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textMuted), textAlign: TextAlign.center),
                        ],
                      ),
          ),
        ),
      ),
    );
  }
}
