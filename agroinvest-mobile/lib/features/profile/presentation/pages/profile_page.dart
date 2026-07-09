import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';

// Only 'uz' exists today (PLATFORM_ROADMAP.md Phase 0.5 is mechanism-only;
// Phase 3 adds ru/en) - listed here so _showLanguagePicker needs no rewiring
// when a second language is added, just a new entry in this map.
const Map<String, String> _availableLanguages = {'uz': "O'zbek"};

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textDark,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: user == null
            ? _buildGuestView(context)
            : _buildUserView(context, user, auth),
      ),
    );
  }

  Widget _buildGuestView(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.account_circle_outlined, size: 84, color: AppColors.textMuted.withOpacity(0.4)),
        const SizedBox(height: 20),
        const Text(
          'Tizimga kirmagansiz',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        const SizedBox(height: 8),
        const Text(
          'Loyihalarga sarmoya kiritish, loyihalar yaratish va hamyondan foydalanish uchun hisobingizga kiring.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () {
            context.push('/login');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text('Kirish', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ),
      ],
    );
  }

  Widget _buildUserView(BuildContext context, Map<String, dynamic> user, AuthProvider auth) {
    final role = user['role'] ?? 'INVESTOR';
    final isInvestor = role == 'INVESTOR';
    final isFarmer = role == 'FARMER';

    String getRoleLabel(String r) {
      if (r == 'INVESTOR') return 'Investor';
      if (r == 'FARMER') return 'Fermer';
      return r;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // User profile Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  user['fullName']?[0]?.toUpperCase() ?? 'U',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['fullName'] ?? 'Foydalanuvchi',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user['phone_number'] ?? user['phoneNumber'] ?? '',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => context.push('/profile/edit'),
                icon: const Icon(Icons.edit_outlined, color: AppColors.textMuted),
                tooltip: 'Tahrirlash',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // List item detail details
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Foydalanuvchi roli', style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  getRoleLabel(role),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Action menu item: My Investments (Only for INVESTOR)
        if (isInvestor)
          _buildMenuButton(
            context: context,
            icon: Icons.trending_up_rounded,
            label: 'Mening sarmoyalarim',
            onTap: () {
              context.push('/investments');
            },
          ),

        // Action menu item: My Projects (Only for FARMER)
        if (isFarmer)
          _buildMenuButton(
            context: context,
            icon: Icons.assignment_outlined,
            label: 'Mening loyihalarim',
            onTap: () {
              context.push('/projects/my');
            },
          ),

        // Bildirishnomalar (har ikkala rol uchun)
        Consumer<NotificationProvider>(
          builder: (context, notificationProvider, _) => _buildMenuButton(
            context: context,
            icon: Icons.notifications_outlined,
            label: 'Bildirishnomalar',
            badgeCount: notificationProvider.unreadCount,
            onTap: () {
              context.push('/notifications');
            },
          ),
        ),

        // Mening hamyonim (har ikkala rol uchun)
        _buildMenuButton(
          context: context,
          icon: Icons.account_balance_wallet_outlined,
          label: 'Mening hamyonim',
          onTap: () {
            context.push('/wallet');
          },
        ),

        // KYC (har ikkala rol uchun)
        _buildMenuButton(
          context: context,
          icon: Icons.verified_user_outlined,
          label: 'Shaxsni tasdiqlash (KYC)',
          onTap: () {
            context.push('/kyc');
          },
        ),

        // Shikoyatlar (har ikkala rol uchun)
        _buildMenuButton(
          context: context,
          icon: Icons.gavel_outlined,
          label: 'Shikoyatlarim',
          onTap: () {
            context.push('/disputes');
          },
        ),

        // Til (hozircha faqat o'zbek, lekin infratuzilma tayyor)
        _buildMenuButton(
          context: context,
          icon: Icons.language_rounded,
          label: 'Til',
          onTap: () => _showLanguagePicker(context),
        ),

        // Ko'rinish (tungi rejim)
        _buildMenuButton(
          context: context,
          icon: Icons.dark_mode_outlined,
          label: "Ko'rinish",
          onTap: () => _showThemePicker(context),
        ),

        const Spacer(),

        // Log out button
        ElevatedButton.icon(
          onPressed: () {
            auth.logout();
          },
          icon: const Icon(Icons.logout_rounded, size: 18),
          label: const Text('Tizimdan chiqish', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.danger.withOpacity(0.08),
            foregroundColor: AppColors.danger,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }

  void _showLanguagePicker(BuildContext context) {
    final currentCode = context.locale.languageCode;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(18),
              child: Text('Tilni tanlang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            for (final entry in _availableLanguages.entries)
              ListTile(
                title: Text(entry.value),
                trailing: entry.key == currentCode ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
                onTap: () {
                  sheetContext.setLocale(Locale(entry.key));
                  Navigator.of(sheetContext).pop();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showThemePicker(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    const options = {
      ThemeMode.system: ("Tizim bo'yicha", Icons.brightness_auto_rounded),
      ThemeMode.light: ('Yorug\'', Icons.light_mode_rounded),
      ThemeMode.dark: ('Tungi', Icons.dark_mode_rounded),
    };
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(18),
              child: Text("Ko'rinishni tanlang", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            for (final entry in options.entries)
              ListTile(
                leading: Icon(entry.value.$2, color: AppColors.primary),
                title: Text(entry.value.$1),
                trailing: entry.key == themeProvider.themeMode ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
                onTap: () {
                  themeProvider.setThemeMode(entry.key);
                  Navigator.of(sheetContext).pop();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
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
                const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
