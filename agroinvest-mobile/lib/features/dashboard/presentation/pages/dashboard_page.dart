import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/widgets/app_sidebar.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/shimmer_loader.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/dashboard_greeting.dart';
import '../widgets/farmer_dashboard.dart';
import '../widgets/guest_dashboard.dart';
import '../widgets/investor_dashboard.dart';
import '../widgets/news_section.dart';
import '../widgets/weather_card.dart';

/// Role-aware home tab: KPI tiles + action feed for INVESTOR and FARMER,
/// a welcome/CTA screen for guests.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user != null) {
      Provider.of<DashboardProvider>(context, listen: false).fetchDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    if (user == null) {
      return const GuestDashboard();
    }

    final dashboard = Provider.of<DashboardProvider>(context);

    // Auto-trigger fetch if user is loaded but dashboard data hasn't been fetched yet
    if (dashboard.data == null && !dashboard.loading && dashboard.error == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<DashboardProvider>(context, listen: false).fetchDashboard();
      });
    }

    return Scaffold(
      drawer: const AppSidebar(),
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          flexibleSpace: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: DashboardGreeting(name: user['fullName']?.toString() ?? '', role: user['role']?.toString() ?? ''),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => _load(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const WeatherCard(),
              if (dashboard.loading && dashboard.data == null)
                const ShimmerList(count: 4)
              else if (dashboard.error != null && dashboard.data == null)
                ErrorStateWidget(message: dashboard.error!, onRetry: _load)
              else if (dashboard.data != null)
                (dashboard.data!['role'] == 'FARMER')
                    ? FarmerDashboard(data: dashboard.data!)
                    : InvestorDashboard(data: dashboard.data!),
              const NewsSection(),
              // Clears the floating bottom nav (extendBody: true shell).
              SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
            ],
          ),
        ),
      ),
    );
  }
}
