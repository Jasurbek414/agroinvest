import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import 'projects_search_field.dart';

class ProjectsSliverHeader extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  const ProjectsSliverHeader({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final isFarmer = user != null && user['role'] == 'FARMER';
    final name = user != null ? user['fullName'].toString().split(' ')[0] : 'Mehmon';
    final avatarUrl = user != null ? user['avatarUrl'] : null;

    return SliverAppBar(
      floating: true,
      snap: true,
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 215,
      titleSpacing: 0,
      title: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Bar: Logo + Brand + Notification + Profile
            Row(
              children: [
                // Menu Button to trigger sidebar drawer
                IconButton(
                  icon: const Icon(Icons.menu_rounded, color: AppColors.textDark, size: 24),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AgroInvest',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF16A34A),
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        'Investitsiya kelajak sari',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                // Market storefront action button
                IconButton(
                  onPressed: () => context.push('/services'),
                  icon: const Icon(Icons.storefront_rounded, color: Color(0xFF16A34A), size: 20),
                  tooltip: 'Market',
                ),
                // Notification Bell with green badge
                Consumer<NotificationProvider>(
                  builder: (context, np, _) {
                    final unread = np.unreadCount;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          onPressed: () => context.push('/notifications'),
                          icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textDark, size: 20),
                        ),
                        if (unread > 0)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFF16A34A),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$unread',
                                style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(width: 4),
                // User Avatar
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null
                      ? Text(
                          name[0].toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12),
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Middle Hero section: Page title + Subtitle + "Loyiham yaratish" action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Loyihalar',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Eng yaxshi loyihalarni tanlang va foyda oling',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                // "Loyiham yaratish +" button
                OutlinedButton(
                  onPressed: () => context.push('/projects-new'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF16A34A),
                    side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isFarmer ? 'Loyiham yaratish' : 'Sarmoya taklifi',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textDark),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF16A34A), size: 14),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Search field
            ProjectsSearchField(
              controller: searchController,
              onChanged: onSearchChanged,
            ),
          ],
        ),
      ),
    );
  }
}
