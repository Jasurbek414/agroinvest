import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// Welcome/CTA screen shown on the home tab for signed-out users.
class GuestDashboard extends StatelessWidget {
  const GuestDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.spa_rounded, size: 72, color: AppColors.primary),
              const SizedBox(height: AppSpacing.lg),
              const Text('AgroInvest', textAlign: TextAlign.center, style: AppTypography.h1),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                "Qishloq xo'jaligiga sarmoya kiriting yoki loyihangizga investor toping",
                textAlign: TextAlign.center,
                style: AppTypography.bodyMuted,
              ),
              const SizedBox(height: AppSpacing.xxl),
              ElevatedButton(
                onPressed: () => context.push('/login'),
                child: const Text('Kirish'),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: () => context.push('/register'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radius)),
                ),
                child: const Text("Ro'yxatdan o'tish", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () => context.go('/projects'),
                child: const Text("Loyihalarni ko'rish →"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
