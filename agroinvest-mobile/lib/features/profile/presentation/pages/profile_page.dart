import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import '../../data/profile_repository.dart';
import '../../../../core/widgets/app_sidebar.dart';
import '../widgets/profile_header_card.dart';
import '../widgets/profile_kyc_banner.dart';
import '../widgets/profile_menu_section.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

const Map<String, String> _availableLanguages = {'uz': "O'zbek"};

// Keep in sync with pubspec.yaml `version:` (no package_info_plus dependency).
const String _appVersion = '1.0.2';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _repository = ProfileRepository();
  bool _loading = false;
  Map<String, dynamic>? _profileData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final me = await _repository.fetchMe();
      if (!mounted) return;
      setState(() {
        _profileData = me;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // AppBar recipe matches the Investments tab (left-aligned w900 title on a
    // white bar with a hairline bottom border), with dark-mode color swaps.
    return Scaffold(
      drawer: const AppSidebar(),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu_rounded, color: isDark ? Colors.white : AppColors.textDark, size: 24),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          'Profil',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: isDark ? Colors.white : AppColors.textDark,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        centerTitle: false,
        shape: Border(
          bottom: BorderSide(color: isDark ? const Color(0xFF334155) : AppColors.border, width: 1),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.storefront_rounded, color: Color(0xFF16A34A), size: 24),
            onPressed: () => context.push('/services'),
            tooltip: 'Market',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: user == null
          ? Padding(
              padding: const EdgeInsets.all(24.0),
              child: _buildGuestView(context),
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: _loading && _profileData == null
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _buildUserView(context, user, auth),
            ),
    );
  }

  Widget _buildGuestView(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 96,
          height: 96,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.account_circle_outlined, size: 56, color: AppColors.primary),
        ),
        const SizedBox(height: 20),
        const Text(
          'Tizimga kirmagansiz',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Loyihalarga sarmoya kiritish, loyihalar yaratish va hamyondan foydalanish uchun hisobingizga kiring.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => context.push('/login'),
          child: const Text('Kirish', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => context.push('/register'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text("Ro'yxatdan o'tish", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ),
      ],
    );
  }

  Widget _buildUserView(BuildContext context, Map<String, dynamic> user, AuthProvider auth) {
    // Fresh /users/me data wins; auth cache fills the first frame before _load
    // completes so the header never renders empty.
    final profile = <String, dynamic>{...user, ...?_profileData};
    profile['phoneNumber'] ??= user['phone_number'];

    final role = profile['role']?.toString() ?? 'INVESTOR';
    final isInvestor = role == 'INVESTOR';
    final isFarmer = role == 'FARMER';
    final kycStatus = profile['kycStatus']?.toString();
    final userId = profile['id']?.toString();
    final themeProvider = Provider.of<ThemeProvider>(context);

    final themeLabel = switch (themeProvider.themeMode) {
      ThemeMode.light => "Yorug'",
      ThemeMode.dark => 'Tungi',
      _ => "Tizim bo'yicha",
    };

    final (kycChipText, kycChipColor) = switch (kycStatus) {
      'VERIFIED' => ('Tasdiqlangan', AppColors.primary),
      'PENDING' => ('Kutilmoqda', AppColors.accent),
      'REJECTED' => ('Rad etilgan', AppColors.danger),
      _ => ("O'tilmagan", AppColors.textMuted),
    };

    // The app shell uses extendBody: true, so content scrolls behind the
    // floating bottom nav; MediaQuery.padding.bottom carries its height there
    // (plus the system inset) - without it the last rows (settings, logout)
    // are unreachable under the bar.
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset + 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.danger.withOpacity(0.2)),
              ),
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ),
          ],

          ProfileHeaderCard(
            profile: profile,
            onEdit: () async {
              await context.push('/profile/edit');
              _load();
            },
          ),
          const SizedBox(height: 16),

          ProfileKycBanner(
            kycStatus: kycStatus,
            rejectedReason: profile['kycRejectedReason']?.toString(),
            onTap: () async {
              await context.push('/kyc');
              _load();
            },
          ),
          if (kycStatus != 'VERIFIED') const SizedBox(height: 20) else const SizedBox(height: 4),

          if (isInvestor)
            ProfileMenuSection(
              title: 'Moliya',
              tiles: [
                ProfileMenuTile(
                  icon: Icons.trending_up_rounded,
                  label: 'Mening sarmoyalarim',
                  subtitle: 'Portfel, shartnomalar holati, hisobotlar',
                  onTap: () => context.push('/investments'),
                ),
                ProfileMenuTile(
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: AppColors.info,
                  label: 'Mening hamyonim',
                  subtitle: "To'ldirish, yechish, tranzaksiyalar",
                  onTap: () => context.push('/wallet'),
                ),
                ProfileMenuTile(
                  icon: Icons.assignment_turned_in_rounded,
                  iconColor: const Color(0xFF8B5CF6),
                  label: 'Elektron shartnomalar',
                  subtitle: 'Imzolangan investitsiya kelishuvlari',
                  onTap: () => context.push('/profile/contracts'),
                ),
                ProfileMenuTile(
                  icon: Icons.analytics_rounded,
                  iconColor: AppColors.accent,
                  label: 'Sarmoya & ROI tahlili',
                  subtitle: 'Daromad dinamikasi va taqsimot',
                  onTap: () => context.push('/profile/analytics'),
                ),
              ],
            ),

          if (isFarmer)
            ProfileMenuSection(
              title: 'Faoliyat',
              tiles: [
                ProfileMenuTile(
                  icon: Icons.agriculture_rounded,
                  label: 'Mening loyihalarim',
                  subtitle: 'Loyihalar, kunlik hisobotlar',
                  onTap: () => context.push('/projects/my'),
                ),
                ProfileMenuTile(
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: AppColors.info,
                  label: 'Mening hamyonim',
                  subtitle: "Yig'ilgan mablag', yechish, tranzaksiyalar",
                  onTap: () => context.push('/wallet'),
                ),
                if (userId != null)
                  ProfileMenuTile(
                    icon: Icons.star_rounded,
                    iconColor: AppColors.accent,
                    label: 'Mening sharhlarim',
                    subtitle: 'Investorlar qoldirgan baholar',
                    onTap: () => context.push(
                      '/farmers/$userId/reviews',
                      extra: {'farmerName': profile['fullName']},
                    ),
                  ),
              ],
            ),

          ProfileMenuSection(
            title: 'Hisob',
            tiles: [
              ProfileMenuTile(
                icon: Icons.person_rounded,
                label: 'Profilni tahrirlash',
                subtitle: 'Ism, email, profil rasmi',
                onTap: () async {
                  await context.push('/profile/edit');
                  _load();
                },
              ),
              ProfileMenuTile(
                icon: Icons.verified_user_rounded,
                iconColor: kycChipColor == AppColors.textMuted ? AppColors.primary : kycChipColor,
                label: 'Shaxsni tasdiqlash (KYC)',
                trailingText: kycChipText,
                trailingColor: kycChipColor,
                onTap: () async {
                  await context.push('/kyc');
                  _load();
                },
              ),
              ProfileMenuTile(
                icon: Icons.notifications_rounded,
                iconColor: AppColors.info,
                label: 'Bildirishnomalar',
                badgeCount: context.watch<NotificationProvider>().unreadCount,
                onTap: () => context.push('/notifications'),
              ),
              ProfileMenuTile(
                icon: Icons.tune_rounded,
                iconColor: AppColors.textMuted,
                label: 'Bildirishnoma sozlamalari',
                subtitle: 'SMS, push va Telegram kanallari',
                onTap: () => context.push('/profile/notification-settings'),
              ),
            ],
          ),

          ProfileMenuSection(
            title: 'Sozlamalar',
            tiles: [
              ProfileMenuTile(
                icon: Icons.language_rounded,
                iconColor: AppColors.info,
                label: 'Til',
                trailingText: _availableLanguages[context.locale.languageCode] ?? context.locale.languageCode,
                trailingColor: AppColors.info,
                onTap: () => _showLanguagePicker(context),
              ),
              ProfileMenuTile(
                icon: Icons.dark_mode_rounded,
                iconColor: const Color(0xFF8B5CF6),
                label: "Ko'rinish",
                trailingText: themeLabel,
                trailingColor: const Color(0xFF8B5CF6),
                onTap: () => _showThemePicker(context),
              ),
            ],
          ),

          ProfileMenuSection(
            title: 'Yordam',
            tiles: [
              ProfileMenuTile(
                icon: Icons.support_agent_rounded,
                label: "Qo'llab-quvvatlash markazi",
                subtitle: "Savol-javob, biz bilan bog'lanish",
                onTap: () => context.push('/profile/help'),
              ),
              ProfileMenuTile(
                icon: Icons.info_rounded,
                iconColor: AppColors.info,
                label: 'Platforma haqida',
                subtitle: "Video qo'llanmalar, huquqiy hujjatlar",
                onTap: () => context.push('/profile/about'),
              ),
              ProfileMenuTile(
                icon: Icons.gavel_rounded,
                iconColor: AppColors.danger,
                label: 'Shikoyatlarim',
                subtitle: 'Nizolar va ularning holati',
                onTap: () => context.push('/disputes'),
              ),
            ],
          ),

          ProfileMenuSection(
            title: 'Yangilanish',
            tiles: [
              ProfileMenuTile(
                icon: Icons.system_update_rounded,
                iconColor: AppColors.primary,
                label: 'Oxirgi versiyani o\'rnatish',
                subtitle: 'Yangi imkoniyatlarni yuklab olish',
                onTap: _checkAndUpdateApp,
              ),
            ],
          ),

          ElevatedButton.icon(
            onPressed: () => _confirmLogout(context, auth),
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
          const SizedBox(height: 16),
          const Text(
            'AgroInvest v$_appVersion',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Future<void> _checkAndUpdateApp() async {
    final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8080/api/v1';
    final uri = Uri.parse(apiUrl);
    final String host = uri.host;
    final String scheme = uri.scheme;
    final downloadUrl = '$scheme://$host/agroinvest.apk';

    try {
      final launchUri = Uri.parse(downloadUrl);
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Launch failed';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xatolik: yangilanishni yuklab bo\'lmadi ($downloadUrl)')),
      );
    }
  }

  void _confirmLogout(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Tizimdan chiqish', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        content: const Text(
          'Haqiqatan ham hisobingizdan chiqmoqchimisiz?',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              auth.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Chiqish', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    final currentCode = context.locale.languageCode;
    // viewPadding (not SafeArea) so the last row clears the system navigation
    // bar - inside a modal sheet SafeArea can read an already-consumed inset.
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    showModalBottomSheet(
      context: context,
      // The profile tab lives in a nested shell-branch navigator; without the
      // root navigator the sheet opens UNDER the floating bottom nav bar.
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(bottom: bottomInset + 16),
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
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(bottom: bottomInset + 16),
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
}
