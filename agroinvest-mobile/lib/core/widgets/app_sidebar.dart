import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../constants/app_colors.dart';
import 'sidebar/sidebar_header.dart';
import 'sidebar/sidebar_menu_item.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final isLoggedIn = user != null;
    final name = user?['fullName']?.toString() ?? 'Mehmon';
    final phone = user?['phoneNumber']?.toString() ?? 'Tizimga kiring';

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.70,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Modular Header Component
          SidebarHeader(
            name: name,
            phoneNumber: phone,
            onClose: () => Navigator.pop(context),
          ),

          // Sidebar Menu Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                SidebarMenuItem(
                  icon: Icons.storefront_rounded,
                  label: 'Market (Yem, Vet...)',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/services');
                  },
                ),
                SidebarMenuItem(
                  icon: Icons.trending_up_rounded,
                  label: 'Loyihalar bozori',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/projects');
                  },
                ),
                SidebarMenuItem(
                  icon: Icons.description_rounded,
                  label: 'Shartnomalar tarixi',
                  onTap: () {
                    Navigator.pop(context);
                    if (isLoggedIn) {
                      context.push('/profile/contracts');
                    } else {
                      context.push('/login');
                    }
                  },
                ),
                SidebarMenuItem(
                  icon: Icons.history_rounded,
                  label: 'Ma\'lumotlar tarixi',
                  onTap: () {
                    Navigator.pop(context);
                    if (isLoggedIn) {
                      context.push('/investments');
                    } else {
                      context.push('/login');
                    }
                  },
                ),
                SidebarMenuItem(
                  icon: Icons.gavel_outlined,
                  label: 'Shikoyatlar',
                  onTap: () {
                    Navigator.pop(context);
                    if (isLoggedIn) {
                      context.push('/disputes');
                    } else {
                      context.push('/login');
                    }
                  },
                ),
                const Divider(color: AppColors.border, indent: 16, endIndent: 16),
                SidebarMenuItem(
                  icon: Icons.info_outline_rounded,
                  label: 'Platforma haqida',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/profile/about');
                  },
                ),
                SidebarMenuItem(
                  icon: Icons.settings_outlined,
                  label: 'Sozlamalar',
                  onTap: () {
                    Navigator.pop(context);
                    if (isLoggedIn) {
                      context.push('/profile/notification-settings');
                    } else {
                      context.push('/login');
                    }
                  },
                ),
                SidebarMenuItem(
                  icon: Icons.help_outline_rounded,
                  label: 'Yordam markazi',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/profile/help');
                  },
                ),
              ],
            ),
          ),

          // Sidebar Footer: App info + Logout
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isLoggedIn)
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        auth.logout();
                        context.go('/home');
                      },
                      icon: const Icon(Icons.logout_rounded, size: 16, color: AppColors.danger),
                      label: const Text('Tizimdan chiqish', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.danger)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    )
                  else
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/login');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Tizimga kirish', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  const SizedBox(height: 12),
                  const Text(
                    'AgroInvest v1.2.0',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
