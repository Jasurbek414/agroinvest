import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'core/constants/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/auth/presentation/pages/otp_page.dart';
import 'features/dashboard/presentation/providers/dashboard_provider.dart';
import 'features/dashboard/presentation/pages/dashboard_page.dart';
import 'features/projects/presentation/providers/projects_provider.dart';
import 'features/projects/presentation/pages/projects_list_page.dart';
import 'features/projects/presentation/pages/project_detail_page.dart';
import 'features/projects/presentation/pages/create_project_page.dart';
import 'features/projects/presentation/pages/my_projects_page.dart';
import 'features/investments/presentation/providers/investment_provider.dart';
import 'features/investments/presentation/pages/my_investments_page.dart';
import 'features/wallet/presentation/pages/wallet_page.dart';
import 'features/wallet/presentation/providers/wallet_provider.dart';
import 'features/services/presentation/pages/services_page.dart';
import 'features/coop/presentation/pages/coop_market_page.dart';
import 'features/disputes/presentation/pages/disputes_page.dart';
import 'features/disputes/presentation/providers/dispute_provider.dart';
import 'features/notifications/presentation/pages/notifications_page.dart';
import 'features/notifications/presentation/providers/notification_provider.dart';
import 'features/kyc/presentation/pages/kyc_page.dart';
import 'features/kyc/presentation/providers/kyc_provider.dart';
import 'core/widgets/app_sidebar.dart';
import 'features/reports/presentation/pages/submit_report_page.dart';
import 'features/reports/presentation/pages/daily_log_page.dart';
import 'features/reports/presentation/pages/report_timeline_page.dart';
import 'features/expenses/presentation/pages/project_expenses_page.dart';
import 'features/expenses/presentation/pages/add_expense_page.dart';
import 'features/vet/presentation/pages/project_vet_page.dart';
import 'features/vet/presentation/pages/add_vet_inspection_page.dart';
import 'features/profile/presentation/pages/profile_page.dart';
import 'features/profile/presentation/pages/edit_profile_page.dart';
import 'features/profile/presentation/pages/contracts_page.dart';
import 'features/profile/presentation/pages/portfolio_analytics_page.dart';
import 'features/profile/presentation/pages/notification_settings_page.dart';
import 'features/profile/presentation/pages/help_support_page.dart';
import 'features/profile/presentation/pages/about_platform_page.dart';
import 'features/reviews/presentation/pages/farmer_reviews_page.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

// Routes a logged-out user must not reach directly (deep link, back button,
// stale bookmark) - previously each page guarded itself ad hoc with its own
// `if (auth.user == null) Navigator.push(LoginPage)` check.
const List<String> _protectedPaths = [
  '/wallet',
  '/investments',
  '/notifications',
  '/kyc',
  '/disputes',
  '/projects-new',
  '/projects/my',
  '/profile/edit',
  '/profile/contracts',
  '/profile/analytics',
  '/profile/notification-settings',
  '/profile/help',
];

// Sub-routes of a project (/projects/:id/<suffix>) that require login -
// unlike the project detail page itself, which guests may browse.
const List<String> _protectedProjectSuffixes = [
  '/report',
  '/daily-log',
  '/reports',
  '/expenses',
  '/expenses/add',
  '/vet/add',
];

bool _isProtected(String location) {
  if (_protectedPaths.contains(location)) return true;
  if (!location.startsWith('/projects/')) return false;
  return _protectedProjectSuffixes.any((suffix) => location.endsWith(suffix));
}

const _authFlowPaths = {'/login', '/register', '/otp', '/session-expired'};

class AgroInvestApp extends StatefulWidget {
  const AgroInvestApp({super.key});

  @override
  State<AgroInvestApp> createState() => _AgroInvestAppState();
}

class _AgroInvestAppState extends State<AgroInvestApp> {
  final AuthProvider _authProvider = AuthProvider();
  final ThemeProvider _themeProvider = ThemeProvider();
  late final GoRouter _router = _buildRouter();

  @override
  void initState() {
    super.initState();
    _themeProvider.load();
  }

  GoRouter _buildRouter() {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/home',
      refreshListenable: _authProvider,
      redirect: (context, state) {
        final loggedIn = _authProvider.user != null;
        final sessionExpired = _authProvider.error != null && _authProvider.error!.contains('Sessiya');
        final loc = state.matchedLocation;

        if (sessionExpired && !_authFlowPaths.contains(loc)) {
          return '/session-expired';
        }
        if (!loggedIn && _isProtected(loc)) {
          return '/login';
        }
        return null;
      },
      routes: [
        GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
        GoRoute(path: '/register', builder: (context, state) => const RegisterPage()),
        GoRoute(
          path: '/otp',
          builder: (context, state) {
            final extra = state.extra as Map<dynamic, dynamic>? ?? const {};
            return OtpPage(
              phoneNumber: extra['phoneNumber']?.toString() ?? '',
              purpose: extra['purpose']?.toString() ?? '',
              infoMessage: extra['info']?.toString(),
              initialCooldownSeconds: extra['cooldownSeconds'] is int ? extra['cooldownSeconds'] as int : null,
            );
          },
        ),
        GoRoute(path: '/session-expired', builder: (context, state) => const SessionExpiredPage()),
        GoRoute(path: '/services', builder: (context, state) => const ServicesPage()),
        GoRoute(path: '/coop-market', builder: (context, state) => const CoopMarketPage()),
        GoRoute(path: '/notifications', builder: (context, state) => const NotificationsPage()),
        GoRoute(path: '/kyc', builder: (context, state) => const KycPage()),
        GoRoute(path: '/disputes', builder: (context, state) => const DisputesPage()),
        GoRoute(path: '/projects/my', builder: (context, state) => const MyProjectsPage()),
        GoRoute(path: '/profile/edit', builder: (context, state) => const EditProfilePage()),
        GoRoute(path: '/profile/contracts', builder: (context, state) => const ContractsPage()),
        GoRoute(path: '/profile/analytics', builder: (context, state) => const PortfolioAnalyticsPage()),
        GoRoute(path: '/profile/notification-settings', builder: (context, state) => const NotificationSettingsPage()),
        GoRoute(path: '/profile/help', builder: (context, state) => const HelpSupportPage()),
        GoRoute(path: '/profile/about', builder: (context, state) => const AboutPlatformPage()),
        GoRoute(
          path: '/farmers/:id/reviews',
          builder: (context, state) {
            final extra = state.extra as Map<dynamic, dynamic>? ?? const {};
            return FarmerReviewsPage(
              farmerId: state.pathParameters['id']!,
              farmerName: extra['farmerName']?.toString(),
            );
          },
        ),
        GoRoute(
          path: '/projects/:id/report',
          builder: (context, state) => SubmitReportPage(projectId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/projects/:id/daily-log',
          builder: (context, state) => DailyLogPage(projectId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/projects/:id/reports',
          builder: (context, state) {
            final extra = state.extra as Map<dynamic, dynamic>? ?? const {};
            return ReportTimelinePage(
              projectId: state.pathParameters['id']!,
              projectTitle: extra['title']?.toString(),
            );
          },
        ),
        GoRoute(
          path: '/projects/:id/expenses',
          builder: (context, state) {
            final extra = state.extra as Map<dynamic, dynamic>? ?? const {};
            return ProjectExpensesPage(
              projectId: state.pathParameters['id']!,
              projectTitle: extra['title']?.toString(),
              expensePolicy: extra['expensePolicy']?.toString(),
              farmerId: extra['farmerId']?.toString(),
            );
          },
        ),
        GoRoute(
          path: '/projects/:id/expenses/add',
          builder: (context, state) {
            final extra = state.extra as Map<dynamic, dynamic>? ?? const {};
            return AddExpensePage(
              projectId: state.pathParameters['id']!,
              expensePolicy: extra['expensePolicy']?.toString(),
            );
          },
        ),
        GoRoute(
          path: '/projects/:id/vet',
          builder: (context, state) {
            final extra = state.extra as Map<dynamic, dynamic>? ?? const {};
            return ProjectVetPage(
              projectId: state.pathParameters['id']!,
              projectTitle: extra['title']?.toString(),
              farmerId: extra['farmerId']?.toString(),
            );
          },
        ),
        GoRoute(
          path: '/projects/:id/vet/add',
          builder: (context, state) => AddVetInspectionPage(projectId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/wallet',
          builder: (context, state) => const WalletPage(),
        ),
        GoRoute(
          path: '/projects/:id',
          builder: (context, state) => ProjectDetailPage(projectId: state.pathParameters['id']!),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => AppShellScaffold(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(path: '/home', builder: (context, state) => const DashboardPage()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/projects', builder: (context, state) => const ProjectsListPage()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/projects-new', builder: (context, state) => const CreateProjectPage()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/investments', builder: (context, state) => const MyInvestmentsPage()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/profile', builder: (context, state) => const ProfilePage()),
            ]),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => ProjectsProvider()),
        ChangeNotifierProvider(create: (_) => InvestmentProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => DisputeProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => KycProvider()),
        ChangeNotifierProvider<ThemeProvider>.value(value: _themeProvider),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp.router(
          title: 'AgroInvest',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeProvider.themeMode,
          routerConfig: _router,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
        ),
      ),
    );
  }
}

/// Full-screen replacement for the old inline "session expired" branch inside
/// AppShell.build - now a real route the router's redirect sends the app to
/// whenever DioClient's forced logout fires.
class SessionExpiredPage extends StatelessWidget {
  const SessionExpiredPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_clock_outlined, size: 64, color: AppColors.accent),
                const SizedBox(height: 16),
                const Text(
                  'Sessiya muddati tugadi',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  auth.error ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    auth.clearError();
                    context.go('/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Qayta kirish', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The persistent app frame (offline banner + bottom nav) around the four
/// StatefulShellRoute branches - replaces the old hand-rolled IndexedStack
/// AppShell, but keeps its exact behavior (per-tab guest gating, session-reset
/// wiring, connectivity banner), plus the new Dashboard home tab.
class AppShellScaffold extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppShellScaffold({super.key, required this.navigationShell});

  @override
  State<AppShellScaffold> createState() => _AppShellScaffoldState();
}

class _AppShellScaffoldState extends State<AppShellScaffold> {
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _listenToConnectivity();
    _wireSessionResetCallback();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (Provider.of<AuthProvider>(context, listen: false).user != null) {
        Provider.of<NotificationProvider>(context, listen: false).fetchUnreadCount();
      }
    });
  }

  // Ensures a second user logging in on the same device (without killing the app)
  // never sees the previous user's cached projects/investments/wallet/notifications.
  void _wireSessionResetCallback() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    auth.onSessionEnded = () {
      Provider.of<DashboardProvider>(context, listen: false).reset();
      Provider.of<ProjectsProvider>(context, listen: false).reset();
      Provider.of<InvestmentProvider>(context, listen: false).reset();
      Provider.of<WalletProvider>(context, listen: false).reset();
      Provider.of<DisputeProvider>(context, listen: false).reset();
      Provider.of<NotificationProvider>(context, listen: false).reset();
    };
  }

  void _listenToConnectivity() {
    Connectivity().onConnectivityChanged.listen((results) {
      final offline = results.every((r) => r == ConnectivityResult.none);
      if (mounted && offline != _isOffline) {
        setState(() {
          _isOffline = offline;
        });
        if (!offline) {
          // Reconnected — refresh data
          Provider.of<ProjectsProvider>(context, listen: false).fetchProjects(status: 'FUNDING');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: Column(
        children: [
          if (_isOffline)
            Material(
              color: AppColors.accent,
              child: const SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Internet aloqasi mavjud emas',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(child: widget.navigationShell),
        ],
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BottomNavigationBar(
            currentIndex: widget.navigationShell.currentIndex,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: -0.2),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: -0.2),
            onTap: (index) {
              widget.navigationShell.goBranch(
                index,
                initialLocation: index == widget.navigationShell.currentIndex,
              );
              if (index == 0 && user != null) {
                Provider.of<DashboardProvider>(context, listen: false).fetchDashboard();
              }
              if (index == 3 && user != null && user['role'] != 'FARMER') {
                Provider.of<InvestmentProvider>(context, listen: false).fetchMyInvestments();
              }
              if (index == 4 && user != null) {
                Provider.of<NotificationProvider>(context, listen: false).fetchUnreadCount();
              }
            },
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded, size: 24),
                label: 'Bosh sahifa',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.business_center_outlined),
                activeIcon: Icon(Icons.business_center_rounded, size: 24),
                label: 'Loyihalar',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                ),
                activeIcon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryDark,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                ),
                label: 'Yangi loyiha',
              ),
              BottomNavigationBarItem(
                icon: Icon(user?['role'] == 'FARMER' ? Icons.inventory_2_outlined : Icons.trending_up_rounded),
                activeIcon: Icon(user?['role'] == 'FARMER' ? Icons.inventory_2_rounded : Icons.trending_up_rounded, size: 24),
                label: user?['role'] == 'FARMER' ? 'Loyihalarim' : 'Investitsiyalar',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                activeIcon: Icon(Icons.person_rounded, size: 24),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
