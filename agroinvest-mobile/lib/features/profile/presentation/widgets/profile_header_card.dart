import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/format.dart';

/// Premium gradient identity card at the top of the Profile tab: avatar with a
/// KYC-verified badge, name/phone, role chip, member-since line and (for
/// farmers) the public rating + project count that investors see.
class ProfileHeaderCard extends StatelessWidget {
  final Map<String, dynamic> profile;
  final VoidCallback onEdit;

  const ProfileHeaderCard({super.key, required this.profile, required this.onEdit});

  String _roleLabel(String role) {
    switch (role) {
      case 'INVESTOR':
        return 'Investor';
      case 'FARMER':
        return 'Fermer';
      case 'SUPERADMIN':
        return 'Super Admin';
      case 'ADMIN':
        return 'Admin';
      case 'MODERATOR':
        return 'Moderator';
      case 'VERIFIER':
        return 'Tekshiruvchi';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullName = profile['fullName']?.toString() ?? 'Foydalanuvchi';
    final phoneNumber = profile['phoneNumber']?.toString() ?? '';
    final avatarUrl = profile['avatarUrl']?.toString();
    final role = profile['role']?.toString() ?? 'INVESTOR';
    final isVerified = profile['kycStatus'] == 'VERIFIED';
    final createdAt = profile['createdAt'];
    final rating = double.tryParse(profile['rating']?.toString() ?? '');
    final totalProjects = (profile['totalProjects'] as num?)?.toInt() ?? 0;
    final isFarmer = role == 'FARMER';

    // Same gradient/shadow recipe as PortfolioSummaryCard on the Investments
    // tab, so the two hero cards read as one design system.
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF15803D), Color(0xFF166534)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF166534).withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null
                        ? Text(
                            fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                          )
                        : null,
                  ),
                  if (isVerified)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.verified_rounded, color: AppColors.primary, size: 18),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.3),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      phoneNumber,
                      style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _roleLabel(role),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 9.5),
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_user_rounded, color: Colors.white, size: 11),
                                SizedBox(width: 4),
                                Text('KYC', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 9.5)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.15)),
                tooltip: 'Tahrirlash',
              ),
            ],
          ),
          if (createdAt != null || isFarmer) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                if (createdAt != null)
                  Expanded(
                    child: _HeaderStat(
                      icon: Icons.calendar_month_rounded,
                      label: "A'zo bo'lgan sana",
                      value: formatDate(createdAt),
                    ),
                  ),
                if (isFarmer) ...[
                  Expanded(
                    child: _HeaderStat(
                      icon: Icons.star_rounded,
                      label: 'Reyting',
                      value: rating != null && rating > 0 ? rating.toStringAsFixed(1) : '—',
                    ),
                  ),
                  Expanded(
                    child: _HeaderStat(
                      icon: Icons.agriculture_rounded,
                      label: 'Loyihalar',
                      value: '$totalProjects ta',
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HeaderStat({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
