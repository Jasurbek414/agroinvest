import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'core/constants/app_colors.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/projects/presentation/providers/projects_provider.dart';
import 'features/investments/presentation/providers/investment_provider.dart';
import 'features/projects/presentation/pages/projects_list_page.dart';
import 'features/wallet/presentation/pages/wallet_page.dart';
import 'features/wallet/presentation/providers/wallet_provider.dart';
import 'features/disputes/presentation/providers/dispute_provider.dart';
import 'features/notifications/presentation/providers/notification_provider.dart';
import 'features/kyc/presentation/providers/kyc_provider.dart';
import 'features/profile/presentation/pages/profile_page.dart';

class AgroInvestApp extends StatelessWidget {
  const AgroInvestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProjectsProvider()),
        ChangeNotifierProvider(create: (_) => InvestmentProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => DisputeProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => KycProvider()),
      ],
      child: MaterialApp(
        title: 'AgroInvest',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          primaryColor: AppColors.primary,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            surface: AppColors.background,
          ),
          fontFamily: 'Roboto',
        ),
        home: const AppShell(),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
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
          Provider.of<ProjectsProvider>(context, listen: false)
              .fetchProjects(status: 'FUNDING');
        }
      }
    });
  }

  // Pages are defined as getters (not const) so they always reflect current state
  List<Widget> get _pages => const [
        ProjectsListPage(),
        WalletPage(),
        ProfilePage(),
      ];

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    // Show login page if session was force-expired by DioClient (refresh failed)
    if (user == null && auth.error != null && auth.error!.contains('Sessiya')) {
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
                    auth.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
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

    return Scaffold(
      body: Column(
        children: [
          // Offline banner
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
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _pages,
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        backgroundColor: Colors.white,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 1 && user == null) {
            // Redirect to login for Wallet tab
            Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
          } else {
            setState(() {
              _currentIndex = index;
            });
            if (index == 2 && user != null) {
              Provider.of<NotificationProvider>(context, listen: false).fetchUnreadCount();
            }
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_rounded),
            label: 'Loyihalar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Hamyon',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
