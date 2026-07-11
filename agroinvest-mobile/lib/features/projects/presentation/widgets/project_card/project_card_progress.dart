import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/format.dart';

/// Funding progress block: percent + raised/target amounts over an animated
/// fill bar. The bar turns green once the target is fully raised.
class ProjectCardProgress extends StatelessWidget {
  final Map<String, dynamic> project;

  const ProjectCardProgress({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final raised = double.tryParse(project['raisedAmount'].toString()) ?? 0.0;
    final target = double.tryParse(project['targetAmount'].toString()) ?? 1.0;
    final percent = target <= 0 ? 0.0 : (raised / target).clamp(0.0, 1.0);
    final isFull = percent >= 1.0;
    final barColor = isFull ? const Color(0xFF16A34A) : AppColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${(percent * 100).toStringAsFixed(0)}% ',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: barColor),
                  ),
                  const TextSpan(
                    text: 'yig\'ildi',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  '${formatMoneyCompact(raised)} / ${formatMoneyCompact(target)} so\'m',
                  maxLines: 1,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: percent),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 7,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ),
      ],
    );
  }
}
