import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class WalletCard extends StatelessWidget {
  final String balanceText;

  const WalletCard({super.key, required this.balanceText});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'AgroInvest Card',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              Icon(Icons.nfc_rounded, color: Colors.white.withOpacity(0.8), size: 24),
            ],
          ),
          const Spacer(),
          const Text(
            'Erkin hisob balansi',
            style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            balanceText,
            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '••••  ••••  ••••  8080',
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
              const Icon(Icons.spa_rounded, color: Colors.white30, size: 24),
            ],
          ),
        ],
      ),
    );
  }
}
