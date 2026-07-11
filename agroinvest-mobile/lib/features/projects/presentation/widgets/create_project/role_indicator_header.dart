import 'package:flutter/material.dart';

class RoleIndicatorHeader extends StatelessWidget {
  final bool isInvestor;

  const RoleIndicatorHeader({super.key, required this.isInvestor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isInvestor
              ? [const Color(0xFF2563EB), const Color(0xFF1D4ED8)]
              : [const Color(0xFF16A34A), const Color(0xFF15803D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isInvestor ? const Color(0xFF2563EB) : const Color(0xFF16A34A)).withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isInvestor ? Icons.trending_up_rounded : Icons.agriculture_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isInvestor ? 'SARMOYA TAKLIFI' : 'LOYIHA ARIZASI',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isInvestor
                      ? 'Mablag\' kiritmoqchi bo\'lgan yo\'nalishingiz bo\'yicha reklama bering. Ushbu shartlar mutlaqo qat\'iy emas, fermerlar boshqa g\'oyalar bilan ham bog\'lanishi mumkin.'
                      : 'Sarmoya yig\'ishni boshlash uchun loyiha ma\'lumotlarini to\'ldiring. Loyiha admin tomonidan tasdiqlanganidan so\'ng faollashadi.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 11.5,
                    height: 1.45,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
