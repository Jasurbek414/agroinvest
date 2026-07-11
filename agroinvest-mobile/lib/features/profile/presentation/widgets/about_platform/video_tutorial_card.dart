import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class VideoTutorialCard extends StatelessWidget {
  final Map<String, dynamic> video;
  final VoidCallback onPlay;

  const VideoTutorialCard({
    super.key,
    required this.video,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final title = video['title'].toString();
    final duration = video['duration'].toString();
    final description = video['description'].toString();
    final views = video['views'].toString();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Simulated Video Player Thumbnail
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 160,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF334155), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Center(
                  child: Opacity(
                    opacity: 0.1,
                    child: Icon(Icons.spa_rounded, size: 100, color: Colors.white.withOpacity(0.8)),
                  ),
                ),
              ),
              // Play button overlay
              IconButton(
                iconSize: 56,
                icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                onPressed: onPlay,
              ),
              // Duration badge
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    duration,
                    style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          // Video details info
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.45, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.remove_red_eye_outlined, color: AppColors.textMuted, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      views,
                      style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
