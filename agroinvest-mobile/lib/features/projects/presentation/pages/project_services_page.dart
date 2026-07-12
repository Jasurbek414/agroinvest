import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/status_badge.dart';

class ProjectServicesPage extends StatelessWidget {
  final String projectId;
  final String? projectTitle;

  const ProjectServicesPage({super.key, required this.projectId, this.projectTitle});

  @override
  Widget build(BuildContext context) {
    // Realistic mockup of services rendered to the farmer for this livestock project
    final services = [
      {
        'title': 'Veterinar nazorati va emlash',
        'provider': 'MChJ "AgroVet Servis"',
        'date': DateTime.now().subtract(const Duration(days: 10)),
        'cost': 500000.0,
        'status': 'VERIFIED',
        'details': 'Barcha 5 bosh qoramollar to\'liq ko\'rikdan o\'tkazildi va emlandi.'
      },
      {
        'title': 'Yuqori ozuqali yem yetkazib berish (500 kg)',
        'provider': 'Yem-Xashak Markazi',
        'date': DateTime.now().subtract(const Duration(days: 15)),
        'cost': 2500000.0,
        'status': 'VERIFIED',
        'details': 'Sifatli aralash ozuqa em-xashak to\'g\'ridan-to\'g\'ri fermaga yetkazildi.'
      },
      {
        'title': 'Loyihani sug\'urtalash xizmati',
        'provider': 'Gross Insurance sug\'urta kompaniyasi',
        'date': DateTime.now().subtract(const Duration(days: 18)),
        'cost': 1200000.0,
        'status': 'VERIFIED',
        'details': 'Qoramollarni nobud bo\'lish va kasalliklardan sug\'urtalash shartnomasi.'
      },
      {
        'title': 'Transport xizmati (Hayvonlarni tashish)',
        'provider': 'UzAgroLogistics',
        'date': DateTime.now().subtract(const Duration(days: 20)),
        'cost': 800000.0,
        'status': 'VERIFIED',
        'details': 'Nasldor qoramollar maxsus transportda fermaga xavfsiz yetkazildi.'
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textDark, size: 24),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Ko\'rsatilgan qo\'shimcha xizmatlar',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textDark, letterSpacing: -0.5),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      body: ListView(
        padding: AppSpacing.page,
        children: [
          if (projectTitle != null) ...[
            Text(projectTitle!, style: AppTypography.h2),
            const SizedBox(height: AppSpacing.lg),
          ],
          ...services.map((s) => Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radius),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            s['title'] as String,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusBadge(status: s['status'] as String),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.business_center_rounded, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Provayder: ${s['provider']}',
                            style: AppTypography.caption,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          'Sana: ${formatDate((s['date'] as DateTime).toIso8601String())}',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.payments_rounded, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          'Narxi: ${formatMoney(s['cost'] as double)} UZS',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary),
                        ),
                      ],
                    ),
                    if (s['details'] != null) ...[
                      const Divider(height: 24, color: AppColors.border),
                      Text(s['details'] as String, style: AppTypography.bodyMuted),
                    ],
                  ],
                ),
              )),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
